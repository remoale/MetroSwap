import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/exchange/material_detail_screen.dart';
import 'package:metroswap/screens/search/search_results_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_layout.dart';

/// Muestra la pantalla principal con buscador y acceso al material publicado.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<Map<String, dynamic>>> _searchPosts(String rawTerm) async {
    final matches = await SearchResultsScreen.searchPosts(rawTerm);
    return matches.take(8).toList();
  }

  String _buildSuggestionSubtitle(Map<String, dynamic> data) {
    return SearchResultsScreen.buildSuggestionSubtitle(data);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return MetroSwapLayout(
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
                          Colors.black.withValues(alpha: 0.4),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? screenWidth - 56 : 860,
                      ),
                      child: Text(
                        'Todo lo que necesitas\npara tu trimestre',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 32 : 42,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                          shadows: const [
                            Shadow(offset: Offset(0, 3), blurRadius: 16, color: Colors.black87),
                          ],
                        ),
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
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE7E2EA),
                        ),
                      ),
                      child: SearchAnchor(
                        isFullScreen: false, 
                        viewOnSubmitted: (value) {
                          final query = value.trim();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchResultsScreen(
                                initialQuery: query,
                              ),
                            ),
                          );
                        },
                        builder: (context, controller) {
                          return SearchBar(
                            controller: controller,
                            hintText: 'Buscar por título, material o materia...',
                            hintStyle: const WidgetStatePropertyAll(
                              TextStyle(
                                color: Color(0xFF8A8790),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: 
                            const WidgetStatePropertyAll(Colors.transparent),
                            elevation: const WidgetStatePropertyAll(0),
                            onTap: controller.openView,
                            onChanged: (_) => controller.openView(),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 25),
                            ),
                            trailing: [
                              IconButton(
                                onPressed: () {
                                  final query = controller.text.trim();
                                  controller.closeView(query);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultsScreen(
                                        initialQuery: query,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.black54,
                                ),
                                tooltip: 'Ver resultados',
                              ),
                            ],
                          );
                        },
                        suggestionsBuilder: (context, controller) async {
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

                            final resultTiles = results.map((data) {
                              final title = data['title']?.toString() ?? 'Sin titulo';
                              final imageUrl = data['imageUrl']?.toString();
                              final post = PostModel.fromMap(data);

                              return ListTile(
                                key: ValueKey('suggestion:${post.id}:${post.imageUrl}'),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: ClipRRect(
                                  key: ValueKey('suggestion-image:${post.id}:${post.imageUrl}'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(
                                            key: ValueKey('suggestion-network:${post.id}:${post.imageUrl}'),
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

                            return [
                              ...resultTiles,
                              ListTile(
                                leading: const Icon(Icons.manage_search),
                                title: Text(
                                  controller.text.trim().isEmpty
                                      ? 'Ver todos los materiales'
                                      : 'Ver todos los resultados para "${controller.text.trim()}"',
                                ),
                                onTap: () {
                                  final query = controller.text.trim();
                                  controller.closeView(query);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultsScreen(
                                        initialQuery: query,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ];
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
              spacing: isMobile ? 24 : 56,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: [
                _buildCategoryCard(
                  title: 'Libros',
                  imagePath: 'assets/images/libros.png',
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                  onTap: () => _openCategoryResults(context, 'Libro'),
                ),
                _buildCategoryCard(
                  title: 'Guias',
                  imagePath: 'assets/images/guias.png',
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                  onTap: () => _openCategoryResults(context, 'Guía'),
                ),
                _buildCategoryCard(
                  title: 'Materiales',
                  imagePath: 'assets/images/materiales.png',
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                  onTap: () => _openCategoryResults(context, 'Material'),
                ),
                _buildCategoryCard(
                  title: 'Otros',
                  imagePath: 'assets/images/otros.png',
                  isMobile: isMobile,
                  screenWidth: screenWidth,
                  onTap: () => _openCategoryResults(context, 'Otro'),
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

  void _openCategoryResults(BuildContext context, String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(initialQuery: query),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String imagePath,
    required bool isMobile,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                width: isMobile ? screenWidth - 60 : 240,
                height: isMobile ? 180 : 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: isMobile ? screenWidth - 60 : 240,
                    height: isMobile ? 180 : 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D4DA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5E5963),
                      ),
                    ),
                  );
                },
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
        ),
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
