import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import 'edit_profile_screen.dart';
import 'user_reviews_screen.dart';
import '../../widgets/profile_avatar.dart'; 
import '../../widgets/metroswap_navbar.dart';
import '../../widgets/metroswap_footer.dart';
import '../../widgets/metroswap_layout.dart'; 

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override 
  State<ProfileScreen> createState() => _ProfileScreenState(); 
}

class _ProfileScreenState extends State<ProfileScreen> {
  final controller = ProfileController();
  final storage = StorageService();
  UserModel? user;
  Uint8List? profileImageBytes;
  bool isLoading = true;

  @override 
  void initState() {
     super.initState(); 
     loadUser();
  }

  Future<void> loadUser() async {
    final data = await controller.loadUser(widget.uid);
    if (data != null) {
      final resolvedPhotoUrl = await storage.getProfileImageDownloadUrl(widget.uid) ??
          await storage.resolveImageUrl(data.photoUrl);
      data.photoUrl = resolvedPhotoUrl;
    }

    Uint8List? imageBytes;
    if (!kIsWeb) {
      imageBytes = await storage.getProfileImageBytes(widget.uid);
    }

    if (!kIsWeb && imageBytes == null) {
      debugPrint(
        '[ProfileScreen.loadUser] No image bytes for uid=${widget.uid}. '
        'Firestore photoUrl=${data?.photoUrl}',
      );
    }

    if (!mounted) return;
    setState(() {
      user = data;
      profileImageBytes = imageBytes;
      isLoading = false;
    });
  }

  @override 
  Widget build(BuildContext context) {
     if (isLoading) {
       return MetroSwapLayout( 
        body: const Center(child: CircularProgressIndicator())
        );
      }

      if (user == null) {
        return MetroSwapLayout( 
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("No se pudo cargar el perfil."),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => isLoading = true);
                    loadUser();
                  },
                  child: const Text("Reintentar"),
                ),
              ],
            ),
          ),
        );
      }

      return MetroSwapLayout(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 700;
              final isCompact = constraints.maxWidth < 760;

              return Column(
                children: [
                  if (isDesktop)
                    const MetroSwapNavbar(
                      developmentNav: true,
                      heading: 'Mi Perfil',
                      showLogoutButton: true,
                      showNotificationsButton: false,
                      showProfileButton: false,
                    ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isDesktop ? 0 : 24.0, 
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

                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 0 : 24, 
                                  vertical: 8, 
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ProfileAvatar(
                                          localImageBytes: profileImageBytes,
                                          imageUrl: (user!.photoUrl != null &&
                                                  user!.photoUrl!.trim().isNotEmpty)
                                              ? user!.photoUrl
                                              : FirebaseAuth
                                                  .instance.currentUser?.photoURL,
                                          size: 38,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user!.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  color: Color(0xFF54515A),
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.1, 
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              _buildRatingSummary(isCompact),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF5A5860),
                                          width: 3,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            "Información del usuario",
                                            style: TextStyle(
                                              color: Color(0xFF6A6770),
                                              fontSize: 26,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          isCompact
                                              ? Column(
                                                  children: [
                                                    _buildLeftInfo(),
                                                    const SizedBox(height: 18),
                                                    _buildRightInfo(),
                                                  ],
                                                )
                                              : Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: _buildLeftInfo(),
                                                    ),
                                                    const SizedBox(width: 30),
                                                    Expanded(
                                                      child: _buildRightInfo(),
                                                    ),
                                                  ],
                                                ),
                                          const SizedBox(height: 24),
                                          if (FirebaseAuth.instance.currentUser?.uid == widget.uid)
                                            SizedBox(
                                              width: 190,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  final updated =
                                                      await Navigator.push<bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProfileScreen(
                                                        user: user!,
                                                      ),
                                                    ),
                                                  );
                                                  if (updated == true) {
                                                    setState(
                                                      () => isLoading = true,
                                                    );
                                                    await loadUser();
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFFF5C00),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: const Text("Editar perfil"),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
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
              );
            },
          ),
        ),
      );
  }

  Widget _buildLeftInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoLabelValue(
          "Nombre completo:",
          user!.name,
        ),
        const SizedBox(height: 16),
        _buildInfoLabelValue(
          "Carrera:",
          _fallbackValue(user!.career, "No especificada"),
        ),
        const SizedBox(height: 16),
        _buildInfoLabelValue(
          "Carnet:",
          _buildStudentIdValue(user!.studentId, user!.uid),
        ),
      ],
    );
  }

  Widget _buildRightInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoLabelValue(
          "Correo Unimet:",
          user!.email,
        ),
        const SizedBox(height: 16),
        _buildInfoLabelValue(
          "Número de teléfono:",
          _fallbackValue(user!.phone, "No especificado"),
        ),
        const SizedBox(height: 16),
        _buildInfoLabelValue(
          "Materiales publicados:",
          _buildBooksValue(user!.books),
        ),
      ],
    );
  }

  Widget _buildInfoLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF595660),
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF706C76),
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  String _fallbackValue(String? value, String fallback) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    return normalized;
  }

  String _buildStudentIdValue(String? studentId, String uid) {
    final normalized = studentId?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    if (uid.length <= 8) {
      return uid.toUpperCase();
    }
    return uid.substring(0, 8).toUpperCase();
  }

  String _buildBooksValue(List<String>? books) {
    final count = books?.where((book) => book.trim().isNotEmpty).length ?? 0;
    return count > 0 ? "$count material(es)" : "Sin publicaciones";
  }

  Widget _buildRatingSummary(bool isCompact) {
    final ratingsStream = FirebaseFirestore.instance
        .collection('user_ratings')
        .doc(widget.uid)
        .collection('entries')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ratingsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final ratings = docs
            .map((doc) => doc.data()['rating'])
            .whereType<int>()
            .toList(growable: false);

        final count = ratings.length;
        final average = count == 0
            ? user!.reputation.toDouble()
            : ratings.reduce((a, b) => a + b) / count;
        final displayCount = count == 0 ? user!.tradesCount : count;

        return Row(
          children: [
            Text(
              average.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.star,
              color: Color.fromARGB(242, 241, 255, 52),
              size: 24,
            ),
            const SizedBox(width: 6),
            Text(
              '($displayCount)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserReviewsScreen(
                      uid: widget.uid,
                      userName: user!.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.comment_outlined, size: 18),
              label: Text(isCompact ? "Ver" : "Ver Reseñas"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5C00), 
                backgroundColor: const Color(0xFFFF5C00).withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
