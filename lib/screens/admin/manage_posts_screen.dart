import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/utils/admin_utils.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> {
  bool _isAuthorizing = true;
  bool _isAuthorized = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _authorizeAndFetch();
  }

  Future<void> _authorizeAndFetch() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final isAuthorized = isAdminEmail(email);

    if (!mounted) return;
    setState(() {
      _isAuthorized = isAuthorized;
      _isAuthorizing = false;
    });

    if (!isAuthorized) return;
    await _fetchPosts();
  }

  // Obtiene las publicaciones desde Firestore.
  Future<void> _fetchPosts() async {
    try {
      final postsSnap = await FirebaseFirestore.instance.collection('posts').get();
      final List<Map<String, dynamic>> loadedPosts = [];

      for (var doc in postsSnap.docs) {
        final data = doc.data();
        
        // Formatea la fecha de creación.
        String dateStr = 'Sin fecha';
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            DateTime dt = (data['createdAt'] as Timestamp).toDate();
            dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          } else {
            dateStr = data['createdAt'].toString();
          }
        }

        // Normaliza el estado para mostrarlo en español.
        String rawStatus = data['status'] ?? 'Activo';
        if (rawStatus.toLowerCase() == 'active') {
          rawStatus = 'Activo';
        }

        loadedPosts.add({
          'id': doc.id,
          'title': data['title'] ?? data['productName'] ?? 'Publicación sin título',
          'author': data['authorEmail'] ?? data['email'] ?? 'Autor desconocido',
          'date': dateStr,
          'status': rawStatus,
        });
      }

      if (mounted) {
        setState(() {
          _posts = loadedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo publicaciones: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Elimina una publicación después de confirmar la acción.
  Future<void> _deletePost(String postId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('ELIMINAR PUBLICACIÓN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente la publicación "$title"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        
        setState(() {
          _posts.removeWhere((p) => p['id'] == postId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación eliminada exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error eliminando publicación: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la publicación.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E9EB),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: false, heading: 'Gestionar Publicaciones'),
          
          Expanded(
            child: _isAuthorizing
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
                : !_isAuthorized
                    ? _buildUnauthorizedState()
                    : _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(30.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Publicaciones Activas e Históricas',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Volver al Dashboard'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFC93C20),
                                  side: const BorderSide(color: Color(0xFFC93C20)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          SizedBox(
                            width: double.infinity,
                            child: _posts.isEmpty 
                              ? const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Center(
                                    child: Text(
                                      'Aún no hay publicaciones en la base de datos.',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                )
                              : DataTable(
                                  headingRowColor: WidgetStateProperty.resolveWith(
                                    (states) => Colors.grey.withValues(alpha: 0.1),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Título / Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Autor (Correo)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _posts.map((post) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(post['title'])),
                                        DataCell(Text(post['author'])),
                                        DataCell(Text(post['date'])),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              // Usa el mismo color para cada estado.
                                              color: post['status'] == 'Activo' 
                                                  ? Colors.green.withValues(alpha: 0.1) 
                                                  : Colors.orange.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              post['status'],
                                              style: TextStyle(
                                                // Usa el mismo color para cada estado.
                                                color: post['status'] == 'Activo' ? Colors.green[700] : Colors.orange[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            tooltip: 'Eliminar publicación',
                                            onPressed: () => _deletePost(post['id'], post['title']),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          const MetroSwapFooter(),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 52, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No tienes permisos de administrador para gestionar publicaciones.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
