import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/screens/publish/edit_post_screen.dart';

/// Muestra el detalle completo de una publicación disponible.
class MaterialDetailScreen extends StatefulWidget {
  final PostModel? post;

  const MaterialDetailScreen({super.key, this.post});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  // Estado local para mantener y actualizar la publicación
  PostModel? _currentPost;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post; // Inicializamos con la data que llega
  }

  // Función clave: vuelve a pedir el post a Firebase y actualiza la vista
  Future<void> _cargarDatosActualizadosDeFirebase() async {
    if (_currentPost?.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // NOTA: Asegúrate de que tu colección se llame 'posts' o cambia el nombre aquí
      final docSnapshot = await FirebaseFirestore.instance
          .collection('posts') 
          .doc(_currentPost!.id)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          // NOTA: Adapta esto al método que uses en tu PostModel (fromMap, fromJson, fromFirestore, etc.)
          _currentPost = PostModel.fromMap(docSnapshot.data()!); 
          // Si tu modelo requiere el ID aparte: PostModel.fromMap(docSnapshot.data()!, docSnapshot.id);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error actualizando el post: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.of(context).size.width;
    final currentPost = _currentPost; // Usamos el estado local

    // Obtenemos el usuario actual y verificamos si es el dueño
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserUid != null && currentPost?.ownerUid == currentUserUid;

    final title = currentPost?.title ?? 'Publicación no disponible';
    final ownerName = currentPost?.ownerName ?? 'Usuario';
    final ownerUid = currentPost?.ownerUid ?? '';
    final knowledgeArea = currentPost?.knowledgeArea ?? 'Sin categoría';
    final method = currentPost?.method ?? 'Sin método';
    final description = currentPost?.description ?? 'Sin descripción disponible.';
    final imageUrl = currentPost?.imageUrl ?? '';
    final subject = currentPost?.subject ?? '';
    final condition = currentPost?.condition ?? '';
    final career = currentPost?.career ?? '';
    final quantity = currentPost?.quantity ?? 1;
    final priceUsd = currentPost?.priceUsd;
    final hasPrice = priceUsd != null;

    final isOutOfStock = currentPost == null ||
        quantity <= 0 ||
        currentPost.status == PostModel.statusInactive ||
        currentPost.lifecycleStatus == PostModel.lifecycleOutOfStock;
    final isMobile = viewportWidth < 760;

    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth > 1100
              ? 1100.0
              : constraints.maxWidth;
          final imageMaxWidth = isMobile
              ? (contentWidth - 48).clamp(220.0, 360.0).toDouble()
              : 380.0;

          return CustomScrollView(
            slivers: [
              // 1. Todo el contenido principal va en su propio Sliver independiente
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const MetroSwapNavbar(
                      developmentNav: true,
                      heading: 'Material',
                    ),
                    SizedBox(height: isMobile ? 24 : 60),
                    SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 0,
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImageCard(
                                    imageUrl: imageUrl,
                                    imageMaxWidth: imageMaxWidth,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDetailsContent(
                                    context,
                                    title: title,
                                    materialId: currentPost?.id ?? '',
                                    ownerName: ownerName,
                                    ownerUid: ownerUid,
                                    knowledgeArea: knowledgeArea,
                                    method: method,
                                    subject: subject,
                                    career: career,
                                    condition: condition,
                                    quantity: quantity,
                                    priceUsd: priceUsd,
                                    description: description,
                                    isOutOfStock: isOutOfStock,
                                    hasPrice: hasPrice,
                                    currentPost: currentPost,
                                    isOwner: isOwner,
                                    compact: true,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImageCard(
                                    imageUrl: imageUrl,
                                    imageMaxWidth: imageMaxWidth,
                                  ),
                                  const SizedBox(width: 50),
                                  Expanded(
                                    child: _buildDetailsContent(
                                      context,
                                      title: title,
                                      materialId: currentPost?.id ?? '',
                                      ownerName: ownerName,
                                      ownerUid: ownerUid,
                                      knowledgeArea: knowledgeArea,
                                      method: method,
                                      subject: subject,
                                      career: career,
                                      condition: condition,
                                      quantity: quantity,
                                      priceUsd: priceUsd,
                                      description: description,
                                      isOutOfStock: isOutOfStock,
                                      hasPrice: hasPrice,
                                      currentPost: currentPost,
                                      isOwner: isOwner,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      SizedBox(height: 24),
                      MetroSwapFooter(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageCard({
    required String imageUrl,
    required double imageMaxWidth,
    bool compact = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: imageMaxWidth,
        maxHeight: compact ? 520 : 620,
      ),
      child: Container(
        width: imageMaxWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                webHtmlElementStrategy: kIsWeb
                    ? WebHtmlElementStrategy.prefer
                    : WebHtmlElementStrategy.never,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImageFallback();
                },
              )
            : _buildImageFallback(),
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context, {
    required String title,
    required String materialId,
    required String ownerName,
    required String ownerUid,
    required String knowledgeArea,
    required String method,
    required String subject,
    required String career,
    required String condition,
    required int quantity,
    required double? priceUsd,
    required String description,
    required bool isOutOfStock,
    required bool hasPrice,
    required PostModel? currentPost,
    required bool isOwner,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        if (materialId.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'ID: $materialId',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        SizedBox(height: compact ? 12 : 15),
        GestureDetector(
          onTap: ownerUid.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(uid: ownerUid),
                    ),
                  );
                },
          child: MouseRegion(
            cursor: ownerUid.isEmpty
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: Row(
              children: [
                _OwnerAvatar(ownerUid: ownerUid),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    ownerName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 20 : 25),
        Wrap(
          spacing: compact ? 12 : 30,
          runSpacing: 14,
          children: [
            _buildInfoBadge('Categoría', knowledgeArea, compact: compact),
            _buildInfoBadge('Método', method, compact: compact),
            if (subject.isNotEmpty)
              _buildInfoBadge('Materia', subject, compact: compact),
          ],
        ),
        if (career.isNotEmpty || condition.isNotEmpty || priceUsd != null) ...[
          SizedBox(height: compact ? 18 : 20),
          Wrap(
            spacing: compact ? 10 : 16,
            runSpacing: 12,
            children: [
              if (career.isNotEmpty)
                _buildMetaChip('Carrera', career, compact: compact),
              if (condition.isNotEmpty)
                _buildMetaChip('Estado', condition, compact: compact),
              _buildMetaChip('Cantidad', quantity.toString(), compact: compact),
              if (isOutOfStock)
                _buildMetaChip(
                  'Disponibilidad',
                  PostModel.lifecycleOutOfStock,
                  backgroundColor: const Color(0xFFFCE8E6),
                  textColor: const Color(0xFFB3261E),
                  borderColor: const Color(0xFFF1B5AF),
                  compact: compact,
                ),
              if (priceUsd != null)
                _buildMetaChip(
                  'Precio',
                  '\$${priceUsd.toStringAsFixed(2)}',
                  compact: compact,
                ),
            ],
          ),
        ],
        SizedBox(height: compact ? 24 : 30),
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: compact ? 17 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            description,
            style: TextStyle(
              fontSize: compact ? 15 : 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: compact ? 28 : 40),
        SizedBox(
          width: double.infinity,
          height: compact ? 54 : 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isOwner
                  ? const Color(0xFF2196F3) // Azul para indicar que puede editar
                  : (isOutOfStock ? const Color(0xFF9A969F) : const Color(0xFFFF6B00)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            onPressed: (!isOwner && isOutOfStock)
                ? null
                : () {
                    _handleActionPressed(
                      context,
                      currentPost,
                      quantity,
                      hasPrice,
                      isOwner,
                    );
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOwner ? Icons.edit : Icons.handshake_outlined,
                  color: Colors.white,
                  size: compact ? 24 : 28,
                ),
                SizedBox(width: compact ? 8 : 10),
                Flexible(
                  child: Text(
                    isOwner
                        ? 'Editar publicación'
                        : (isOutOfStock
                            ? PostModel.lifecycleOutOfStock
                            : hasPrice
                                ? 'Comprar'
                                : 'Intercambiar'),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // AQUÍ ESTÁ EL CAMBIO CLAVE EN LA NAVEGACIÓN
  void _handleActionPressed(
    BuildContext context,
    PostModel? currentPost,
    int maxQuantity,
    bool hasPrice,
    bool isOwner,
  ) async {
    if (currentPost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la publicación.')),
      );
      return;
    }

    // Lógica si el usuario es el dueño de la publicación
    if (isOwner) {
      // 1. Esperamos (await) el resultado de la pantalla de edición
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPostScreen(post: currentPost),
        ),
      );

      // 2. Si el resultado es true, llamamos a recargar los datos
      if (resultado == true) {
        _cargarDatosActualizadosDeFirebase();
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar esta acción.'),
        ),
      );
      return;
    }

    final isOutOfStock = maxQuantity <= 0 ||
        currentPost.status == PostModel.statusInactive ||
        currentPost.lifecycleStatus == PostModel.lifecycleOutOfStock;
        
    if (isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este material está agotado.')),
      );
      return;
    }

    if (maxQuantity > 1) {
      _showQuantityDialog(context, maxQuantity, (selectedQty) {
        _executeTrade(context, currentPost, currentUser, hasPrice, selectedQty);
      });
    } else {
      _executeTrade(context, currentPost, currentUser, hasPrice, 1);
    }
  }

  void _showQuantityDialog(
    BuildContext context,
    int maxQuantity,
    Function(int) onConfirm,
  ) {
    int selectedQuantity = 1;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                '¿Qué cantidad deseas?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Disponible: $maxQuantity',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
                        color: const Color(0xFFFF6B00),
                        onPressed: selectedQuantity > 1
                            ? () => setState(() => selectedQuantity--)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$selectedQuantity',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        color: const Color(0xFFFF6B00),
                        onPressed: selectedQuantity < maxQuantity
                            ? () => setState(() => selectedQuantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onConfirm(selectedQuantity);
                  },
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeTrade(
    BuildContext context,
    PostModel currentPost,
    User currentUser,
    bool autoAccept,
    int selectedQuantity,
  ) async {
    final postId = currentPost.id.trim();
    if (postId.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    String tradeId = '';

    try {
      final requesterSnapshot =
          await firestore.collection('users').doc(currentUser.uid).get();
      final requesterData = requesterSnapshot.data();
      final requesterName = (requesterData?['name'] ??
              requesterData?['displayName'] ??
              currentUser.displayName ??
              currentUser.email ??
              'Usuario')
          .toString()
          .trim();

      final exchangeRef = firestore.collection('exchanges').doc();
      tradeId = exchangeRef.id;

      await exchangeRef.set({
        'id': tradeId,
        'postId': postId,
        'postTitle': currentPost.title,
        'imageUrl': currentPost.imageUrl,
        'method': currentPost.method,
        'ownerUid': currentPost.ownerUid,
        'ownerName': currentPost.ownerName,
        'targetUid': currentPost.ownerUid,
        'requesterUid': currentUser.uid,
        'requesterName': requesterName.isEmpty ? 'Usuario' : requesterName,
        'requestedQuantity': selectedQuantity,
        'priceUsd': currentPost.priceUsd,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (autoAccept) {
        await exchangeRef.update({
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TradeChatScreen(tradeId: tradeId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la operación.')),
      );
    }
  }

  Widget _buildImageFallback() {
    return Center(
      child: Icon(
        Icons.menu_book,
        size: 150,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value, {bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: compact ? 13 : 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChip(
    String label,
    String value, {
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF333333),
    Color borderColor = const Color(0xFFD4CFD8),
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: textColor,
            fontSize: compact ? 13 : 14,
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

class _OwnerAvatar extends StatelessWidget {
  final String ownerUid;

  const _OwnerAvatar({required this.ownerUid});

  @override
  Widget build(BuildContext context) {
    if (ownerUid.isEmpty) {
      return const _OwnerAvatarFallback();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('users').doc(ownerUid).get(),
      builder: (context, snapshot) {
        final photoUrl = snapshot.data?.data()?['photoUrl']?.toString() ?? '';
        if (photoUrl.isEmpty) {
          return const _OwnerAvatarFallback();
        }

        return ClipOval(
          child: SizedBox(
            width: 32,
            height: 32,
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              webHtmlElementStrategy: kIsWeb
                  ? WebHtmlElementStrategy.prefer
                  : WebHtmlElementStrategy.never,
              errorBuilder: (context, error, stackTrace) {
                return const _OwnerAvatarFallback();
              },
            ),
          ),
        );
      },
    );
  }
}

class _OwnerAvatarFallback extends StatelessWidget {
  const _OwnerAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFF5A5860),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}