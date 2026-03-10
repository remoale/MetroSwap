import 'package:firebase_auth/firebase_auth.dart';
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
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  bool _isInProgress(NotificationModel notification) {
    final rawStatus = notification.data?['status']?.toString().toLowerCase() ?? '';
    final normalizedType = notification.type.toLowerCase();
    return rawStatus == 'requested' ||
        rawStatus == 'accepted' ||
        normalizedType == 'exchange_started' ||
        normalizedType == 'exchange_requested' ||
        normalizedType == 'exchange_accepted';
  }

  Color _resolveStatusColor(NotificationModel notification, bool inProgress) {
    final rawStatus = notification.data?['status']?.toString().toLowerCase() ?? '';
    if (inProgress) {
      if (rawStatus == 'requested' || notification.type == 'exchange_requested') {
        return const Color(0xFFEBCD35);
      }
      return const Color(0xFF4E69E8);
    }
    if (rawStatus == 'failed' || notification.type == 'exchange_rejected') {
      return const Color(0xFFE35A06);
    }
    return const Color(0xFF84D264);
  }

  String _resolveUserName(NotificationModel notification) {
    final actorName = notification.data?['actorName']?.toString();
    if (actorName != null && actorName.trim().isNotEmpty) {
      return actorName;
    }
    return '[Nombre de Usuario]';
  }

  String _formatRelativeTime(DateTime? createdAt) {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
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
    final uid = _uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFDCD9DF),
        body: Column(
          children: const [
            MetroSwapNavbar(developmentNav: true, heading: 'Notificaciones'),
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
                const MetroSwapNavbar(developmentNav: true, heading: 'Notificaciones'),
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
          final inProgress = notifications.where(_isInProgress).toList();
          final history = notifications.where((n) => !_isInProgress(n)).toList();
          final latest = notifications.take(2).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const MetroSwapNavbar(developmentNav: true, heading: 'Notificaciones'),
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: notifications.isEmpty
                                    ? null
                                    : () => _notificationService.markAllAsRead(uid),
                                child: const Text('Marcar todas como leídas'),
                              ),
                            ],
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildSection(
                                    title: 'Historial',
                                    children: _buildHistoryCards(history),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  color: const Color(0xFF8D8A90),
                                ),
                                Expanded(
                                  child: _buildSection(
                                    title: 'En curso',
                                    children: _buildHistoryCards(inProgress),
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
                const MetroSwapFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildHistoryCards(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const [
        _EmptyStateCard(message: 'Sin notificaciones en esta sección.'),
      ];
    }

    final widgets = <Widget>[];
    final maxItems = notifications.length > 3 ? 3 : notifications.length;
    for (var i = 0; i < maxItems; i++) {
      final notification = notifications[i];
      final inProgress = _isInProgress(notification);
      widgets.add(
        _HistoryCard(
          username: _resolveUserName(notification),
          message: notification.body,
          timeText: _formatRelativeTime(notification.createdAt),
          statusColor: _resolveStatusColor(notification, inProgress),
          isUnread: !notification.read,
          onTap: () => _openNotification(notification),
        ),
      );
      if (i < maxItems - 1) {
        widgets.add(const SizedBox(height: 14));
      }
    }
    return widgets;
  }

  List<Widget> _buildActivityCards(List<NotificationModel> latest) {
    final first = latest.isNotEmpty ? latest[0] : null;
    final second = latest.length > 1 ? latest[1] : null;

    return [
      _ActivityCard(
        isDark: true,
        title: first?.title.isNotEmpty == true ? first!.title : 'Nueva Notificación!',
        body: first?.body ?? 'No hay actividad reciente.',
        trailingText: _formatRelativeTime(first?.createdAt),
        icon: Icons.dashboard_outlined,
        isUnread: first != null && !first.read,
        onTap: first == null ? null : () => _openNotification(first),
      ),
      _ActivityCard(
        isDark: false,
        title: second?.title.isNotEmpty == true ? second!.title : 'Notificación',
        body: second?.body ?? 'No hay actividad reciente.',
        trailingText: _formatRelativeTime(second?.createdAt),
        icon: Icons.person_outline,
        showAction: second != null && _exchangeIdFromNotification(second).isNotEmpty,
        isUnread: second != null && !second.read,
        onTap: second == null ? null : () => _openNotification(second),
      ),
    ];
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1E21),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
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

  const _HistoryCard({
    required this.username,
    required this.message,
    required this.timeText,
    required this.statusColor,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 88,
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
              const SizedBox(width: 14),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFD7C9F0),
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Color(0xFF5A4B76),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A292C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4C4A50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              timeText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9A96A1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 96,
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
    final cardColor = isDark ? const Color(0xFFB9B8BB) : const Color(0xFFF1F1F2);
    final textColor = isDark ? const Color(0xFF242428) : const Color(0xFF2C2B30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
              Icon(icon, color: textColor, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trailingText,
                    style: const TextStyle(
                      color: Color(0xFFA7A2AE),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (showAction)
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Ir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF55525D),
                        side: const BorderSide(color: Color(0xFFC2BECA)),
                      ),
                    ),
                ],
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
