import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/screens/admin/manage_posts_screen.dart';
import 'package:metroswap/screens/admin/manage_profiles_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  
  int _totalMembers = 0;
  int _totalProducts = 0;
  int _totalExchanges = 0;
  double _totalContributions = 0.0;
  int _suspendedUsers = 0; 
  
  Map<String, int> _careerCounts = {};

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
    _fetchDashboardData();
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

        if (data['status'] == 'Suspendido') {
          suspendedCount++;
        }
      }

      final postsSnap = await FirebaseFirestore.instance.collection('posts').count().get();

      if (mounted) {
        setState(() {
          _totalMembers = memberCount;
          _suspendedUsers = suspendedCount; 
          _careerCounts = tempCareerCounts;
          _totalProducts = postsSnap.count ?? 0;
          _totalExchanges = 0; 
          _totalContributions = 0.0; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo datos del dashboard: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E9EB),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: false, heading: 'Dashboard'),
          
        
          const SizedBox(height: 20), // Un pequeño espacio para respirar

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Tarjeta de productos la cual llevas a posts
                                  Expanded(
                                    child: _buildKpiCard(
                                      'Total productos', 
                                      _totalProducts.toString(), 
                                      Icons.computer,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePostsScreen())),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  // TARJETA DE MIEMBROS -> LLEVA A PERFILES
                                  Expanded(
                                    child: _buildKpiCard(
                                      'Miembros', 
                                      _totalMembers.toString(), 
                                      Icons.person,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProfilesScreen())),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  // tarjeta de suspendidos -> lleva a suspendidos
                                  Expanded(
                                    child: _buildKpiCard(
                                      'Suspendidos', 
                                      _suspendedUsers.toString(), 
                                      Icons.person_off,
                                      onTap: () => Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => const ManageProfilesScreen(showOnlySuspended: true) // ¡AQUÍ ESTÁ LA MAGIA!
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(child: _buildKpiCard('Total contribuciones', '\$$_totalContributions', Icons.attach_money, isLarge: true)),
                                  const SizedBox(width: 15),
                                  Expanded(child: _buildKpiCard('Total Intercambios', _totalExchanges.toString(), Icons.swap_horiz, isLarge: true)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              
                              Container(
                                width: double.infinity,
                                height: 260, 
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Actividad Semanal (Simulada)',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: LineChart(
                                        LineChartData(
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval: 2,
                                            getDrawingHorizontalLine: (value) {
                                              return FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1);
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            show: true,
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30,
                                                interval: 1,
                                                getTitlesWidget: (value, meta) {
                                                  const style = TextStyle(color: Colors.grey, fontSize: 12);
                                                  Widget text;
                                                  switch (value.toInt()) {
                                                    case 0: text = const Text('Lun', style: style); break;
                                                    case 1: text = const Text('Mar', style: style); break;
                                                    case 2: text = const Text('Mié', style: style); break;
                                                    case 3: text = const Text('Jue', style: style); break;
                                                    case 4: text = const Text('Vie', style: style); break;
                                                    case 5: text = const Text('Sáb', style: style); break;
                                                    case 6: text = const Text('Dom', style: style); break;
                                                    default: text = const Text('', style: style); break;
                                                  }
                                                  return SideTitleWidget(meta: meta, child: text);
                                                },
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                interval: 2,
                                                reservedSize: 30,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12));
                                                },
                                              ),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          minX: 0, maxX: 6, minY: 0, maxY: 10,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: const [
                                                FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 2), FlSpot(3, 8), 
                                                FlSpot(4, 4), FlSpot(5, 7), FlSpot(6, 9), 
                                              ],
                                              isCurved: true,
                                              color: const Color(0xFFC93C20), 
                                              barWidth: 4,
                                              isStrokeCapRound: true,
                                              dotData: const FlDotData(show: true),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: const Color(0xFFC93C20).withValues(alpha: 0.1), 
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 30),

                        Expanded(
                          flex: 4,
                          child: Container(
                            height: 480,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estadísticas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: _careerCounts.isEmpty 
                                    ? const Center(child: Text('No hay datos de carreras aún'))
                                    : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PieChart(
                                            PieChartData(
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 80,
                                              sections: _getChartSections(),
                                            ),
                                          ),
                                          const Text(
                                            'Carreras\nsolicitantes',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                ),
                                const SizedBox(height: 20),
                                _buildLegend(), 
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const MetroSwapFooter(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getChartSections() {
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    _careerCounts.forEach((career, count) {
      final percentage = (count / _totalMembers) * 100;
      sections.add(
        PieChartSectionData(
          color: _chartColors[colorIndex % _chartColors.length],
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 40,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      colorIndex++;
    });

    return sections;
  }

  Widget _buildLegend() {
    int colorIndex = 0;
    return Wrap(
      spacing: 15,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _careerCounts.keys.map((career) {
        final color = _chartColors[colorIndex % _chartColors.length];
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(career, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        );
      }).toList(),
    );
  }

  // Ahora acepta un 'onTap' y usa 'InkWell' para ser clickable 
  Widget _buildKpiCard(String title, String value, IconData icon, {bool isLarge = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent, // Necesario para que el InkWell muestre el efecto sobre el fondo blanco
        child: InkWell(
          onTap: onTap, // Aquí le pasamos la acción (a dónde ir)
          borderRadius: BorderRadius.circular(15),
          hoverColor: Colors.orange.withValues(alpha: 0.05), // Colorcito suave al pasar el mouse
          child: Padding(
            padding: EdgeInsets.all(isLarge ? 25.0 : 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withValues(alpha: 0.2)),
                      child: Icon(icon, color: const Color(0xFFFF5C00), size: isLarge ? 28 : 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: TextStyle(color: Colors.grey[700], fontSize: isLarge ? 16 : 12), maxLines: 2)),
                    
                    // Si la tarjeta tiene una acción (onTap), mostramos una flechita sutil
                    if (onTap != null)
                      Icon(Icons.chevron_right, color: Colors.grey.withValues(alpha: 0.5), size: 20),
                  ],
                ),
                const SizedBox(height: 15),
                Text(value, style: TextStyle(fontSize: isLarge ? 32 : 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}