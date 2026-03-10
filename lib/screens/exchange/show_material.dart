import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/models/post_model.dart'; 

class TradeScreen extends StatelessWidget {
  final PostModel post; 
  final dynamic user; 

  const TradeScreen({
    super.key, 
    required this.post,
    this.user, 
  });

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
              heading: 'Intercambio'
            ),
            
            const SizedBox(height: 60),
            // 2. Contenedor principal de la vista
            SizedBox(
              width: 1100, 
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: post.imageUrl.isNotEmpty
                          ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                  ),

                  const SizedBox(width: 50),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title, 
                          style: const TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)
                          ),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(uid: post.ownerUid),
                              ),
                            );
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFF5A5860),
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.ownerName, 
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.blue[700]
                                      ),
                                    ),
                                    if (user != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${user!.reputation}',
                                            style: const TextStyle(
                                              fontSize: 16, 
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF9800)
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.star,
                                            color: Color.fromARGB(242, 241, 255, 52),
                                            size: 18, 
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${user!.tradesCount})',
                                            style: const TextStyle(
                                              fontSize: 14, 
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Row(
                          children: [
                            _buildInfoBadge('Área', post.knowledgeArea), 
                            const SizedBox(width: 30),
                            _buildInfoBadge('Método', post.method), 
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
                          child: Text(
                            post.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Botón de Intercambiar
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
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.handshake_outlined, color: Colors.white, size: 28),
                                SizedBox(width: 10),
                                Text(
                                  'Intercambiar',
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
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.menu_book, 
        size: 150,
        color: Colors.grey[400],
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