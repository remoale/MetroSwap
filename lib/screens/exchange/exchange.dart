import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/exchange_model.dart';
import 'package:metroswap/screens/feedback/feedback_screen.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/payments/contribution_payment_screen.dart';
import 'package:metroswap/screens/payments/payment_confirmation_screen.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/services/presence_service.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

/// Gestiona la conversación y el estado de un intercambio entre usuarios.
class TradeChatScreen extends StatefulWidget {
  final String tradeId;

  const TradeChatScreen({
    super.key,
    required this.tradeId,
  });

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<_ParticipantsData>? _participantsFuture;
  String? _participantsKey;
  int _lastRenderedMessageCount = 0;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _exchangeStream() {
    return _firestore.collection('exchanges').doc(widget.tradeId).snapshots();
  }

  Stream<List<_ExchangeMessage>> _messagesStream() {
    return _firestore
        .collection('exchanges')
        .doc(widget.tradeId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(_ExchangeMessage.fromDoc)
          .toList(growable: false);
    });
  }

  Future<_ParticipantsData> _loadParticipants(ExchangeModel exchange) async {
    Future<_UserSummary> loadUser({
      required String uid,
      required String fallbackName,
    }) async {
      if (uid.isEmpty) {
        return _UserSummary(name: fallbackName);
      }

      try {
        final snapshot = await _firestore.collection('users').doc(uid).get();
        final data = snapshot.data();
        if (data == null) {
          return _UserSummary(name: fallbackName);
        }

        final rawName = (data['name'] ?? data['displayName'] ?? fallbackName)
            .toString()
            .trim();
        return _UserSummary(
          uid: uid,
          name: rawName.isEmpty ? fallbackName : rawName,
          email: data['email']?.toString(),
          phone: (data['phone'] ?? data['phoneNumber'])?.toString(),
          career: data['career']?.toString(),
          studentId: data['studentId']?.toString(),
          photoUrl: (data['photoUrl'] ?? data['photoURL'])?.toString(),
        );
      } catch (_) {
        return _UserSummary(uid: uid, name: fallbackName);
      }
    }

    final requester = await loadUser(
      uid: exchange.requesterUid,
      fallbackName: exchange.requesterName.trim().isEmpty
          ? 'Solicitante'
          : exchange.requesterName.trim(),
    );
    final owner = await loadUser(
      uid: exchange.targetUid.trim().isEmpty
          ? exchange.ownerUid
          : exchange.targetUid,
      fallbackName: 'Propietario',
    );

    return _ParticipantsData(requester: requester, owner: owner);
  }

  String _participantsCacheKey(ExchangeModel exchange) {
    final ownerUid =
        exchange.targetUid.trim().isEmpty ? exchange.ownerUid.trim() : exchange.targetUid.trim();
    return "${exchange.requesterUid.trim()}|$ownerUid|${exchange.requesterName.trim()}";
  }

  void _refreshParticipantsIfNeeded(ExchangeModel exchange) {
    final nextKey = _participantsCacheKey(exchange);
    if (_participantsKey == nextKey && _participantsFuture != null) {
      return;
    }

    _participantsKey = nextKey;
    _participantsFuture = _loadParticipants(exchange);
  }

  void _scheduleAutoScroll(int messageCount) {
    if (messageCount <= 0 || messageCount == _lastRenderedMessageCount) {
      return;
    }

    final shouldAutoScroll = !_scrollController.hasClients ||
        (_scrollController.position.maxScrollExtent - _scrollController.offset) <= 120;

    _lastRenderedMessageCount = messageCount;
    if (!shouldAutoScroll) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final targetOffset = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset == targetOffset) return;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _resolveSenderName(ExchangeModel exchange) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 'Usuario';

    final displayName = currentUser.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    if (currentUser.uid == exchange.requesterUid &&
        exchange.requesterName.trim().isNotEmpty) {
      return exchange.requesterName.trim();
    }

    try {
      final snapshot = await _firestore.collection('users').doc(currentUser.uid).get();
      final data = snapshot.data();
      final name = (data?['name'] ?? data?['displayName'])?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    } catch (_) {}

    final email = currentUser.email?.trim();
    return (email != null && email.isNotEmpty) ? email : 'Usuario';
  }

  Future<void> _sendMessage(ExchangeModel exchange) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    if (exchange.status == ExchangeModel.statusRejected ||
        exchange.status == ExchangeModel.statusDeclined) {
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final senderName = await _resolveSenderName(exchange);
      final messageRef = _firestore
          .collection('exchanges')
          .doc(widget.tradeId)
          .collection('messages')
          .doc();

      final batch = _firestore.batch();
      batch.set(messageRef, {
        'id': messageRef.id,
        'text': text,
        'senderUid': currentUser.uid,
        'senderName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_firestore.collection('exchanges').doc(widget.tradeId), {
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _messageController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _isPostOwner(ExchangeModel exchange) {
    final currentUid = _auth.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return false;
    final ownerUids = <String>{exchange.ownerUid.trim(), exchange.targetUid.trim()}
      ..removeWhere((uid) => uid.isEmpty);
    return ownerUids.contains(currentUid);
  }

  Future<void> _goToContributionPayment(ExchangeModel exchange) async {
    if (_isPostOwner(exchange)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El propietario no debe enviar contribuciones.'),
        ),
      );
      return;
    }

    if (exchange.status != ExchangeModel.statusAccepted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes esperar a que acepten la solicitud.')),
      );
      return;
    }

    final isSale = exchange.priceUsd != null && exchange.priceUsd! > 0;
    final requiredAmount = isSale
        ? exchange.priceUsd! * exchange.requestedQuantity
        : 30.0;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContributionPaymentScreen(
          tradeId: widget.tradeId,
          title: exchange.postTitle,
          imageUrl: exchange.imageUrl,
          amount: requiredAmount,
          allowCustomAmount: !isSale,
        ),
      ),
    );
  }

  Future<void> _goToFeedback(ExchangeModel exchange) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          tradeId: widget.tradeId,
          postTitle: exchange.postTitle,
        ),
      ),
    );
  }

  Future<void> _goToOwnerFeedback(ExchangeModel exchange) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          tradeId: widget.tradeId,
          postTitle: exchange.postTitle,
          isRequesterReview: true,
        ),
      ),
    );
  }

  Future<void> _goToPaymentSuccessful(ExchangeModel exchange) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(
          amount: exchange.paypalAmount ??
              (exchange.priceUsd != null
                  ? exchange.priceUsd! * exchange.requestedQuantity
                  : 0),
          exchangeId: widget.tradeId,
        ),
      ),
    );
  }

  Future<void> _openUserProfile(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(uid: cleanUid),
      ),
    );
  }

  Future<void> _cancelExchange() async {
    try {
      await _firestore.collection('exchanges').doc(widget.tradeId).update({
        'status': ExchangeModel.statusDeclined,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cancelar el intercambio.')),
      );
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Intercambio cancelado.')),
    );
  }

  Future<void> _acceptExchange() async {
    try {
      await _firestore.collection('exchanges').doc(widget.tradeId).update({
        'status': ExchangeModel.statusAccepted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aceptar el intercambio.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud aceptada.')),
    );
  }

  Future<void> _rejectExchange() async {
    try {
      await _firestore.collection('exchanges').doc(widget.tradeId).update({
        'status': ExchangeModel.statusRejected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo rechazar el intercambio.')),
      );
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Solicitud rechazada.')),
    );
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case ExchangeModel.statusAccepted:
        return 'Aceptado';
      case ExchangeModel.statusRejected:
      case ExchangeModel.statusDeclined:
        return 'Rechazado';
      case ExchangeModel.statusCompleted:
        return 'Completado';
      case ExchangeModel.statusRequested:
      default:
        return 'Solicitado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final isMobileViewport = viewport.width < 600;
    final isShortViewport = viewport.height <= 700;
    final useCompactLayout = isShortViewport || isMobileViewport;

    return Scaffold(
      backgroundColor: const Color(0xFFEFECEF),
      body: SafeArea(
        child: Column(
          children: [
            const MetroSwapNavbar(
              developmentNav: true,
              heading: '',
              showLogoutButton: false,
              showNotificationsButton: true,
              showProfileButton: true,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: useCompactLayout ? 16 : 24,
                      vertical: useCompactLayout ? 8 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          visualDensity: isShortViewport ? VisualDensity.compact : VisualDensity.standard,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.black,
                            size: useCompactLayout ? 24 : 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(height: useCompactLayout ? 6 : 10),
                        Expanded(
                          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _exchangeStream(),
                            builder: (context, exchangeSnapshot) {
                              if (exchangeSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !exchangeSnapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (exchangeSnapshot.hasError) {
                                return const Center(
                                  child: Text('No se pudo cargar el intercambio.'),
                                );
                              }

                              final exchangeDoc = exchangeSnapshot.data;
                              if (exchangeDoc == null || !exchangeDoc.exists) {
                                return const Center(
                                  child: Text('El intercambio no existe o fue eliminado.'),
                                );
                              }

                              final exchange = ExchangeModel.fromDoc(exchangeDoc);
                              _refreshParticipantsIfNeeded(exchange);
                              final isPostOwner = _isPostOwner(exchange);
                              final isRequested =
                                  exchange.status == ExchangeModel.statusRequested;
                              final isAccepted =
                                  exchange.status == ExchangeModel.statusAccepted;
                              final hasCompletedPayment =
                                  exchange.status == ExchangeModel.statusCompleted &&
                                  exchange.paymentStatus.trim().toLowerCase() == 'completed';
                              final isFinalStatus =
                                  exchange.status == ExchangeModel.statusCompleted ||
                                      exchange.status == ExchangeModel.statusRejected ||
                                      exchange.status == ExchangeModel.statusDeclined;

                              return Column(
                                children: [
                                  FutureBuilder<_ParticipantsData>(
                                    future: _participantsFuture,
                                    builder: (context, participantsSnapshot) {
                                      final participants = participantsSnapshot.data;
                                      return _buildTradeHeader(
                                        exchange: exchange,
                                        requester: participants?.requester ??
                                            _UserSummary(
                                              uid: exchange.requesterUid,
                                              name: exchange.requesterName.trim().isEmpty
                                                  ? 'Solicitante'
                                                  : exchange.requesterName.trim(),
                                            ),
                                        owner: participants?.owner ??
                                            _UserSummary(
                                              uid: exchange.targetUid.trim().isEmpty
                                                  ? exchange.ownerUid
                                                  : exchange.targetUid,
                                              name: 'Propietario',
                                            ),
                                        currentUid: _auth.currentUser?.uid ?? '',
                                        compact: useCompactLayout,
                                        mobile: isMobileViewport,
                                      );
                                    },
                                  ),
                                  SizedBox(height: useCompactLayout ? 12 : 20),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.all(useCompactLayout ? 14 : 20),
                                      child: StreamBuilder<List<_ExchangeMessage>>(
                                        stream: _messagesStream(),
                                        builder: (context, messagesSnapshot) {
                                          if (messagesSnapshot.hasError) {
                                            return const Center(
                                              child: Text('No se pudieron cargar los mensajes.'),
                                            );
                                          }

                                          final messages =
                                              messagesSnapshot.data ?? const <_ExchangeMessage>[];
                                          _scheduleAutoScroll(messages.length);

                                          if (messages.isEmpty) {
                                            final emptyMessage =
                                                exchange.status == ExchangeModel.statusDeclined
                                                    ? 'Este intercambio fue cancelado. Ya no se pueden enviar mensajes.'
                                                    : exchange.status == ExchangeModel.statusRejected
                                                        ? 'Esta solicitud fue rechazada. Ya no se pueden enviar mensajes.'
                                                        : isPostOwner
                                                            ? 'Aun no hay mensajes. Escribe primero para coordinar el intercambio con el solicitante.'
                                                            : 'Aun no hay mensajes. Escribe primero para coordinar el intercambio con el propietario.';
                                            return Center(
                                              child: Text(
                                                emptyMessage,
                                              ),
                                            );
                                          }

                                          final currentUid = _auth.currentUser?.uid;
                                          return ListView.builder(
                                            controller: _scrollController,
                                            itemCount: messages.length,
                                            itemBuilder: (context, index) {
                                              final msg = messages[index];
                                              return _buildMessageBubble(
                                                text: msg.text,
                                                isMe: msg.senderUid == currentUid,
                                                compact: useCompactLayout,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: useCompactLayout ? 12 : 20),
                                  _buildInputArea(
                                    exchange,
                                    canSendMessages:
                                        exchange.status != ExchangeModel.statusRejected &&
                                        exchange.status != ExchangeModel.statusDeclined,
                                    compact: useCompactLayout,
                                  ),
                                  SizedBox(height: useCompactLayout ? 12 : 20),
                                  if (isRequested)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: useCompactLayout ? 8 : 12),
                                      child: Text(
                                        isPostOwner
                                            ? 'Esta solicitud esta pendiente por tu aceptacion.'
                                            : 'Tu solicitud esta pendiente de aceptacion del propietario.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6A6671),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: Wrap(
                                      spacing: 14,
                                      runSpacing: 14,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        if (isAccepted && !isPostOwner)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: ElevatedButton(
                                              onPressed: () => _goToContributionPayment(exchange),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFF8A4C),
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Enviar contribucion',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isPostOwner && isRequested)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: ElevatedButton(
                                              onPressed: _acceptExchange,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4E69E8),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Aceptar solicitud',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isPostOwner && isRequested)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: OutlinedButton(
                                              onPressed: _rejectExchange,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF8A1E1E),
                                                side: const BorderSide(
                                                  color: Color(0xFF8A1E1E),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Rechazar solicitud',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isPostOwner && isAccepted)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: OutlinedButton(
                                              onPressed: () => _goToFeedback(exchange),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF2F2F33),
                                                side: const BorderSide(
                                                  color: Color(0xFF8A858F),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Terminar intercambio',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (!isPostOwner &&
                                            exchange.status == ExchangeModel.statusCompleted &&
                                            !exchange.requesterFeedbackSubmitted)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: ElevatedButton(
                                              onPressed: () => _goToOwnerFeedback(exchange),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4E69E8),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Calificar propietario',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (hasCompletedPayment)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: ElevatedButton(
                                              onPressed: () => _goToPaymentSuccessful(exchange),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2F3035),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Ver pago completado',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (!isPostOwner &&
                                            !isFinalStatus)
                                          SizedBox(
                                            width: useCompactLayout ? 220 : 250,
                                            height: useCompactLayout ? 40 : 45,
                                            child: OutlinedButton(
                                              onPressed: _cancelExchange,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF8A1E1E),
                                                side: const BorderSide(
                                                  color: Color(0xFF8A1E1E),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Cancelar intercambio',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: useCompactLayout ? 8 : 20),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!useCompactLayout) const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHeader({
    required ExchangeModel exchange,
    required _UserSummary requester,
    required _UserSummary owner,
    required String currentUid,
    required bool compact,
    required bool mobile,
  }) {
    final isRequesterCurrentUser =
        currentUid.isNotEmpty && currentUid == exchange.requesterUid;
    final leftUser = isRequesterCurrentUser ? requester : owner;
    final rightUser = isRequesterCurrentUser ? owner : requester;
    final leftIsOwner = !isRequesterCurrentUser;
    final rightIsOwner = isRequesterCurrentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 14 : 20,
            horizontal: compact ? 16 : 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 24 : 40),
          ),
          child: mobile
              ? Column(
                  children: [
                    _buildUserColumn(
                      leftUser,
                      isRightAligned: false,
                      isOwner: leftIsOwner,
                      compact: true,
                      mobile: true,
                    ),
                    const Divider(height: 18),
                    _buildItemInfo(exchange, compact: true, mobile: true),
                    const Divider(height: 18),
                    _buildUserColumn(
                      rightUser,
                      isRightAligned: false,
                      isOwner: rightIsOwner,
                      compact: true,
                      mobile: true,
                    ),
                  ],
                )
              : isCompact
              ? Column(
                  children: [
                    _buildUserColumn(
                      leftUser,
                      isRightAligned: false,
                      isOwner: leftIsOwner,
                      compact: compact,
                      mobile: false,
                    ),
                    Divider(height: compact ? 20 : 30),
                    _buildItemInfo(exchange, compact: compact, mobile: false),
                    Divider(height: compact ? 20 : 30),
                    _buildUserColumn(
                      rightUser,
                      isRightAligned: true,
                      isOwner: rightIsOwner,
                      compact: compact,
                      mobile: false,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildUserColumn(
                        leftUser,
                        isRightAligned: false,
                        isOwner: leftIsOwner,
                        compact: compact,
                        mobile: false,
                      ),
                    ),
                    Container(height: compact ? 60 : 80, width: 2, color: Colors.grey.shade300),
                    Expanded(child: _buildItemInfo(exchange, compact: compact, mobile: false)),
                    Container(height: compact ? 60 : 80, width: 2, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildUserColumn(
                        rightUser,
                        isRightAligned: true,
                        isOwner: rightIsOwner,
                        compact: compact,
                        mobile: false,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildUserColumn(
    _UserSummary user, {
    required bool isRightAligned,
    required bool isOwner,
    required bool compact,
    required bool mobile,
  }) {
    final photoUrl = user.photoUrl?.trim() ?? '';
    final avatarRadius = compact ? 30.0 : 40.0;
    final avatarIconSize = compact ? 28.0 : 36.0;
    final avatarBase = photoUrl.isEmpty
        ? CircleAvatar(
            radius: avatarRadius,
            backgroundColor: const Color(0xFF5A5860),
            child: Icon(
              Icons.person,
              color: Colors.grey.shade100,
              size: avatarIconSize,
            ),
          )
        : CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade300,
            child: ClipOval(
              child: Image.network(
                photoUrl,
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy:
                    kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: Colors.grey.shade700,
                  size: avatarIconSize,
                ),
              ),
            ),
          );
    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarBase,
        if (isOwner)
          Positioned(
            top: compact ? -10 : -12,
            left: 0,
            right: 0,
            child: Center(child: _OwnerBadge(compact: compact)),
          ),
      ],
    );

    Widget buildMetaText(String value) {
      return Text(
        value,
        style: TextStyle(fontSize: compact ? 9 : 10),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
    }

    final info = Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 14 : 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!mobile) ...[
          buildMetaText(
            user.studentId?.trim().isNotEmpty == true ? user.studentId! : 'Carnet no disponible',
          ),
          buildMetaText(
            user.email?.trim().isNotEmpty == true ? user.email! : 'Correo no disponible',
          ),
          buildMetaText(
            user.phone?.trim().isNotEmpty == true ? user.phone! : 'Telefono no disponible',
          ),
          buildMetaText(
            user.career?.trim().isNotEmpty == true ? user.career! : 'Carrera no disponible',
          ),
        ] else ...[
          if (user.career?.trim().isNotEmpty == true)
            Text(
              user.career!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6A6671)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
        SizedBox(height: compact ? 6 : 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<UserPresence>(
              stream: PresenceService.instance.watchUserPresence(user.uid),
              builder: (context, snapshot) {
                final presence = snapshot.data ?? const UserPresence.offline();
                final statusLabel = _presenceLabel(presence);
                final statusColor =
                    presence.isOnline ? Colors.green : const Color(0xFF8A858F);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isRightAligned) _statusDot(statusColor),
                    if (!isRightAligned) const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (isRightAligned) const SizedBox(width: 4),
                    if (isRightAligned) _statusDot(statusColor),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );

    final userRow = Row(
      mainAxisAlignment: mobile
          ? MainAxisAlignment.start
          : isRightAligned
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
      children: mobile
          ? [avatar, SizedBox(width: compact ? 10 : 16), Expanded(child: info)]
          : isRightAligned
              ? [Flexible(child: info), SizedBox(width: compact ? 10 : 16), avatar]
              : [avatar, SizedBox(width: compact ? 10 : 16), Flexible(child: info)],
    );

    if (user.uid.trim().isEmpty) {
      return userRow;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openUserProfile(user.uid),
        child: userRow,
      ),
    );
  }

  Widget _buildItemInfo(
    ExchangeModel exchange, {
    required bool compact,
    required bool mobile,
  }) {
    final imageUrl = exchange.imageUrl.trim();
    final hasAgreedAmount = exchange.priceUsd != null && exchange.priceUsd! > 0;
    final agreedAmount = hasAgreedAmount
        ? exchange.priceUsd! * exchange.requestedQuantity
        : 0.0;
    return mobile
        ? Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.image, color: Colors.grey)
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: kIsWeb
                            ? WebHtmlElementStrategy.prefer
                            : WebHtmlElementStrategy.never,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exchange.postTitle.trim().isEmpty
                          ? 'Publicacion sin titulo'
                          : exchange.postTitle.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exchange.method.trim().isEmpty ? 'No definido' : exchange.method.trim(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(exchange.status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A6671),
                      ),
                    ),
                    if (hasAgreedAmount) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Precio: \$${agreedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A4589),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          )
        : Column(
      children: [
        Text(
          exchange.postTitle.trim().isEmpty
              ? 'Publicacion sin titulo'
              : exchange.postTitle.trim(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 13 : 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: compact ? 6 : 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 42 : 50,
              height: compact ? 42 : 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy: kIsWeb
                                ? WebHtmlElementStrategy.prefer
                                : WebHtmlElementStrategy.never,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          ),
            ),
            SizedBox(width: compact ? 12 : 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de metodo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
                Text(
                  exchange.method.trim().isEmpty ? 'No definido' : exchange.method.trim(),
                  style: TextStyle(fontSize: compact ? 11 : 12),
                ),
                if (hasAgreedAmount)
                  Text(
                    'Precio: \$${agreedAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A4589),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Estado de la solicitud',
          style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.bold),
        ),
        Text(_statusLabel(exchange.status), style: TextStyle(fontSize: compact ? 9 : 10)),
      ],
    );
  }

  String _presenceLabel(UserPresence presence) {
    if (presence.isOnline) return 'En linea';

    final lastSeen = presence.lastSeen;
    if (lastSeen == null) {
      return 'Desconectado';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Activo hace un momento';
    }
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'Activo hace $minutes min';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return 'Activo hace $hours h';
    }

    final days = difference.inDays;
    return 'Activo hace $days d';
  }

  Widget _statusDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required bool compact,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFF8A4C) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: compact ? 14 : 16,
            fontWeight: isMe ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(
    ExchangeModel exchange, {
    required bool canSendMessages,
    required bool compact,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _messageController,
              enabled: canSendMessages,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje',
                hintStyle: TextStyle(color: Colors.grey, fontSize: compact ? 16 : 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 20,
                  vertical: compact ? 12 : 15,
                ),
              ),
              onSubmitted: canSendMessages ? (_) => _sendMessage(exchange) : null,
            ),
          ),
        ),
        SizedBox(width: compact ? 10 : 16),
        SizedBox(
          height: compact ? 44 : 50,
          child: ElevatedButton(
            onPressed: _isSending || !canSendMessages
                ? null
                : () => _sendMessage(exchange),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A4C),
              foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 30),
            ),
            child: Text(
              _isSending ? 'Enviando...' : 'Enviar',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  final bool compact;

  const _OwnerBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Propietario',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExchangeMessage {
  final String id;
  final String text;
  final String senderUid;
  final DateTime? createdAt;

  const _ExchangeMessage({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.createdAt,
  });

  factory _ExchangeMessage.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    return _ExchangeMessage(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      senderUid: (data['senderUid'] ?? '').toString(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class _ParticipantsData {
  final _UserSummary requester;
  final _UserSummary owner;

  const _ParticipantsData({
    required this.requester,
    required this.owner,
  });
}

class _UserSummary {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String? career;
  final String? studentId;
  final String? photoUrl;

  const _UserSummary({
    this.uid = '',
    required this.name,
    this.email,
    this.phone,
    this.career,
    this.studentId,
    this.photoUrl,
  });
}
