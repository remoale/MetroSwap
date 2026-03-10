import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/models/exchange_model.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class FeedbackScreen extends StatefulWidget {
  final String tradeId;
  final String postTitle;

  const FeedbackScreen({
    super.key,
    required this.tradeId,
    required this.postTitle,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _rating = 5;
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _finishExchange() async {
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

      if (ownerUid != currentUser.uid) {
        throw StateError('Solo el dueño del post puede calificar y finalizar.');
      }
      if (requesterUid.isEmpty) {
        throw StateError('No se pudo identificar al usuario calificado.');
      }

      final ratingRef = _firestore
          .collection('user_ratings')
          .doc(requesterUid)
          .collection('entries')
          .doc(widget.tradeId);

      final comment = _commentController.text.trim();

      final batch = _firestore.batch();
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intercambio completado y feedback enviado.')),
      );
      Navigator.pop(context);
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
                          'Finalizar intercambio',
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
                          'Calificación',
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
                            labelText: 'Comentario',
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
                              _sending ? 'Enviando...' : 'Enviar feedback y terminar',
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
