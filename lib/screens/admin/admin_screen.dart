import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  
  // Variables para almacenar los datos reales de Firebase
  int _totalMembers = 0;
  int _totalProducts = 0;
  int _totalExchanges = 0;
  double _totalContributions = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ¡Magia de Firebase! Aquí leemos los datos reales
  Future<void> _fetchDashboardData() async {
    try {
      // 1. Contar total de usuarios
      final usersSnap = await FirebaseFirestore.instance.collection('users').count().get();
      // 2. Contar total de publicaciones (asumiendo que tu colección se llama 'posts' o 'products')
      final postsSnap = await FirebaseFirestore.instance.collection('posts').count().get();
      // 3. Contar intercambios (asumiendo colección 'exchanges', pon 0 si aún no existe)
      // final exchangesSnap = await FirebaseFirestore.instance.collection('exchanges').count().get();

      if (mounted) {
        setState(() {
          _totalMembers = usersSnap.count ?? 0;
          _totalProducts = postsSnap.count ?? 0;
          _totalExchanges = 0; // Cambiar cuando tengas la colección de intercambios
          _totalContributions = 0.0; // Cambiar cuando manejes pagos/donaciones
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
      backgroundColor: const Color(0xFFE8E9EB), // Color de fondo gris claro del mockup
      body: Column(
        children: [
          // 1. Navbar con el color terracota que hicimos
          const MetroSwapNavbar(developmentNav: false, heading: 'Dashboard'),

          // 2. Botones de Gestión (Lo que pediste nuevo)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navegar a pantalla de gestión de perfiles
                  },
                  icon: const Icon(Icons.people_alt),
                  label: const Text('Gestionar Perfiles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navegar a pantalla de gestión de publicaciones
                  },
                  icon: const Icon(Icons.library_books),
                  label: const Text('Gestionar Publicaciones'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC93C20), // Terracota
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // 3. Cuerpo del Dashboard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(30.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // COLUMNA IZQUIERDA (Tarjetas de KPIs)
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              // Fila 1: 3 Tarjetas pequeñas
                              Row(
                                children: [
                                  Expanded(child: _buildKpiCard('Total productos', _totalProducts.toString(), Icons.computer)),
                                  const SizedBox(width: 15),
                                  Expanded(child: _buildKpiCard('Miembros', _totalMembers.toString(), Icons.person)),
                                  const SizedBox(width: 15),
                                  Expanded(child: _buildKpiCard('Activos ahora', '1', Icons.monitor_heart)), // Simulado por ahora
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Fila 2: 2 Tarjetas medianas
                              Row(
                                children: [
                                  Expanded(child: _buildKpiCard('Total contribuciones', '\$$_totalContributions', Icons.attach_money, isLarge: true)),
                                  const SizedBox(width: 15),
                                  Expanded(child: _buildKpiCard('Total Intercambios', _totalExchanges.toString(), Icons.swap_horiz, isLarge: true)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Fila 3: Gráfico de línea (Espacio reservado)
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: const Center(
                                  child: Text('Gráfico de Actividad Semanal\n(Próximamente con fl_chart)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 30),

                        // COLUMNA DERECHA (Gráfico de Dona)
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: 480,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estadísticas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Center(
                                    child: Text('Gráfico de Dona de Carreras\n(Próximamente con fl_chart)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // 4. Footer
          const MetroSwapFooter(),
        ],
      ),
    );
  }

  // Widget auxiliar para crear las tarjetitas blancas con sombra
  Widget _buildKpiCard(String title, String value, IconData icon, {bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 25.0 : 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.2),
                ),
                child: Icon(icon, color: const Color(0xFFFF5C00), size: isLarge ? 28 : 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[700], fontSize: isLarge ? 16 : 12),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}