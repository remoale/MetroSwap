import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart'; // 1. Agregamos esta línea

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333), 
      body: Column(
        children: [
          // 1. Navbar
          const MetroSwapNavbar(developmentNav: true, heading: 'Conócenos'),

          // 2. Cuerpo principal
          Expanded(
            child: Row(
              children: [
                // --- COLUMNA IZQUIERDA (Fondo mármol e integrantes) ---
                Expanded(
                  flex: 6, 
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/fondo_marmol.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      // Usamos SingleChildScrollView por si la pantalla es muy pequeña
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // FILA 1: Forzamos 3 elementos
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTeamMember(name: 'Diego Guzmán', age: '18', ig: '@diego_guzguz', imagePath: 'assets/images/diego.png'),
                                _buildTeamMember(name: 'Derek Carvajal', age: '22', ig: '@dcarvajal_13', imagePath: 'assets/images/derek.png'),
                                _buildTeamMember(name: 'Daniela Pacheco', age: '18', ig: '@dpacc_7', imagePath: 'assets/images/daniela.png'),
                              ],
                            ),
                            const SizedBox(height: 50), // Espacio grande entre la fila 1 y 2
                            // FILA 2: Forzamos 3 elementos
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTeamMember(name: 'Simón Ananian', age: '20', ig: '@simon_ananian_hurtado', imagePath: 'assets/images/simon.png'),
                                _buildTeamMember(name: 'Andrés Mujica', age: '20', ig: '@mujica550', imagePath: 'assets/images/andres.png'),
                                _buildTeamMember(name: 'Remo Agostinelli', age: '21', ig: '@remoax', imagePath: 'assets/images/remo.png'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- COLUMNA DERECHA (Foto trabajando) ---
                Expanded(
                  flex: 4, 
                  child: Image.asset(
                    'assets/images/equipo_trabajando.png', 
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),

          // 3. Footer
          const MetroSwapFooter(), // 2. ¡Reemplazamos el Container por nuestro widget mágico!
        ],
      ),
    );
  }

  // Widget auxiliar rediseñado con ClipRRect e Image.asset directo para máxima calidad web
  Widget _buildTeamMember({
    required String name,
    required String age,
    required String ig,
    required String imagePath,
  }) {
    return SizedBox(
      width: 150, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // Usamos ClipRRect en lugar de Container con DecorationImage para que no se pixele
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: 150,
              height: 190,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high, // Fuerza el mejor escalado
              isAntiAlias: true, // Suaviza los bordes 
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$age años',
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.instagram, size: 16, color: Colors.black87), 
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ig,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}