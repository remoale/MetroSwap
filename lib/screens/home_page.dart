import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E2E2E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.swap_horizontal_circle, color: Colors.orange, size: 30),
            SizedBox(width: 8),
            Text('MetroSwap',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {},
              child: const Text('Publicar', style: TextStyle(color: Colors.white))),
          TextButton(
              onPressed: () {},
              child: const Text('Conócenos', style: TextStyle(color: Colors.white))),
          const Icon(Icons.notifications_none, color: Colors.white),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SECCIÓN SUPERIOR CON IMAGEN Y BUSCADOR
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=1000'),
                      fit: BoxFit.cover,
                      colorFilter:
                          ColorFilter.mode(Colors.black45, BlendMode.darken),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Todo lo que necesitas para tu trimestre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w300),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -25,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por título, material o materia...',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 50),

            // SECCIÓN DE CATEGORÍAS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryCard('Libros',
                        'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?q=80&w=500'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildCategoryCard('Materiales',
                        'https://images.unsplash.com/photo-1532094349884-543bc11b234d?q=80&w=500'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // FOOTER
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF2E2E2E),
              width: double.infinity,
              child: const Text(
                '© 2026 MetroSwap - Universidad Metropolitana.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, String imageUrl) {
    return Column(
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
                image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                color: Colors.black54, // Cambiado de grey a black54 para mejor visibilidad
                fontWeight: FontWeight.w400)),
      ],
    );
  }
}