import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import 'edit_profile_screen.dart';
import '../../widgets/profile_avatar.dart'; 
import '../home_page.dart';

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
       return const Scaffold(
        body: Center(child: CircularProgressIndicator())
        );
      }

      if (user == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Mi Perfil")),
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

      return Scaffold(
        backgroundColor: const Color(0xFFEFECEF),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 760;
                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
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
                                      child: Text(
                                        user!.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Color(0xFF54515A),
                                          fontWeight: FontWeight.w400,
                                        ),
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
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFF2C2C2C),
                padding: const EdgeInsets.all(20),
                child: const Text(
                  "© 2026 MetroSwap - Universidad Metropolitana.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 85,
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Image.asset(
            "assets/images/logo_metroswap.png",
            height: 45,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "MetroSwap",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomePage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Inicio"),
          ),
        ],
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
          "Libros publicados:",
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
    return count > 0 ? "$count libro(s)" : "Sin publicaciones";
  }
}
