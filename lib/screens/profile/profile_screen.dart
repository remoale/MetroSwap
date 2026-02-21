import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart'; 
import '../../models/user_model.dart';
import '../../widgets/profile_avatar.dart'; 
import '../../widgets/profile_info_card.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override 
  State<ProfileScreen> createState() => _ProfileScreenState(); 
}

class _ProfileScreenState extends State<ProfileScreen> {
  final controller = ProfileController();
  UserModel? user;

  @override 
  void initState() {
     super.initState(); 
     loadUser();
  }

  Future<void> loadUser() async {
    final data = await controller.loadUser(widget.uid);
    setState(() => user = data);
  }

  @override 
  Widget build(BuildContext context) {
     if (user == null) {
       return const Scaffold(
        body: Center(child: CircularProgressIndicator())
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text("Mi Perfil")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProfileAvatar(imageUrl: user!.photoUrl, size: 70),
              const SizedBox(height: 20),
              Text(user!.name, style: const TextStyle(fontSize: 22)), 
              Text(user!.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ProfileInfoCard(
                title: "Editar Perfil",
                icon: Icons.edit,
                onTap: () {
                  Navigator.pushNamed(context, '/edit-profile', arguments: user); 
                },
              ),
              ProfileInfoCard(
                title: "Mis Libros",
                icon: Icons.book,
                onTap: () { 
                // Navegar a pantalla de libros
                },
              ),

              ProfileInfoCard(
                title: "Cerrar Sesión",
                icon: Icons.logout,
                onTap: () {
                  // Llamar a logout
                },
              ),

            ],
          ),
        ),
      );
  }
}   