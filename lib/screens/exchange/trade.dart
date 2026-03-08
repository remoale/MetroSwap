import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class TradeScreen extends StatelessWidget {
  const TradeScreen({super.key});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Encabezado actualizado
            const MetroSwapNavbar(
              developmentNav: true, 
              heading: 'Tradea'
            ),
            
            const SizedBox(height: 60),

            // 2. Contenedor principal de la vista
            SizedBox(
              width: 900, 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- COLUMNA IZQUIERDA: Foto del material ya publicado ---
                  Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book, 
                        size: 150,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),

                  const SizedBox(width: 50),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Libro de Cálculo Diferencial e Integral',
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)
                          ),
                        ),
                        
                        const SizedBox(height: 25),

                        Row(
                          children: [
                            _buildInfoBadge('Categoría', 'Ingeniería'),
                            const SizedBox(width: 30),
                            _buildInfoBadge('Método', 'Intercambio'),
                          ],
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Libro en excelente estado, usado solo durante un trimestre. Tiene algunas anotaciones a lápiz en los primeros capítulos, pero nada que impida la lectura. Busco a cambio material de Física 1 o implementos de dibujo técnico.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Botón de Tradear
                        SizedBox(
                          width: double.infinity,
                          height: 60, 
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              // Aquí irá la lógica para iniciar el tradeo luego
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.handshake_outlined, color: Colors.white, size: 28),
                                SizedBox(width: 10),
                                Text(
                                  'Tradear',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold
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

            const SizedBox(height: 100),
            
            // 3. Footer
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(fontSize: 14, color: Colors.grey[600])
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF333333), // Fondo oscuro
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value, 
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w500,
              fontSize: 15
            ),
          ),
        ),
      ],
    );
  }
}