import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/notification_model.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/services/notification_service.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _inProgressScrollController = ScrollController();
  Map<String, String>? _userNameCache;
  Set<String>? _loadingUserNames;
  Map<String, String>? _exchangeTitleCache;
  Map<String, String>? _exchangeStatusCache;
  Set<String>? _loadingExchangeTitles;
  Set<String>? _blockedExchangeTitles;
  String? _uid;

  Map<String, String> get _nameCache => _userNameCache ??= <String, String>{};
  Set<String> get _loadingNames => _loadingUserNames ??= <String>{};
  Map<String, String> get _titleCache => _exchangeTitleCache ??= <String, String>{};
  Map<String, String> get _statusCache => _exchangeStatusCache ??= <String, String>{};
  Set<String> get _loadingTitles => _loadingExchangeTitles ??= <String>{};
  Set<String> get _blockedTitles => _blockedExchangeTitles ??= <String>{};

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    _inProgressScrollController.dispose();
    super.dispose();
  }

  bool _isInProgress(NotificationModel notification) {
    final status = _effectiveStatusKey(notification);
    return status == 'requested' || status == 'accepted';
  }

  bool _isHistory(NotificationModel notification) {
    final status = _effectiveStatusKey(notification);
    return status == 'rejected' || status == 'cancelled' || status == 'completed';
  }

  Color _resolveStatusColor(NotificationModel notification, bool inProgress) {
    final status = _effectiveStatusKey(notification);
    if (inProgress && status == 'requested') {
      return const Color(0xFFEBCD35);
    }
    if (inProgress && status == 'accepted') {
      return const Color(0xFF4E69E8);
    }
    if (status == 'rejected' || status == 'cancelled') {
      return const Color(0xFFE35A06);
    }
    return const Color(0xFF84D264);
  }

  String _resolveUserName(NotificationModel notification) {
    final actorUid = _actorUid(notification);
    final cachedName =
        actorUid == null ? null : _nameCache[actorUid]?.trim();
    if (cachedName != null && cachedName.isNotEmpty) {
      return cachedName;
    }

    final actorName = notification.data?['actorName']?.toString().trim() ?? '';
    if (actorName.isNotEmpty && !_isGenericActorName(actorName)) {
      return actorName;
    }

    final bodyName = _extractNameFromBody(notification.body);
    if (bodyName.isNotEmpty && !_isGenericActorName(bodyName)) {
      return bodyName;
    }

    if (actorUid != null) {
      _resolveUserNameFromUid(actorUid);
    }
    return 'Usuario';
  }

  String? _actorUid(NotificationModel notification) {
    final fromData = notification.data?['actorUid']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) {
      return fromData;
    }

    final fromField = notification.actorUid?.trim();
    if (fromField != null && fromField.isNotEmpty) {
      return fromField;
    }
    return null;
  }

  bool _isGenericActorName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'el publicador' ||
        normalized == 'el usuario' ||
        normalized == 'un usuario' ||
        normalized == 'el propietario' ||
        normalized == 'propietario' ||
        normalized == 'usuario';
  }

  String _extractNameFromBody(String body) {
    final text = body.trim();
    if (text.isEmpty) return '';

    final patterns = <RegExp>[
      RegExp(r'^(.+?)\s+quiere realizar un intercambio contigo$', caseSensitive: false),
      RegExp(r'^(.+?)\s+quiere intercambiar por', caseSensitive: false),
      RegExp(r'^El intercambio con\s+(.+?)\s+fue completado$', caseSensitive: false),
      RegExp(r'^Tu solicitud fue enviada a\s+(.+)$', caseSensitive: false),
      RegExp(r'^Aceptaste el intercambio de\s+(.+)$', caseSensitive: false),
      RegExp(r'^Rechazaste el intercambio de\s+(.+)$', caseSensitive: false),
      RegExp(r'^(.+?)\s+aceptó tu solicitud', caseSensitive: false),
      RegExp(r'^(.+?)\s+rechazó tu solicitud', caseSensitive: false),
      RegExp(r'^Intercambio de\s+".+?"\s+completado con\s+(.+)$', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final extracted = (match.group(1) ?? '').trim();
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }
    return '';
  }

  void _resolveUserNameFromUid(String uid) {
    if (_isUidLoading(uid) || _nameCache[uid] != null) {
      return;
    }

    _loadingNames.add(uid);
    _firestore.collection('users').doc(uid).get().then((snapshot) {
      final data = snapshot.data();
      final resolved = (data?['name'] ??
              data?['displayName'] ??
              data?['fullName'] ??
              data?['email'] ??
              '')
          .toString()
          .trim();
      if (!mounted) return;

      if (resolved.isNotEmpty) {
        setState(() {
          _nameCache[uid] = resolved;
        });
      }
    }).whenComplete(() {
      _loadingNames.remove(uid);
    });
  }

  bool _isUidLoading(String uid) {
    final set = _loadingUserNames;
    if (set == null) return false;
    return set.lookup(uid) != null;
  }

  void _primeUserNames(List<NotificationModel> notifications) {
    for (final notification in notifications) {
      final uid = _actorUid(notification);
      if (uid != null) {
        _resolveUserNameFromUid(uid);
      }
      final exchangeId = _exchangeIdFromNotification(notification);
      if (exchangeId.isNotEmpty) {
        _resolveItemTitleFromExchange(exchangeId);
      }
    }
  }

  String _formatRelativeTime(DateTime? createdAt) {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  String _resolveTitle(
    NotificationModel? notification, {
    required String fallback,
  }) {
    if (notification == null) return fallback;
    return _resolveUiTitle(notification);
  }

  String _resolveCardTitle(NotificationModel notification) {
    return _resolveUiTitle(notification);
  }

  String _resolveItemTitle(NotificationModel notification) {
    final fromData = notification.data?['postTitle']?.toString().trim() ?? '';
    if (fromData.isNotEmpty) {
      return fromData;
    }

    final fromAltData = notification.data?['title']?.toString().trim() ?? '';
    if (fromAltData.isNotEmpty) {
      return fromAltData;
    }

    final exchangeId = _exchangeIdFromNotification(notification);
    if (exchangeId.isNotEmpty) {
      final cached = _titleCache[exchangeId]?.trim();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      _resolveItemTitleFromExchange(exchangeId);
    }

    return '';
  }

  bool _isExchangeTitleLoading(String exchangeId) {
    final set = _loadingExchangeTitles;
    if (set == null) return false;
    return set.lookup(exchangeId) != null;
  }

  void _resolveItemTitleFromExchange(String exchangeId) {
    if (_isExchangeTitleLoading(exchangeId) ||
        (_titleCache[exchangeId] != null && _statusCache[exchangeId] != null) ||
        _blockedTitles.lookup(exchangeId) != null) {
      return;
    }

    _loadingTitles.add(exchangeId);
    _firestore.collection('exchanges').doc(exchangeId).get().then((snapshot) {
      final data = snapshot.data();
      final resolved = (data?['postTitle'] ?? data?['title'] ?? '')
          .toString()
          .trim();
      final rawStatus = data?['status']?.toString().trim().toLowerCase() ?? '';
      final resolvedStatus = rawStatus == 'declined' ||
              rawStatus == 'cancelled' ||
              rawStatus == 'canceled'
          ? 'cancelled'
          : rawStatus == 'rejected'
              ? 'rejected'
              : rawStatus == 'completed' ||
                      rawStatus == 'finalized' ||
                      rawStatus == 'finalizado'
                  ? 'completed'
                  : rawStatus;
      if (!mounted) return;
      if (resolved.isNotEmpty || resolvedStatus.isNotEmpty) {
        setState(() {
          if (resolved.isNotEmpty) {
            _titleCache[exchangeId] = resolved;
          }
          if (resolvedStatus.isNotEmpty) {
            _statusCache[exchangeId] = resolvedStatus;
          }
        });
      }
    }).catchError((error) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        _blockedTitles.add(exchangeId);
      }
    }).whenComplete(() {
      _loadingTitles.remove(exchangeId);
    });
  }

  String _resolveBody(NotificationModel notification) {
    return _resolveUiBody(notification);
  }

  String _effectiveStatusKey(NotificationModel notification) {
    final notificationStatus = _statusKey(notification);
    final exchangeId = _exchangeIdFromNotification(notification);
    if (exchangeId.isEmpty) {
      return notificationStatus;
    }

    final exchangeStatus = _statusCache[exchangeId];
    if (exchangeStatus == null || exchangeStatus.isEmpty) {
      return notificationStatus;
    }

    if ((notificationStatus == 'requested' || notificationStatus == 'accepted') &&
        (exchangeStatus == 'rejected' ||
            exchangeStatus == 'cancelled' ||
            exchangeStatus == 'completed')) {
      return exchangeStatus;
    }

    return notificationStatus;
  }

  String _statusKey(NotificationModel notification) {
    final type = notification.type.toLowerCase();
    if (type == 'exchange_cancelled') {
      return 'cancelled';
    }

    final rawStatus = notification.data?['status']?.toString().trim().toLowerCase();
    if (rawStatus != null && rawStatus.isNotEmpty) {
      if (rawStatus == 'declined' || rawStatus == 'cancelled' || rawStatus == 'canceled') {
        return 'cancelled';
      }
      if (rawStatus == 'rejected') {
        return 'rejected';
      }
      if (rawStatus == 'completed' || rawStatus == 'finalized' || rawStatus == 'finalizado') {
        return 'completed';
      }
      return rawStatus;
    }

    switch (type) {
      case 'exchange_requested':
        return 'requested';
      case 'exchange_accepted':
        return 'accepted';
      case 'exchange_rejected':
        return 'rejected';
      case 'exchange_completed':
        return 'completed';
      default:
        return '';
    }
  }

  String _resolveUiTitle(NotificationModel notification) {
    final status = _effectiveStatusKey(notification);
    if (status == 'requested') {
      final requestedByMe = notification.data?['requestedByMe'] == true;
      return requestedByMe ? 'Solicitud enviada' : 'Nueva solicitud';
    }
    if (status == 'accepted') return 'Solicitud aceptada';
    if (status == 'rejected') return 'Solicitud rechazada';
    if (status == 'cancelled') return 'Solicitud cancelada';
    if (status == 'completed') return 'Intercambio completado';
    final title = notification.title.trim();
    return title.isEmpty ? 'Notificación' : title;
  }

  String _resolveUiBody(NotificationModel notification) {
    final status = _effectiveStatusKey(notification);
    if (status.isEmpty) {
      return notification.body;
    }

    final actor = _resolveUserName(notification);
    final material = _resolveItemTitle(notification).trim();
    final safeActor = actor.isEmpty ? 'Usuario' : actor;
    final safeMaterial = material.isEmpty ? 'material' : material;

    if (status == 'requested') {
      final requestedByMe = notification.data?['requestedByMe'] == true;
      if (requestedByMe) {
        return 'Tu solicitud para "$safeMaterial" fue enviada';
      }
      return '$safeActor quiere intercambiar por "$safeMaterial"';
    }
    if (status == 'accepted') {
      return '$safeActor aceptó tu solicitud para "$safeMaterial"';
    }
    if (status == 'rejected') {
      return '$safeActor rechazó tu solicitud para "$safeMaterial"';
    }
    if (status == 'cancelled') {
      return notification.body;
    }
    return 'Intercambio de "$safeMaterial" completado con $safeActor';
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (_uid == null || notification.read) return;
    await _notificationService.markAsRead(
      uid: _uid!,
      notificationId: notification.id,
    );
  }

  String _exchangeIdFromNotification(NotificationModel notification) {
    final raw = notification.data?['exchangeId']?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    return '';
  }

  Future<void> _openNotification(NotificationModel notification) async {
    await _markAsRead(notification);
    final exchangeId = _exchangeIdFromNotification(notification);
    if (exchangeId.isEmpty || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradeChatScreen(tradeId: exchangeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    final viewportWidth = MediaQuery.of(context).size.width;
    final isMobile = viewportWidth < 700;
    final desktopSectionsHeight = viewportHeight >= 950
        ? 480.0
        : viewportHeight >= 860
            ? 420.0
            : 360.0;
    final uid = _uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFDCD9DF),
        body: Column(
          children: const [
            MetroSwapNavbar(
              developmentNav: true,
              heading: 'Notificaciones',
              showNotificationsButton: false,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Debes iniciar sesión para ver notificaciones.',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            MetroSwapFooter(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDCD9DF),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.streamNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError && !snapshot.hasData) {
            return Column(
              children: [
                const MetroSwapNavbar(
                  developmentNav: true,
                  heading: 'Notificaciones',
                  showNotificationsButton: false,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Error cargando notificaciones: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const MetroSwapFooter(),
              ],
            );
          }

          final notifications = snapshot.data ?? const <NotificationModel>[];
          _primeUserNames(notifications);
          final inProgress = notifications.where(_isInProgress).toList();
          final history = notifications.where(_isHistory).toList();
          final latest = notifications.take(2).toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const MetroSwapNavbar(
                        developmentNav: true,
                        heading: 'Notificaciones',
                        showNotificationsButton: false,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E6EB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFB7B3BB)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: isMobile
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: TextButton(
                                        onPressed: notifications.isEmpty
                                            ? null
                                            : () => _notificationService.markAllAsRead(uid),
                                        child: const Text(
                                          'Marcar todas como leídas',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: isMobile ? 760 : desktopSectionsHeight,
                                  child: isMobile
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: _buildSection(
                                                title: 'Historial',
                                                notifications: history,
                                                scrollController:
                                                    _historyScrollController,
                                                compact: true,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Divider(
                                              color: Color(0xFF8D8A90),
                                              height: 1,
                                            ),
                                            const SizedBox(height: 20),
                                            Expanded(
                                              child: _buildSection(
                                                title: 'En curso',
                                                notifications: inProgress,
                                                scrollController:
                                                    _inProgressScrollController,
                                                compact: true,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: _buildSection(
                                                title: 'Historial',
                                                notifications: history,
                                                scrollController:
                                                    _historyScrollController,
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  ),
                                              color: const Color(0xFF8D8A90),
                                            ),
                                            Expanded(
                                              child: _buildSection(
                                                title: 'En curso',
                                                notifications: inProgress,
                                                scrollController:
                                                    _inProgressScrollController,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Color(0xFF8D8A90), height: 1),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cards = _buildActivityCards(latest);
                                    if (constraints.maxWidth >= 1000) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: cards[0],
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: cards[1],
                                          ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        cards[0],
                                        const SizedBox(height: 16),
                                        cards[1],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const MetroSwapFooter(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildActivityCards(List<NotificationModel> latest) {
    final first = latest.isNotEmpty ? latest[0] : null;
    final second = latest.length > 1 ? latest[1] : null;

    return [
      _ActivityCard(
        isDark: true,
        title: _resolveTitle(
          first,
          fallback: 'Nueva Notificación!',
        ),
        body: first != null
            ? _resolveBody(first)
            : 'No hay actividad reciente.',
        trailingText: _formatRelativeTime(first?.createdAt),
        icon: Icons.dashboard_outlined,
        isUnread: first != null && !first.read,
        onTap: first == null ? null : () => _openNotification(first),
      ),
      _ActivityCard(
        isDark: false,
        title: _resolveTitle(
          second,
          fallback: 'Notificación',
        ),
        body: second != null
            ? _resolveBody(second)
            : 'No hay actividad reciente.',
        trailingText: _formatRelativeTime(second?.createdAt),
        icon: Icons.person_outline,
        showAction: second != null && _exchangeIdFromNotification(second).isNotEmpty,
        isUnread: second != null && !second.read,
        onTap: second == null ? null : () => _openNotification(second),
      ),
    ];
  }

  Widget _buildSection({
    required String title,
    required List<NotificationModel> notifications,
    required ScrollController scrollController,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: compact ? 26 : 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1E21),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: notifications.isEmpty
              ? const _EmptyStateCard(message: 'Sin notificaciones en esta sección.')
              : Scrollbar(
                  controller: scrollController,
                  child: ListView.separated(
                    controller: scrollController,
                    primary: false,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final inProgress = _isInProgress(notification);
                      return _HistoryCard(
                        username: _resolveCardTitle(notification),
                        message: _resolveBody(notification),
                        timeText: _formatRelativeTime(notification.createdAt),
                        statusColor: _resolveStatusColor(notification, inProgress),
                        isUnread: !notification.read,
                        onTap: () => _openNotification(notification),
                        compact: compact,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String username;
  final String message;
  final String timeText;
  final Color statusColor;
  final bool isUnread;
  final VoidCallback onTap;
  final bool compact;

  const _HistoryCard({
    required this.username,
    required this.message,
    required this.timeText,
    required this.statusColor,
    required this.isUnread,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: compact ? 132 : 118,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EEF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread ? const Color(0xFFB09BFF) : const Color(0xFFCAC5CF),
              width: isUnread ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: compact ? 10 : 14),
              CircleAvatar(
                radius: compact ? 18 : 20,
                backgroundColor: const Color(0xFFD7C9F0),
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Color(0xFF5A4B76),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 12 : 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              username,
                              style: TextStyle(
                                fontSize: compact ? 16 : 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2A292C),
                              ),
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeText.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(left: compact ? 6 : 10),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: compact ? 88 : 120,
                                ),
                                child: Text(
                                  timeText,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 12 : 13,
                                    color: const Color(0xFF9A96A1),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: compact ? 6 : 3),
                      Text(
                        message,
                        maxLines: compact ? 4 : 3,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          height: 1.2,
                          color: const Color(0xFF4C4A50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: compact ? 16 : 96,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;
  final String trailingText;
  final IconData icon;
  final bool showAction;
  final bool isUnread;
  final VoidCallback? onTap;

  const _ActivityCard({
    required this.isDark,
    required this.title,
    required this.body,
    required this.trailingText,
    required this.icon,
    required this.isUnread,
    this.showAction = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 700;
    final cardColor = isDark ? const Color(0xFFB9B8BB) : const Color(0xFFF1F1F2);
    final textColor = isDark ? const Color(0xFF242428) : const Color(0xFF2C2B30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 18,
            vertical: isCompact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? const Color(0xFF8E71FF) : const Color(0xFFD1CDD7),
              width: isUnread ? 1.8 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: isCompact ? 26 : 34),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 20 : 28,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: isCompact ? 4 : null,
                      overflow:
                          isCompact ? TextOverflow.ellipsis : TextOverflow.visible,
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 17,
                        height: 1.3,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Padding(
                padding: EdgeInsets.only(right: isCompact ? 0 : 6, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trailingText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFFA7A2AE),
                        fontSize: isCompact ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isCompact ? 8 : 10),
                    if (showAction)
                      OutlinedButton.icon(
                        onPressed: onTap,
                        icon: Icon(Icons.logout, size: isCompact ? 16 : 20),
                        label: Text(
                          'Ir',
                          style: TextStyle(fontSize: isCompact ? 12 : 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF55525D),
                          side: const BorderSide(color: Color(0xFFC2BECA)),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 10 : 14,
                            vertical: isCompact ? 8 : 10,
                          ),
                          minimumSize: Size(isCompact ? 0 : 72, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;

  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCAC5CF)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF6A6671),
        ),
      ),
    );
  }
}
