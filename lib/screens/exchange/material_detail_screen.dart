import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
// Agrega esta importación en la parte superior
import 'package:metroswap/screens/publish/publish_screen.dart';

/// Muestra el detalle completo de una publicación disponible.
class MaterialDetailScreen extends StatelessWidget {
  final PostModel? post;

  const MaterialDetailScreen({super.key, this.post});

  @override
  Widget build(BuildContext context) {
    final currentPost = post;
    final title = currentPost?.title ?? 'Publicacion no disponible';
    final ownerName = currentPost?.ownerName ?? 'Usuario';
    final ownerUid = currentPost?.ownerUid ?? '';
    final knowledgeArea = currentPost?.knowledgeArea ?? 'Sin categoria';
    final method = currentPost?.method ?? 'Sin metodo';
    final description = currentPost?.description ?? 'Sin descripcion disponible.';
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

    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const MetroSwapNavbar(
                      developmentNav: true,
                      heading: 'Material',
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 1100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
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
                                    fit: BoxFit.cover,
                                    webHtmlElementStrategy: kIsWeb
                                        ? WebHtmlElementStrategy.prefer
                                        : WebHtmlElementStrategy.never,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImageFallback();
                                    },
                                  )
                                : _buildImageFallback(),
                          ),
                          const SizedBox(width: 50),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                GestureDetector(
                                  onTap: ownerUid.isEmpty
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfileScreen(uid: ownerUid),
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[700],
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  children: [
                                    _buildInfoBadge('Categoria', knowledgeArea),
                                    const SizedBox(width: 30),
                                    _buildInfoBadge('Metodo', method),
                                    if (subject.isNotEmpty) ...[
                                      const SizedBox(width: 30),
                                      _buildInfoBadge('Materia', subject),
                                    ],
                                  ],
                                ),
                                if (career.isNotEmpty ||
                                    condition.isNotEmpty ||
                                    priceUsd != null) ...[
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 12,
                                    children: [
                                      if (career.isNotEmpty)
                                        _buildMetaChip('Carrera', career),
                                      if (condition.isNotEmpty)
                                        _buildMetaChip('Estado', condition),
                                      _buildMetaChip(
                                          'Cantidad', quantity.toString()),
                                      if (isOutOfStock)
                                        _buildMetaChip(
                                          'Disponibilidad',
                                          PostModel.lifecycleOutOfStock,
                                          backgroundColor: const Color(0xFFFCE8E6),
                                          textColor: const Color(0xFFB3261E),
                                          borderColor: const Color(0xFFF1B5AF),
                                        ),
                                      if (priceUsd != null)
                                        _buildMetaChip(
                                          'Precio',
                                          '\$${priceUsd.toStringAsFixed(2)}',
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 30),
                                const Text(
                                  'Descripcion',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
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
                                    description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: (FirebaseAuth.instance.currentUser?.uid ==
                                          ownerUid)
                                      ? OutlinedButton.icon(
                                          // --- BOTÓN PARA EL DUEÑO DE LA PUBLICACIÓN ---
                                          icon: const Icon(Icons.edit, size: 28),
                                          label: const Text(
                                            'Editar publicación',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFFF6B00),
                                            side: const BorderSide(
                                              color: Color(0xFFFF6B00),
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PublishScreen(
                                                  postToEdit: currentPost, // Le pasamos el objeto post completo
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : ElevatedButton(
                                          // --- BOTÓN ORIGINAL PARA COMPRAR/INTERCAMBIAR ---
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isOutOfStock
                                                ? const Color(0xFF9A969F)
                                                : const Color(0xFFFF6B00),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                          ),
                                          onPressed: isOutOfStock
                                              ? null
                                              : () {
                                                  _handleActionPressed(
                                                    context,
                                                    currentPost,
                                                    quantity,
                                                    hasPrice,
                                                  );
                                                },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.handshake_outlined,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                isOutOfStock
                                                    ? PostModel
                                                        .lifecycleOutOfStock
                                                    : hasPrice
                                                        ? 'Comprar'
                                                        : 'Intercambiar',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
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
                    const Spacer(),
                    const SizedBox(height: 24),
                    const MetroSwapFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Valida la operación antes de iniciar el intercambio.
  void _handleActionPressed(
    BuildContext context,
    PostModel? currentPost,
    int maxQuantity,
    bool hasPrice,
  ) {
    if (currentPost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la publicación.')),
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

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar esta acción.'),
        ),
      );
      return;
    }

    // Doble verificación de seguridad (aunque ya no se debería ver el botón).
    if (currentUser.uid == currentPost.ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes interactuar con tu propia publicación.'),
        ),
      );
      return;
    }

    // Muestra un diálogo cuando hay más de un artículo disponible.
    if (maxQuantity > 1) {
      _showQuantityDialog(context, maxQuantity, (selectedQty) {
        _executeTrade(context, currentPost, currentUser, hasPrice, selectedQty);
      });
    } else {
      // Continúa directamente cuando solo hay una unidad disponible.
      _executeTrade(context, currentPost, currentUser, hasPrice, 1);
    }
  }

  // Muestra el diálogo para seleccionar la cantidad.
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
                    Navigator.pop(dialogContext); // Cierra el diálogo.
                    onConfirm(selectedQuantity); // Confirma la cantidad elegida.
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

  // Registra el intercambio en Firestore y abre el chat asociado.
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
        'requestedQuantity': selectedQuantity, // Guarda la cantidad solicitada.
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

  Widget _buildInfoBadge(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: textColor,
            fontSize: 14,
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