import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> {
  // Lista simulada de publicaciones
  final List<Map<String, dynamic>> _mockPosts = [
    {
      'id': '1',
      'title': 'Calculo diferencial de Larson',
      'author': 'f.sandoval@correo.unimet.edu.ve',
      'date': '05 Mar 2026',
      'status': 'Disponible',
    },
    {
      'id': '2',
      'title': 'Calculadora Científica Casio',
      'author': 'andres.mujica@correo.unimet.edu.ve',
      'date': '04 Mar 2026',
      'status': 'Intercambiado',
    },
    {
      'id': '3',
      'title': 'Bata de laboratorio (Talla M)',
      'author': 'victoria.uzcategui@correo.unimet.edu.ve',
      'date': '01 Mar 2026',
      'status': 'Disponible',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E9EB),
      body: Column(
        children: [
          // Barra de navegación superior
          const MetroSwapNavbar(developmentNav: false, heading: 'Gestionar Publicaciones'),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Publicaciones Activas e Históricas',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        // Botón para volver al Dashboard
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver al Dashboard'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC93C20),
                            side: const BorderSide(color: Color(0xFFC93C20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Tabla de datos
                    SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith(
                          (states) => Colors.grey.withValues(alpha: 0.1),
                        ),
                        columns: const [
                          DataColumn(label: Text('Título / Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Autor (Correo)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _mockPosts.map((post) {
                          return DataRow(
                            cells: [
                              DataCell(Text(post['title'])),
                              DataCell(Text(post['author'])),
                              DataCell(Text(post['date'])),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: post['status'] == 'Disponible' 
                                        ? Colors.green.withValues(alpha: 0.1) 
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    post['status'],
                                    style: TextStyle(
                                      color: post['status'] == 'Disponible' ? Colors.green[700] : Colors.orange[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Eliminar publicación',
                                  onPressed: () {
                                    // Aquí irá la lógica para borrar de Firebase en el futuro
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Función de eliminar en desarrollo')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Pie de página
          const MetroSwapFooter(),
        ],
      ),
    );
  }
}