import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/widgets/metroswap_brand.dart';
import 'package:metroswap/screens/profile/profile_screen.dart'; 
import 'package:metroswap/screens/publish/publish_screen.dart';
import 'package:metroswap/screens/about/about_screen.dart';
import 'package:metroswap/screens/landing_screen.dart';
import 'package:metroswap/screens/home_screen.dart';
import 'package:metroswap/screens/notifications/notifications_screen.dart';

class MetroSwapDrawer extends StatelessWidget {
  const MetroSwapDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2C2C),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        children: [
          const MetroSwapBrand(),
          const SizedBox(height: 40),
          
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Inicio', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text('Publicar', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublishScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('Conócenos', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.white),
            title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),

          const Divider(color: Colors.white54, height: 40),
          
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              Navigator.pop(context); 
              if (user != null){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(uid: user.uid)),
                );
              }
            },
          ),

          const Divider(color: Colors.white54, height: 40),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF5C00)),
            title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFFF5C00), fontSize: 18)),
            onTap: () async {
              Navigator.pop(context); 
              
              await FirebaseAuth.instance.signOut();
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandingScreen(), 
                  ),
                  (Route<dynamic> route) => false, 
                );
              }
            }
          ),
        ],
      ),
    );
  }
}
