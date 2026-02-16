import 'package:flutter/material.dart';
import '../../services/firestore_service.dart'; 
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({required this.uid});

  @override 
  State<ProfileScreen> createState() => _ProfileScreenState(); 
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirestoreService();
  UserModel? user;

  @override 
  void initState() {
     super.initState(); 
     loadUser();
  }

  Future<void> loadUser() async {
    final data = await _firestore.getUser(widget.uid);
    setState(() => user = data);
  }

  @override 
  Widget build(BuildContext context) {
     if (user == null) return const Center(child: CircularProgressIndicator());

     return Scaffold(
      appBar: AppBar(title: const Text("Perfil"))
      body: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user!.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user!.photoUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(height: 20),
          Text(user!.name, style: const TextStyle(fontSize: 20)),
          Text(user!.email),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile', arguments: user); 
            }, 
            child: const Text("Editar Perfil"), 
          )
        ],
      ), 
    );
  }
}