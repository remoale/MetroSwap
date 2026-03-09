import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCD9DF),
      body: SingleChildScrollView(
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
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildSection(
                                title: 'Historial',
                                children: const [
                                  _HistoryCard(
                                    username: '[Nombre de Usuario]',
                                    message: 'Entregado!',
                                    timeText: 'Hace 5 min',
                                    statusColor: Color(0xFF84D264),
                                  ),
                                  SizedBox(height: 14),
                                  _HistoryCard(
                                    username: '[Nombre de Usuario]',
                                    message: 'No se llegó a un acuerdo',
                                    timeText: '',
                                    statusColor: Color(0xFFE35A06),
                                  ),
                                  SizedBox(height: 14),
                                  _HistoryCard(
                                    username: '[Nombre de Usuario]',
                                    message: 'Entregado!',
                                    timeText: '',
                                    statusColor: Color(0xFF84D264),
                                  ),
                                ],
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
                                children: const [
                                  _HistoryCard(
                                    username: '[Nombre de Usuario]',
                                    message: 'Estado: Solicitado',
                                    timeText: '',
                                    statusColor: Color(0xFFEBCD35),
                                  ),
                                  SizedBox(height: 14),
                                  _HistoryCard(
                                    username: '[Nombre de Usuario]',
                                    message: 'Estado: Aceptado',
                                    timeText: '',
                                    statusColor: Color(0xFF4E69E8),
                                  ),
                                ],
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
                          final horizontal = constraints.maxWidth >= 1000;
                          if (horizontal) {
                            return const Row(
                              children: [
                                Expanded(
                                  child: _ActivityCard(
                                    isDark: true,
                                    title: 'Nueva Notificación!',
                                    body: '[Nombre de Usuario] quiere realizar un intercambio contigo',
                                    trailingText: 'ahora',
                                    icon: Icons.dashboard_outlined,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: _ActivityCard(
                                    isDark: false,
                                    title: 'Notificación',
                                    body: '¡Nueva solicitud! [Nombre de Usuario] está interesado en tu material',
                                    trailingText: 'Hace 5 min',
                                    icon: Icons.person_outline,
                                    showAction: true,
                                  ),
                                ),
                              ],
                            );
                          }

                          return const Column(
                            children: [
                              _ActivityCard(
                                isDark: true,
                                title: 'Nueva Notificación!',
                                body: '[Nombre de Usuario] quiere realizar un intercambio contigo',
                                trailingText: 'ahora',
                                icon: Icons.dashboard_outlined,
                              ),
                              SizedBox(height: 16),
                              _ActivityCard(
                                isDark: false,
                                title: 'Notificación',
                                body: '¡Nueva solicitud! [Nombre de Usuario] está interesado en tu material',
                                trailingText: 'Hace 5 min',
                                icon: Icons.person_outline,
                                showAction: true,
                              ),
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
      ),
    );
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

  const _HistoryCard({
    required this.username,
    required this.message,
    required this.timeText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCAC5CF)),
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

  const _ActivityCard({
    required this.isDark,
    required this.title,
    required this.body,
    required this.trailingText,
    required this.icon,
    this.showAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFFB9B8BB) : const Color(0xFFF1F1F2);
    final textColor = isDark ? const Color(0xFF242428) : const Color(0xFF2C2B30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1CDD7)),
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
                  onPressed: () {},
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
    );
  }
}