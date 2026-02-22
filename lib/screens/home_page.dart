import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/screens/admin/admin_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isAdmin = false; // Aquí se guarda si eres admin

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // Revisamos el nivel de acceso al cargar la pantalla
  }

  // Función para preguntarle a Firestore si eres el admin
  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            isAdmin = doc.data()?['isAdmin'] ?? false;
          });
        }
      } catch (e) {
        debugPrint("Error verificando rol de admin: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6), // Color de fondo gris claro/lila
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera
            Container(
              height: 70,
              color: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // Logo y Título (Ahora es un boton solo para el admin)
                  MouseRegion(
                    cursor: isAdmin ? SystemMouseCursors.click : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTap: isAdmin
                          ? () {
                              // Navegación a la pantalla especial del admin
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminScreen(),
                                ),
                              );
                            }
                          : null,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo_metroswap.png',
                            height: 60, 
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'MetroSwap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Publicar'),
                  ),
                  const SizedBox(width: 15),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Conócenos'),
                  ),
                  const SizedBox(width: 25),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.account_circle, color: Colors.white70, size: 35),
                    onPressed: () {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(uid: currentUser.uid),
                          ),
                        );
                      }
                    },
                  ),
                ], 
              ), 
            ), 

            // Hero y barra de busqueda
            SizedBox(
              height: 330,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Imagen de fondo local con filtro oscuro
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        // Usamos AssetImage para la imagen local
                        image: const AssetImage('assets/images/fondo_estudiantes.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5), // Un poco más oscuro para que resalte el texto
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Todo lo que necesitas para tu trimestre',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  
                  // Barra de búsqueda flotante
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 600,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const TextField( 
                        decoration: InputDecoration(
                          hintText: 'Buscar por titulo, material o materia..',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 15.0),
                            child: Icon(Icons.search, color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Libros y materiales 
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tarjeta Libros con imagen local
                _buildCategoryCard(
                  title: 'Libros',
                  imagePath: 'assets/images/libros.png',
                ),
                const SizedBox(width: 180), // Espacio entre las tarjetas
                
                _buildCategoryCard(
                  title: 'Materiales',
                  imagePath: 'assets/images/materiales.png',
                ),
              ],
            ),
            const SizedBox(height: 100),

      
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF333333),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                '© 2026 MetroSwap - Universidad Metropolitana.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _buildCategoryCard({required String title, required String imagePath}) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
        
          child: Image.asset(
            imagePath,
            width: 300,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white, // Color blanco para que resalte en el fondo gris
            fontSize: 32,
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(1, 1),
              )
            ]
          ),
        ),
      ],
    );
  }
}