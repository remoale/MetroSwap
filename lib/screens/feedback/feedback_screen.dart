import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/exchange_model.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class FeedbackScreen extends StatefulWidget {
  final String tradeId;
  final String postTitle;
  final bool isRequesterReview;

  const FeedbackScreen({
    super.key,
    required this.tradeId,
    required this.postTitle,
    this.isRequesterReview = false,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _rating = 0; 
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _finishExchange() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una calificación (1 a 5 estrellas).'),
          backgroundColor: Colors.red.shade700, 
        ),
      );
      return;
    }

    if (_sending) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final exchangeRef = _firestore.collection('exchanges').doc(widget.tradeId);
      final exchangeSnapshot = await exchangeRef.get();
      if (!exchangeSnapshot.exists) {
        throw StateError('El intercambio no existe.');
      }
      final exchange = ExchangeModel.fromDoc(exchangeSnapshot);

      final ownerUid = exchange.ownerUid.trim().isNotEmpty
          ? exchange.ownerUid.trim()
          : exchange.targetUid.trim();
      final requesterUid = exchange.requesterUid.trim();
      final exchangeData = exchangeSnapshot.data() ?? <String, dynamic>{};
      final comment = _commentController.text.trim();

      final batch = _firestore.batch();

      if (widget.isRequesterReview) {
        if (requesterUid != currentUser.uid) {
          throw StateError('Solo el solicitante puede calificar al propietario.');
        }
        if (exchange.status != ExchangeModel.statusCompleted) {
          throw StateError('Solo puedes calificar al propietario cuando el intercambio esté completado.');
        }
        if (ownerUid.isEmpty) {
          throw StateError('No se pudo identificar al propietario.');
        }
        if (exchange.requesterFeedbackSubmitted) {
          throw StateError('Ya enviaste tu feedback para este intercambio.');
        }

        final ratingRef = _firestore
            .collection('user_ratings')
            .doc(ownerUid)
            .collection('entries')
            .doc('${widget.tradeId}_requester');

        batch.set(ratingRef, {
          'tradeId': widget.tradeId,
          'fromUid': currentUser.uid,
          'toUid': ownerUid,
          'postTitle': exchange.postTitle,
          'rating': _rating,
          'comment': comment.isEmpty ? null : comment,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        batch.update(exchangeRef, {
          'requesterFeedbackSubmitted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (ownerUid != currentUser.uid) {
          throw StateError('Solo el dueño del post puede calificar y finalizar.');
        }
        if (exchange.status != ExchangeModel.statusAccepted) {
          throw StateError('Solo puedes finalizar un intercambio aceptado.');
        }
        if (requesterUid.isEmpty) {
          throw StateError('No se pudo identificar al usuario calificado.');
        }
        if (exchange.ownerFeedbackSubmitted) {
          throw StateError('Ya enviaste tu feedback para este intercambio.');
        }

        final requestedQuantity =
            int.tryParse(exchangeData['requestedQuantity']?.toString() ?? '') ?? 1;
        final postId = exchange.postId.trim();
        if (postId.isEmpty) {
          throw StateError('No se pudo identificar la publicación del intercambio.');
        }

        final postRef = _firestore.collection('posts').doc(postId);
        final postSnapshot = await postRef.get();
        if (!postSnapshot.exists) {
          throw StateError('La publicación asociada ya no existe.');
        }

        final postData = postSnapshot.data() ?? <String, dynamic>{};
        final currentQuantity =
            int.tryParse(postData['quantity']?.toString() ?? '') ?? 1;
        final remainingQuantity = currentQuantity - requestedQuantity;
        final safeQuantity = remainingQuantity < 0 ? 0 : remainingQuantity;

        final ratingRef = _firestore
            .collection('user_ratings')
            .doc(requesterUid)
            .collection('entries')
            .doc(widget.tradeId);

        batch.set(ratingRef, {
          'tradeId': widget.tradeId,
          'fromUid': currentUser.uid,
          'toUid': requesterUid,
          'postTitle': exchange.postTitle,
          'rating': _rating,
          'comment': comment.isEmpty ? null : comment,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        batch.update(exchangeRef, {
          'status': ExchangeModel.statusCompleted,
          'ownerFeedbackSubmitted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {
          'quantity': safeQuantity,
          'lifecycleStatus': safeQuantity == 0
              ? PostModel.lifecycleOutOfStock
              : PostModel.lifecyclePublished,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isRequesterReview
                ? 'Feedback enviado al propietario.'
                : 'Intercambio completado y feedback enviado.',
          ),
          backgroundColor: Colors.green, 
        )
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar el intercambio: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.postTitle.trim().isEmpty ? 'Intercambio' : widget.postTitle.trim();
    final screenTitle = widget.isRequesterReview
        ? 'Calificar propietario'
        : 'Finalizar intercambio';

    return Scaffold(
      backgroundColor: const Color(0xFFE6E3E8),
      body: SafeArea(
        child: Column(
          children: [
            const MetroSwapNavbar(
              developmentNav: true,
              heading: 'Feedback',
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD5D1D9)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          screenTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF605A66),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Calificación (Obligatorio)', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              onPressed: () => setState(() => _rating = star),
                              icon: Icon(
                                star <= _rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFFFB300),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Comentario (Opcional)',
                            hintText: 'Cuéntanos cómo fue el intercambio',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _sending ? null : _finishExchange,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A4C),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _sending
                                  ? 'Enviando...'
                                  : widget.isRequesterReview
                                      ? 'Enviar feedback'
                                      : 'Enviar feedback y terminar',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
