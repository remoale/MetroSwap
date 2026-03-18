import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/screens/admin/manage_posts_screen.dart';
import 'package:metroswap/screens/admin/manage_profiles_screen.dart';
import 'package:metroswap/utils/admin_utils.dart';

/// Muestra el panel administrativo con métricas y accesos de gestión.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isAuthorizing = true;
  bool _isAuthorized = false;
  bool _isLoading = true;
  
  int _totalMembers = 0;
  int _totalProducts = 0;
  int _totalExchanges = 0;
  double _totalContributions = 0.0;
  int _suspendedUsers = 0; 
  
  Map<String, int> _careerCounts = {};
  // Guarda la actividad semanal de lunes a domingo.
  List<double> _weeklyActivity = List.filled(7, 0.0);
  List<MapEntry<String, int>> _topDemandedBooks = [];

  final List<Color> _chartColors = [
    const Color(0xFFEF476F), 
    const Color(0xFFFFD166), 
    const Color(0xFF06D6A0), 
    const Color(0xFF118AB2), 
    const Color(0xFF073B4C), 
    const Color(0xFFFF9F1C), 
    const Color(0xFF9D4EDD), 
  ];

  @override
  void initState() {
    super.initState();
    _authorizeAndFetch();
  }

  Future<void> _authorizeAndFetch() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final isAuthorized = isAdminEmail(email);

    if (!mounted) return;
    setState(() {
      _isAuthorized = isAuthorized;
      _isAuthorizing = false;
    });

    if (!isAuthorized) return;
    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      int memberCount = usersSnap.docs.length;
      int suspendedCount = 0; 
      Map<String, int> tempCareerCounts = {};

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        String career = (data['career'] ?? 'No especificada').toString().trim();
        if (career.isEmpty) career = 'No especificada';
        tempCareerCounts[career] = (tempCareerCounts[career] ?? 0) + 1;
        if (isSuspendedUserStatus(data['status'])) suspendedCount++;
      }

      final postsSnap = await FirebaseFirestore.instance.collection('posts').get();
      int productsCount = postsSnap.docs.length;
      List<double> tempWeeklyActivity = List.filled(7, 0.0);

      for (var doc in postsSnap.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          DateTime dt;
          if (data['createdAt'] is Timestamp) {
            dt = (data['createdAt'] as Timestamp).toDate();
          } else {
            dt = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
          }
          int dayIndex = dt.weekday - 1; 
          if (dayIndex >= 0 && dayIndex < 7) tempWeeklyActivity[dayIndex] += 1;
        }
      }

      int exchangesCount = 0;
      double tempContributions = 0.0;
      Map<String, int> tempBookDemand = {};
      
      try {
        final exchangesSnap = await FirebaseFirestore.instance.collection('exchanges').get();
        exchangesCount = exchangesSnap.docs.length;

        for (var doc in exchangesSnap.docs) {
          final data = doc.data();
          String status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'completed') {
            var monto = data['paypalAmount'] ?? data['price'] ?? data['amount'] ?? data['contribution'];
            if (monto != null) {
              tempContributions += double.tryParse(monto.toString()) ?? 0.0;
            }
          }
          String bookTitle = (data['postTitle'] ?? 'Desconocido').toString();
          if (bookTitle.isNotEmpty && bookTitle != 'Desconocido') {
            tempBookDemand[bookTitle] = (tempBookDemand[bookTitle] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint("Error al leer la colección exchanges: $e");
      }

      var sortedDemand = tempBookDemand.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); 
      List<MapEntry<String, int>> top5Books = sortedDemand.take(5).toList();

      if (mounted) {
        setState(() {
          _totalMembers = memberCount;
          _suspendedUsers = suspendedCount; 
          _careerCounts = tempCareerCounts;
          _totalProducts = productsCount;
          _weeklyActivity = tempWeeklyActivity;
          _totalExchanges = exchangesCount; 
          _totalContributions = tempContributions; 
          _topDemandedBooks = top5Books; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo datos del dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Calcula el valor máximo del gráfico.
  double _getMaxY() {
    double maxVal = 10.0; 
    for (var val in _weeklyActivity) {
      if (val > maxVal) maxVal = val;
    }
    return maxVal + 2.0; 
  }

  double _getMaxBarY() {
    if (_topDemandedBooks.isEmpty) return 5.0;
    double maxVal = _topDemandedBooks.first.value.toDouble();
    return maxVal + 2.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E9EB),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: false, heading: 'Dashboard'),
          const SizedBox(height: 20),
          Expanded(
            child: _isAuthorizing
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
                : !_isAuthorized
                    ? _buildUnauthorizedState()
                    : _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 30.0 : (isTablet ? 20.0 : 14.0),
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: [
                        isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        _buildKpiSection(
                                          isDesktop: true,
                                          isTablet: false,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildLineChart(isCompact: false),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    flex: 4,
                                    child: _buildPieChartCard(isCompact: false),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildKpiSection(
                                    isDesktop: false,
                                    isTablet: isTablet,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildLineChart(isCompact: true),
                                  const SizedBox(height: 20),
                                  _buildPieChartCard(isCompact: true),
                                ],
                              ),
                         
                         const SizedBox(height: 30),
                        _buildTopBooksBarChart(
                          isDesktop,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
          const MetroSwapFooter(),
        ],
      ),
    );
  }

  Widget _buildKpiSection({
    required bool isDesktop,
    required bool isTablet,
  }) {
    if (isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCard('Total productos', _totalProducts.toString(), Icons.computer, onTap: _openManagePosts)),
              const SizedBox(width: 15),
              Expanded(child: _buildKpiCard('Miembros', _totalMembers.toString(), Icons.person, onTap: _openManageProfiles)),
              const SizedBox(width: 15),
              Expanded(child: _buildKpiCard('Suspendidos', _suspendedUsers.toString(), Icons.person_off, onTap: () => _openManageProfiles(showOnlySuspended: true))),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildKpiCard('Total contribuciones', '\$${_totalContributions.toStringAsFixed(2)}', Icons.attach_money, isLarge: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildKpiCard('Total Intercambios', _totalExchanges.toString(), Icons.swap_horiz, isLarge: true)),
            ],
          ),
        ],
      );
    } else {
      final cards = [
        _buildKpiCard('Total productos', _totalProducts.toString(), Icons.computer, onTap: _openManagePosts, compact: true),
        _buildKpiCard('Miembros', _totalMembers.toString(), Icons.person, onTap: _openManageProfiles, compact: true),
        _buildKpiCard('Suspendidos', _suspendedUsers.toString(), Icons.person_off, onTap: () => _openManageProfiles(showOnlySuspended: true), compact: true),
        _buildKpiCard('Total contribuciones', '\$${_totalContributions.toStringAsFixed(2)}', Icons.attach_money, isLarge: true, compact: true),
        _buildKpiCard('Total Intercambios', _totalExchanges.toString(), Icons.swap_horiz, isLarge: true, compact: true),
      ];

      if (isTablet) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: 260, child: card))
              .toList(),
        );
      }

      return Column(
        children: [
          cards[0],
          const SizedBox(height: 10),
          cards[1],
          const SizedBox(height: 10),
          cards[2],
          const SizedBox(height: 10),
          cards[3],
          const SizedBox(height: 10),
          cards[4],
        ],
      );
    }
  }

  Widget _buildLineChart({required bool isCompact}) {
    return Container(
      width: double.infinity,
      height: isCompact ? 220 : 260,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad Semanal',
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isCompact ? 14 : 20),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87, 
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(spot.y.toInt().toString(), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true, drawVerticalLine: false, horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30, interval: 1,
                      getTitlesWidget: (value, meta) {
                        final style = TextStyle(color: Colors.grey, fontSize: isCompact ? 10 : 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = Text('Lun', style: style); break;
                          case 1: text = Text('Mar', style: style); break;
                          case 2: text = Text('Mié', style: style); break;
                          case 3: text = Text('Jue', style: style); break;
                          case 4: text = Text('Vie', style: style); break;
                          case 5: text = Text('Sáb', style: style); break;
                          case 6: text = Text('Dom', style: style); break;
                          default: text = Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, interval: 2, reservedSize: isCompact ? 26 : 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.grey, fontSize: isCompact ? 10 : 12),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 0, maxY: _getMaxY(), 
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (index) => FlSpot(index.toDouble(), _weeklyActivity[index])),
                    isCurved: true, color: const Color(0xFFC93C20), barWidth: 4, isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFFC93C20).withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard({required bool isCompact}) {
    return Container(
      height: isCompact ? 420 : 480,
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(fontSize: isCompact ? 18 : 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isCompact ? 14 : 20),
          Expanded(
            child: _careerCounts.isEmpty 
              ? const Center(child: Text('No hay datos de carreras aún'))
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: isCompact ? 58 : 80,
                        sections: _getChartSections(isCompact: isCompact),
                      ),
                    ),
                    Text(
                      'Carreras\nsolicitantes',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: isCompact ? 13 : 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
          ),
          SizedBox(height: isCompact ? 14 : 20),
          _buildLegend(isCompact: isCompact), 
        ],
      ),
    );
  }

  Widget _buildTopBooksBarChart(bool isDesktop, {required bool isMobile}) {
    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 350,
      padding: EdgeInsets.all(isDesktop ? 25 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Libros con mayor demanda (Top 5)', 
            style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.black87)
          ),
          SizedBox(height: isMobile ? 20 : 30),
          Expanded(
            child: _topDemandedBooks.isEmpty
                ? const Center(child: Text('No hay solicitudes suficientes para mostrar métricas', style: TextStyle(color: Colors.grey)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxBarY(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String title = _topDemandedBooks[group.x.toInt()].key;
                            return BarTooltipItem(
                              '$title\n${rod.toY.toInt()} solicitudes',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: isMobile ? 34 : 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() >= _topDemandedBooks.length) return const SizedBox.shrink();
                              String fullTitle = _topDemandedBooks[value.toInt()].key;
                              // Acorta más el título en pantallas pequeñas.
                              int maxLength = isDesktop ? 15 : 8; 
                              String shortTitle = fullTitle.length > maxLength ? '${fullTitle.substring(0, maxLength)}...' : fullTitle;
                              
                              return SideTitleWidget(
                                meta: meta,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    shortTitle,
                                    style: TextStyle(color: Colors.black54, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: isMobile ? 24 : 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) return const SizedBox.shrink(); 
                              return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        _topDemandedBooks.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _topDemandedBooks[i].value.toDouble(),
                              color: _chartColors[i % _chartColors.length],
                              // Usa barras más delgadas en móvil.
                              width: isDesktop ? 35 : 20,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManagePosts() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePostsScreen()));
    if (!mounted || !_isAuthorized) return;
    setState(() => _isLoading = true);
    await _fetchDashboardData();
  }

  Future<void> _openManageProfiles({bool showOnlySuspended = false}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => ManageProfilesScreen(showOnlySuspended: showOnlySuspended)));
    if (!mounted || !_isAuthorized) return;
    setState(() => _isLoading = true);
    await _fetchDashboardData();
  }

  Widget _buildUnauthorizedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No tienes permisos de administrador para acceder a este panel.', style: TextStyle(fontSize: 16, color: Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('Volver')),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getChartSections({required bool isCompact}) {
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    _careerCounts.forEach((career, careerCount) {
      final percentage = (careerCount / _totalMembers) * 100;
      sections.add(
        PieChartSectionData(
          color: _chartColors[colorIndex % _chartColors.length],
          value: careerCount.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: isCompact ? 32 : 40,
          titleStyle: TextStyle(fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      colorIndex++;
    });
    return sections;
  }

  Widget _buildLegend({required bool isCompact}) {
    int colorIndex = 0;
    return Wrap(
      spacing: isCompact ? 10 : 15, runSpacing: isCompact ? 8 : 10, alignment: WrapAlignment.center,
      children: _careerCounts.keys.map((career) {
        final color = _chartColors[colorIndex % _chartColors.length];
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(career, style: TextStyle(fontSize: isCompact ? 12 : 13, color: Colors.black87)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, {bool isLarge = false, VoidCallback? onTap, bool compact = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent, 
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(15), hoverColor: Colors.orange.withValues(alpha: 0.05), 
          child: Padding(
            padding: EdgeInsets.all(compact ? (isLarge ? 18.0 : 14.0) : (isLarge ? 25.0 : 15.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withValues(alpha: 0.2)),
                      child: Icon(icon, color: const Color(0xFFFF5C00), size: compact ? (isLarge ? 24 : 18) : (isLarge ? 28 : 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: TextStyle(color: Colors.grey[700], fontSize: compact ? (isLarge ? 14 : 11) : (isLarge ? 16 : 12)), maxLines: 2)),
                    if (onTap != null) Icon(Icons.chevron_right, color: Colors.grey.withValues(alpha: 0.5), size: 20),
                  ],
                ),
                SizedBox(height: compact ? 12 : 15),
                Text(value, style: TextStyle(fontSize: compact ? (isLarge ? 26 : 22) : (isLarge ? 32 : 24), fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
