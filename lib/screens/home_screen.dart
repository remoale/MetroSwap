import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/exchange/material_detail_screen.dart';
import 'package:metroswap/screens/landing_screen.dart';
import 'package:metroswap/screens/notifications/notifications_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_brand.dart'; 
import 'package:metroswap/screens/profile/profile_screen.dart'; 
import 'package:metroswap/screens/publish/publish_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<Map<String, dynamic>>> _searchPosts(String rawTerm) async {
    final searchTerm = PostModel.normalizeSearchText(rawTerm);
    if (searchTerm.isEmpty) {
      return const [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('status', isEqualTo: PostModel.statusActive)
        .limit(75)
        .get();

    final matches = snapshot.docs
        .map((doc) => doc.data())
        .where((data) {
          final searchableText = _buildSearchableText(data);
          return searchableText.contains(searchTerm);
        })
        .take(8)
        .toList();

    return matches;
  }

  String _buildSearchableText(Map<String, dynamic> data) {
    final stored = data['searchableText']?.toString();
    if (stored != null && stored.trim().isNotEmpty) {
      return PostModel.normalizeSearchText(stored);
    }

    return PostModel.buildSearchableText(
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      materialType: data['materialType']?.toString() ?? '',
      knowledgeArea: data['knowledgeArea']?.toString() ?? '',
      career: data['career']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
    );
  }

  String _buildSuggestionSubtitle(Map<String, dynamic> data) {
    final description = data['description']?.toString().trim() ?? '';
    if (description.isNotEmpty) {
      return description.length > 90
          ? '${description.substring(0, 90)}...'
          : description;
    }

    final pieces = [
      data['materialType']?.toString().trim() ?? '',
      data['subject']?.toString().trim() ?? '',
      data['career']?.toString().trim() ?? '',
    ].where((value) => value.isNotEmpty).toList();

    return pieces.isEmpty ? 'Sin descripcion disponible.' : pieces.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      endDrawer: isMobile ? _buildMobileDrawer(context) : null,
      appBar: isMobile
          ? AppBar(
              toolbarHeight: 70,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              backgroundColor: const Color(0xFF2C2C2C),
              title: const MetroSwapBrand(),
              actions: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      padding: const EdgeInsets.only(right: 20),
                      icon: const Icon(
                        Icons.menu,
                        color: Color(0xFFFF6B00),
                        size: 40,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    );
                  },
                )
              ],
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!isMobile)
              const MetroSwapNavbar(developmentNav: true, heading: 'Inicio'),
            
            SizedBox(
              height: isMobile ? 280 : 330, 
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: isMobile ? 250 : 300,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage(
                          'assets/images/fondo_estudiantes.jpg',
                        ),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.orange.withValues(alpha: -8),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Todo lo que necesitas para tu trimestre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 32 : 42, 
                        fontWeight: FontWeight.w300,
                        shadows: const [
                          Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: isMobile ? screenWidth - 40 : 600, 
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SearchAnchor(
                        isFullScreen: false, 
                        builder: (context, controller) {
                          return SearchBar(
                            controller: controller,
                            hintText: 'Buscar por título, material o materia...',
                            hintStyle: const WidgetStatePropertyAll(
                              TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            backgroundColor: 
                            const WidgetStatePropertyAll(Colors.transparent),
                            elevation: const WidgetStatePropertyAll(0),
                            onTap: controller.openView,
                            onChanged: (_) => controller.openView(),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 25),
                            ),
                            trailing: const [
                              Icon(Icons.search, color: Colors.black54),
                            ],
                          );
                        },
                        suggestionsBuilder: (context, controller) async {
                          if (controller.text.trim().isEmpty) {
                            return const [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Escribe para buscar...'),
                                ),
                              ),
                            ];
                          }

                          try {
                            final results = await _searchPosts(controller.text);
                            if (results.isEmpty) {
                              return const [
                                ListTile(
                                  leading: Icon(Icons.search_off),
                                  title: Text('No se encontraron resultados.'),
                                  subtitle: Text(
                                    'Prueba con otra palabra o revisa publicaciones activas.',
                                  ),
                                ),
                              ];
                            }

                            return results.map((data) {
                              final title = data['title']?.toString() ?? 'Sin titulo';
                              final imageUrl = data['imageUrl']?.toString();
                              final post = PostModel.fromMap(data);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            webHtmlElementStrategy: kIsWeb
                                                ? WebHtmlElementStrategy.prefer
                                                : WebHtmlElementStrategy.never,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.book, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    _buildSuggestionSubtitle(data),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ),
                                onTap: () {
                                  controller.closeView(title);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MaterialDetailScreen(
                                        post: post,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList();
                          } on FirebaseException catch (e) {
                            return [
                              ListTile(
                                leading: const Icon(Icons.lock_outline),
                                title: const Text('No se pudo consultar publicaciones.'),
                                subtitle: Text(e.message ?? 'Intenta nuevamente.'),
                              ),
                            ];
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isMobile ? 40 : 80),
            Wrap(
              spacing: 80, 
              runSpacing: 40, 
              alignment: WrapAlignment.center,
              children: [
                _buildCategoryCard(
                  title: 'Libros',
                  imagePath: 'assets/images/libros.png',
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                ),
                _buildCategoryCard(
                  title: 'Materiales',
                  imagePath: 'assets/images/materiales.png',
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 60 : 100),
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String imagePath,
    required bool isMobile,
    required double screenWidth,
  }) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imagePath,
            width: isMobile ? screenWidth - 60 : 300, 
            height: isMobile ? 180 : 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isMobile ? 28 : 32, 
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2C2C),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        children: [
          const MetroSwapBrand(),
          const SizedBox(height: 40),
          
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Inicio', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context)  =>HomeScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text('Publicar', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context)  => PublishScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('Conócenos', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context)  => AboutScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.white),
            title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context)  => NotificationsScreen()));
            },
          ),

          const Divider(color: Colors.white54, height: 40),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              Navigator.pop(context); 
              if (user != null){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(uid: user.uid)),
                );
              }
            },
          ),

          const Divider(color: Colors.white54, height: 40),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF5C00)),
            title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFFF5C00), fontSize: 18)),
            onTap: () async {
              Navigator.pop(context); 
              
              await FirebaseAuth.instance.signOut();
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandingScreen(), 
                  ),
                  (Route<dynamic> route) => false, 
                );
              }
            }
          ),
        ],
      ),
    );
  }
}

class ResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Publicacion';
    final method = data['method']?.toString() ?? 'Intercambio';
    final priceUsd = data['priceUsd']?.toString() ?? '0.00';
    final subject = data['subject']?.toString() ?? 'Sin materia';
    final condition = data['condition']?.toString() ?? 'Sin estado';
    final description =
        data['description']?.toString() ?? 'Sin descripcion disponible.';
    final imageUrl = data['imageUrl']?.toString();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: kIsWeb
                          ? WebHtmlElementStrategy.prefer
                          : WebHtmlElementStrategy.never,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.blueGrey),
                    )
                  else
                    Container(color: Colors.blueGrey),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(method),
                        backgroundColor:
                            Colors.blueAccent.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Precio: \$$priceUsd',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Materia: $subject',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estado: $condition',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Divider(height: 40),
                      const Text(
                        'Descripcion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 500),
                      const Text('Fin del contenido.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}