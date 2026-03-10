import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/exchange/exchange.dart';
import 'package:metroswap/screens/profile/profile_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

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
                                              decoration: TextDecoration.underline,
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
                                      _buildMetaChip('Cantidad', quantity.toString()),
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
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B00),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: () async {
                                      if (currentPost == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo cargar la publicacion.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      if (currentUser == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Debes iniciar sesion para intercambiar.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (currentUser.uid == currentPost.ownerUid) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No puedes intercambiar tu propia publicacion.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final postId = currentPost.id.trim();
                                      if (postId.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo cargar la publicacion.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final firestore = FirebaseFirestore.instance;
                                      String tradeId = '';

                                      try {
                                        final requesterSnapshot = await firestore
                                            .collection('users')
                                            .doc(currentUser.uid)
                                            .get();
                                        final requesterData = requesterSnapshot.data();
                                        final requesterName = (requesterData?['name'] ??
                                                requesterData?['displayName'] ??
                                                currentUser.displayName ??
                                                currentUser.email ??
                                                'Usuario')
                                            .toString()
                                            .trim();

                                        final exchangeRef =
                                            firestore.collection('exchanges').doc();
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
                                          'requesterName': requesterName.isEmpty
                                              ? 'Usuario'
                                              : requesterName,
                                          'status': 'requested',
                                          'createdAt': FieldValue.serverTimestamp(),
                                          'updatedAt': FieldValue.serverTimestamp(),
                                        });
                                      } on FirebaseException catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.message ??
                                                  'No se pudo iniciar el intercambio.',
                                            ),
                                          ),
                                        );
                                        return;
                                      } catch (_) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo iniciar el intercambio.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TradeChatScreen(
                                            tradeId: tradeId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.handshake_outlined,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Intercambiar',
                                          style: TextStyle(
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

  Widget _buildMetaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4CFD8)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF333333),
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
      future: FirebaseFirestore.instance.collection('users').doc(ownerUid).get(),
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
