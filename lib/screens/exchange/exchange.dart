import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/exchange_model.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

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
  bool _isSending = false;
  bool _isCompleting = false;

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
          name: rawName.isEmpty ? fallbackName : rawName,
          email: data['email']?.toString(),
          phone: (data['phone'] ?? data['phoneNumber'])?.toString(),
          career: data['career']?.toString(),
          studentId: (data['studentId'] ?? data['carnet'])?.toString(),
          photoUrl: (data['photoUrl'] ?? data['photoURL'])?.toString(),
        );
      } catch (_) {
        return _UserSummary(name: fallbackName);
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

  Future<void> _completeExchange(ExchangeModel exchange) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _isCompleting) return;

    final participantUids = {
      exchange.ownerUid,
      exchange.targetUid,
      exchange.requesterUid,
    }..removeWhere((uid) => uid.trim().isEmpty);

    if (!participantUids.contains(currentUser.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo los participantes pueden completar el intercambio.'),
        ),
      );
      return;
    }

    setState(() => _isCompleting = true);
    try {
      await _firestore.collection('exchanges').doc(widget.tradeId).update({
        'status': ExchangeModel.statusCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intercambio marcado como completado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar el intercambio.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 10),
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
                              _participantsFuture ??= _loadParticipants(exchange);

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
                                              name: exchange.requesterName.trim().isEmpty
                                                  ? 'Solicitante'
                                                  : exchange.requesterName.trim(),
                                            ),
                                        owner: participants?.owner ??
                                            const _UserSummary(name: 'Propietario'),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(20),
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
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(
                                                _scrollController.position.maxScrollExtent,
                                              );
                                            }
                                          });

                                          if (messages.isEmpty) {
                                            return const Center(
                                              child: Text('Aun no hay mensajes.'),
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
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputArea(exchange),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: SizedBox(
                                      width: 250,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: _isCompleting
                                            ? null
                                            : () => _completeExchange(exchange),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF8A4C),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          _isCompleting
                                              ? 'Enviando...'
                                              : 'Enviar contribucion',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
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
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHeader({
    required ExchangeModel exchange,
    required _UserSummary requester,
    required _UserSummary owner,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: isCompact
              ? Column(
                  children: [
                    _buildUserColumn(requester, isRightAligned: false),
                    const Divider(height: 30),
                    _buildItemInfo(exchange),
                    const Divider(height: 30),
                    _buildUserColumn(owner, isRightAligned: true),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildUserColumn(requester, isRightAligned: false)),
                    Container(height: 80, width: 2, color: Colors.grey.shade300),
                    Expanded(child: _buildItemInfo(exchange)),
                    Container(height: 80, width: 2, color: Colors.grey.shade300),
                    Expanded(child: _buildUserColumn(owner, isRightAligned: true)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildUserColumn(_UserSummary user, {required bool isRightAligned}) {
    final photoUrl = user.photoUrl?.trim() ?? '';
    final avatar = photoUrl.isEmpty
        ? CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF5A5860),
            child: Icon(
              Icons.person,
              color: Colors.grey.shade100,
              size: 36,
            ),
          )
        : CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade300,
            child: ClipOval(
              child: Image.network(
                photoUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                webHtmlElementStrategy:
                    kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
                errorBuilder: (, _, _) => Icon(
                  Icons.person,
                  color: Colors.grey.shade700,
                  size: 36,
                ),
              ),
            ),
          );

    final info = Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          user.studentId?.trim().isNotEmpty == true ? user.studentId! : 'Carnet no disponible',
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          user.email?.trim().isNotEmpty == true ? user.email! : 'Correo no disponible',
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          user.phone?.trim().isNotEmpty == true ? user.phone! : 'Telefono no disponible',
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          user.career?.trim().isNotEmpty == true ? user.career! : 'Carrera no disponible',
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRightAligned) _statusDot(),
            if (!isRightAligned) const SizedBox(width: 4),
            const Text(
              'En linea',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (isRightAligned) const SizedBox(width: 4),
            if (isRightAligned) _statusDot(),
          ],
        ),
      ],
    );

    return Row(
      mainAxisAlignment: isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isRightAligned
          ? [Flexible(child: info), const SizedBox(width: 16), avatar]
          : [avatar, const SizedBox(width: 16), Flexible(child: info)],
    );
  }

  Widget _buildItemInfo(ExchangeModel exchange) {
    final imageUrl = exchange.imageUrl.trim();
    return Column(
      children: [
        Text(
          exchange.postTitle.trim().isEmpty
              ? 'Publicacion sin titulo'
              : exchange.postTitle.trim(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
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
                      errorBuilder: (, _, _) =>
                          const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de metodo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  exchange.method.trim().isEmpty ? 'No definido' : exchange.method.trim(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Estado de la solicitud',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(_statusLabel(exchange.status), style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _statusDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFF8A4C) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: isMe ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ExchangeModel exchange) {
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
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onSubmitted: (_) => _sendMessage(exchange),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSending ? null : () => _sendMessage(exchange),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A4C),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30),
            ),
            child: Text(
              _isSending ? 'Enviando...' : 'Enviar',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
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
  final String name;
  final String? email;
  final String? phone;
  final String? career;
  final String? studentId;
  final String? photoUrl;

  const _UserSummary({
    required this.name,
    this.email,
    this.phone,
    this.career,
    this.studentId,
    this.photoUrl,
  });
}