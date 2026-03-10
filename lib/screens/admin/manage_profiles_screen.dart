import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';

class ManageProfilesScreen extends StatefulWidget {
  final bool showOnlySuspended;

  const ManageProfilesScreen({super.key, this.showOnlySuspended = false});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  
  late bool _showingSuspended;

  @override
  void initState() {
    super.initState();
    _showingSuspended = widget.showOnlySuspended; 
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> loadedUsers = [];

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        
        String name = data['name'] ?? data['firstName'] ?? 'Usuario MetroSwap';
        String email = data['email'] ?? 'Sin correo';
        String career = data['career'] ?? 'No especificada';
        String status = data['status'] ?? 'Activo'; 

        loadedUsers.add({
          'id': doc.id,
          'name': name,
          'email': email,
          'career': career,
          'status': status,
        });
      }

      if (mounted) {
        setState(() {
          _users = loadedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo usuarios: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, String currentStatus) async {
    final newStatus = currentStatus == 'Activo' ? 'Suspendido' : 'Activo';
    final actionText = currentStatus == 'Activo' ? 'suspender' : 'reactivar';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('${actionText.toUpperCase()} USUARIO', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas $actionText a este usuario?\n\n(Esto afectará su capacidad para iniciar sesión o publicar en el futuro).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus == 'Activo' ? const Color(0xFFC93C20) : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, $actionText'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {'status': newStatus},
          SetOptions(merge: true), 
        );

        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['status'] = newStatus;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario $newStatus exitosamente.'),
              backgroundColor: newStatus == 'Activo' ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error actualizando estado: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el usuario.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = _showingSuspended 
        ? _users.where((user) => user['status'] == 'Suspendido').toList()
        : _users;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E9EB),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: false, heading: 'Gestionar Perfiles'),
          
          Expanded(
            child: _isLoading 
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
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _showingSuspended ? 'Usuarios Suspendidos' : 'Directorio de Miembros',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            // ELIMINAMOS EL BOTÓN DE "VER TODOS" QUE ESTABA AQUÍ
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Volver al Dashboard'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2C2C2C),
                                side: const BorderSide(color: Color(0xFF2C2C2C)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        if (displayedUsers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: Text(
                                'No se encontraron usuarios.',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.resolveWith(
                                (states) => Colors.grey.withValues(alpha: 0.1),
                              ),
                              columns: const [
                                DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Carrera', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: displayedUsers.map((user) {
                                final bool isActive = user['status'] == 'Activo';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isActive 
                                              ? const Color(0xFFC93C20).withValues(alpha: 0.2)
                                              : Colors.grey.withValues(alpha: 0.3),
                                            child: Text(
                                              user['name'].toString().substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: isActive ? const Color(0xFFC93C20) : Colors.grey[700], 
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            user['name'],
                                            style: TextStyle(
                                              decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              color: isActive ? Colors.black : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(user['email'], style: TextStyle(color: isActive ? Colors.black : Colors.grey))),
                                    DataCell(Text(user['career'], style: TextStyle(color: isActive ? Colors.black : Colors.grey))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          user['status'],
                                          style: TextStyle(
                                            color: isActive ? Colors.green[700] : Colors.red[700], 
                                            fontWeight: FontWeight.bold, fontSize: 12
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: Icon(isActive ? Icons.block : Icons.check_circle_outline),
                                        color: isActive ? Colors.orange : Colors.green,
                                        tooltip: isActive ? 'Suspender usuario' : 'Reactivar usuario',
                                        onPressed: () => _toggleUserStatus(user['id'], user['status']),
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
}