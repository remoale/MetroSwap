import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_layout.dart'; 
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';

class UserReviewsScreen extends StatelessWidget {
  final String uid;
  final String userName;

  const UserReviewsScreen({
    super.key,
    required this.uid,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return MetroSwapLayout(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 700;

            return Column(
              children: [
                if (isDesktop)
                  MetroSwapNavbar(
                    developmentNav: true,
                    heading: 'Reseñas de $userName',
                    showLogoutButton: false,
                    showNotificationsButton: false,
                    showProfileButton: false,
                  ),
                
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: isDesktop ? 0 : 16.0, 
                              top: 16.0, 
                              bottom: 8.0,
                            ),
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios, size: 16),
                              label: const Text(
                                "Volver", 
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 51, 51, 50), 
                              ),
                            ),
                          ),

                          Expanded(
                            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('user_ratings')
                                  .doc(uid)
                                  .collection('entries')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (snapshot.hasError) {
                                  return const Center(
                                    child: Text(
                                      'Hubo un error al cargar las reseñas.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];

                                if (docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Este usuario aún no tiene reseñas.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF706C76),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 0 : 16, 
                                    vertical: 8,
                                  ),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data();
                                    final int rating = data['rating'] ?? 0;
                                    final String comment = data['comment'] ?? 'Sin comentario.';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF5A5860),
                                          width: 2,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(isDesktop ? 20 : 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                starIndex < rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: const Color(0xFFFF9800), 
                                                size: isDesktop ? 24 : 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            comment,
                                            style: TextStyle(
                                              color: const Color(0xFF6A6770),
                                              fontSize: isDesktop ? 18 : 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const MetroSwapFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}
