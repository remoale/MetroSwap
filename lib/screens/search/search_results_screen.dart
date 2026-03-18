import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/exchange/material_detail_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_layout.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
  });

  static Future<List<Map<String, dynamic>>> searchPosts(String rawTerm) async {
    final searchTerm = PostModel.normalizeSearchText(rawTerm);
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('status', isEqualTo: PostModel.statusActive)
        .limit(75)
        .get();

    final matches = snapshot.docs
        .map((doc) => doc.data())
        .where((data) {
          if (searchTerm.isEmpty) {
            return true;
          }
          final searchableText = buildSearchableText(data);
          return searchableText.contains(searchTerm);
        })
        .toList();

    matches.sort((a, b) {
      final aOutOfStock = _isOutOfStockMap(a);
      final bOutOfStock = _isOutOfStockMap(b);
      if (aOutOfStock != bOutOfStock) {
        return aOutOfStock ? 1 : -1;
      }
      return (a['title']?.toString() ?? '')
          .toLowerCase()
          .compareTo((b['title']?.toString() ?? '').toLowerCase());
    });

    return matches;
  }

  static String buildSearchableText(Map<String, dynamic> data) {
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

  static String buildSuggestionSubtitle(Map<String, dynamic> data) {
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

  static bool _isOutOfStockMap(Map<String, dynamic> data) {
    final quantity =
        int.tryParse(data['quantity']?.toString() ?? '') ?? 1;
    final status = data['status']?.toString() ?? PostModel.statusActive;
    final lifecycleStatus =
        data['lifecycleStatus']?.toString() ?? PostModel.lifecyclePublished;

    return quantity <= 0 ||
        status == PostModel.statusInactive ||
        lifecycleStatus == PostModel.lifecycleOutOfStock;
  }

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _searchController;
  late Future<List<Map<String, dynamic>>> _resultsFuture;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery.trim());
    _resultsFuture = SearchResultsScreen.searchPosts(_searchController.text);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _runSearch();
    });
  }

  void _runSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _resultsFuture = SearchResultsScreen.searchPosts(query);
    });
  }

  void _openPost(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialDetailScreen(post: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 760;

    return MetroSwapLayout(
      body: Container(
        color: const Color(0xFFE4E1E6),
        child: Column(
          children: [
            if (!isMobile)
              const MetroSwapNavbar(
                developmentNav: true,
                heading: 'Resultados',
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 28,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 28,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SearchResultsHeader(
                          controller: _searchController,
                          onSearch: _runSearch,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 22),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _resultsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 80),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF6B00),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return _SearchStateCard(
                                title: 'No se pudo completar la busqueda',
                                subtitle:
                                    snapshot.error?.toString() ?? 'Intenta nuevamente.',
                              );
                            }

                            final results = snapshot.data ?? const <Map<String, dynamic>>[];
                            final query = _searchController.text.trim();

                            if (results.isEmpty) {
                              return _SearchStateCard(
                                title: query.isEmpty
                                    ? 'No hay materiales disponibles'
                                    : 'Sin resultados para "$query"',
                                subtitle:
                                    query.isEmpty
                                        ? 'Cuando existan publicaciones activas apareceran aqui.'
                                        : 'Prueba otra palabra clave o revisa publicaciones activas.',
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    query.isEmpty
                                        ? '${results.length} materiales disponibles'
                                        : '${results.length} resultados para "$query"',
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                ),
                                ...results.map((data) {
                                  final post = PostModel.fromMap(data);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _SearchResultRow(
                                      post: post,
                                      isMobile: isMobile,
                                      onOpen: () => _openPost(post),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isMobile;

  const _SearchResultsHeader({
    required this.controller,
    required this.onSearch,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buscar material',
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora resultados en formato listado para comparar rapidamente.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF66616B),
            ),
          ),
          const SizedBox(height: 18),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchInput(controller: controller, onSubmitted: (_) => onSearch()),
                    const SizedBox(height: 12),
                    _SearchButton(onPressed: onSearch),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SearchInput(
                        controller: controller,
                        onSubmitted: (_) => onSearch(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SearchButton(onPressed: onSearch),
                  ],
                ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _SearchInput({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Buscar por titulo, material o materia...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF7F5F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4CFD8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4CFD8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.4),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SearchButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
        child: const Text(
          'Buscar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SearchStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SearchStateCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 42, color: Color(0xFF6B6770)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF66616B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  final PostModel post;
  final bool isMobile;
  final VoidCallback onOpen;

  const _SearchResultRow({
    required this.post,
    required this.isMobile,
    required this.onOpen,
  });

  bool get _isOutOfStock {
    return post.quantity <= 0 ||
        post.status == PostModel.statusInactive ||
        post.lifecycleStatus == PostModel.lifecycleOutOfStock;
  }

  @override
  Widget build(BuildContext context) {
    final priceLabel =
        post.priceUsd == null ? 'Intercambio' : '\$${post.priceUsd!.toStringAsFixed(2)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultImage(imageUrl: post.imageUrl, isMobile: true),
                    const SizedBox(height: 16),
                    _ResultContent(
                      post: post,
                      priceLabel: priceLabel,
                      isMobile: true,
                      isOutOfStock: _isOutOfStock,
                    ),
                    const SizedBox(height: 16),
                    _ResultAction(
                      isMobile: true,
                      isOutOfStock: _isOutOfStock,
                      onOpen: onOpen,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultImage(imageUrl: post.imageUrl, isMobile: false),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _ResultContent(
                        post: post,
                        priceLabel: priceLabel,
                        isMobile: false,
                        isOutOfStock: _isOutOfStock,
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 170,
                      child: _ResultAction(
                        isMobile: false,
                        isOutOfStock: _isOutOfStock,
                        onOpen: onOpen,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  final String imageUrl;
  final bool isMobile;

  const _ResultImage({
    required this.imageUrl,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final width = isMobile ? double.infinity : 180.0;
    final height = isMobile ? 220.0 : 180.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF3F1F4),
        child: imageUrl.trim().isEmpty
            ? const Icon(Icons.menu_book, size: 54, color: Color(0xFFB7B1BC))
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                webHtmlElementStrategy: kIsWeb
                    ? WebHtmlElementStrategy.prefer
                    : WebHtmlElementStrategy.never,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 54,
                    color: Color(0xFFB7B1BC),
                  );
                },
              ),
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  final PostModel post;
  final String priceLabel;
  final bool isMobile;
  final bool isOutOfStock;

  const _ResultContent({
    required this.post,
    required this.priceLabel,
    required this.isMobile,
    required this.isOutOfStock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ResultBadge(label: 'Categoria', value: post.knowledgeArea),
            _ResultBadge(label: 'Metodo', value: post.method),
            if (post.subject.trim().isNotEmpty)
              _ResultBadge(label: 'Materia', value: post.subject),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ResultChip(label: 'Precio', value: priceLabel),
            _ResultChip(label: 'Cantidad', value: post.quantity.toString()),
            if (post.career.trim().isNotEmpty)
              _ResultChip(label: 'Carrera', value: post.career),
            if (post.condition.trim().isNotEmpty)
              _ResultChip(label: 'Estado', value: post.condition),
            if (isOutOfStock)
              const _ResultChip(
                label: 'Disponibilidad',
                value: PostModel.lifecycleOutOfStock,
                textColor: Color(0xFFB3261E),
                backgroundColor: Color(0xFFFCE8E6),
                borderColor: Color(0xFFF1B5AF),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          post.description.trim().isEmpty
              ? 'Sin descripcion disponible.'
              : post.description,
          maxLines: isMobile ? 4 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            height: 1.45,
            color: const Color(0xFF5B5760),
          ),
        ),
      ],
    );
  }
}

class _ResultAction extends StatelessWidget {
  final bool isMobile;
  final bool isOutOfStock;
  final VoidCallback onOpen;

  const _ResultAction({
    required this.isMobile,
    required this.isOutOfStock,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
      children: [
        if (!isMobile) ...[
          Text(
            isOutOfStock ? 'Agotado' : 'Disponible',
            style: TextStyle(
              color: isOutOfStock
                  ? const Color(0xFFB3261E)
                  : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onOpen,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutOfStock
                  ? const Color(0xFF9A969F)
                  : const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isOutOfStock ? 'Ver detalle' : 'Ver material',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final String value;

  const _ResultBadge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF7A7580)),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _ResultChip({
    required this.label,
    required this.value,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF333333),
    this.borderColor = const Color(0xFFD4CFD8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: textColor,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
