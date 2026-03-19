import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metroswap/utils/admin_utils.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';

class ManageProfilesScreen extends StatefulWidget {
  final bool showOnlySuspended;

  const ManageProfilesScreen({super.key, this.showOnlySuspended = false});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  bool _isAuthorizing = true;
  bool _isAuthorized = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  
  late bool _showingSuspended;

  @override
  void initState() {
    super.initState();
    _showingSuspended = widget.showOnlySuspended; 
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
    await _fetchUsers();
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
        final String status = normalizeUserStatus(data['status']);

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
    final isActive = normalizeUserStatus(currentStatus) == 'Activo';
    final newStatus = isActive ? 'Suspendido' : 'Activo';
    
    // Actualiza también el estado de las publicaciones del usuario.
    final newPostStatus = isActive ? 'suspended' : 'active';
    
    final actionText = isActive ? 'suspender' : 'reactivar';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('${actionText.toUpperCase()} USUARIO', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas $actionText a este usuario?\n\n(Esto también cambiará el estado de todas sus publicaciones a "$newPostStatus").'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? const Color(0xFFC93C20) : Colors.green,
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
        // Agrupa las actualizaciones en un batch de Firestore.
        final batch = FirebaseFirestore.instance.batch();

        // Prepara la actualización del usuario.
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        batch.set(userRef, {'status': newStatus}, SetOptions(merge: true));

        // Busca las publicaciones del usuario por `ownerUid`.
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('ownerUid', isEqualTo: userId)
            .get();

        // Prepara la actualización de cada publicación encontrada.
        for (var doc in postsSnapshot.docs) {
          batch.update(doc.reference, {'status': newPostStatus});
        }

        // Ejecuta todas las actualizaciones pendientes.
        await batch.commit();

        // Refleja el nuevo estado en la interfaz.
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['status'] = newStatus;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario y sus ${postsSnapshot.docs.length} publicaciones actualizados.'),
              backgroundColor: newStatus == 'Activo' ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error actualizando estado: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el usuario y sus publicaciones.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = _showingSuspended 
        ? _users.where((user) => isSuspendedUserStatus(user['status'])).toList()
        : _users;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E9EB),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: false, heading: 'Gestionar Perfiles'),
          
          Expanded(
            child: _isAuthorizing
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
              : !_isAuthorized
                ? _buildUnauthorizedState()
                : _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC93C20)))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 25),
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
                        if (isMobile) ...[
                          Text(
                            _showingSuspended ? 'Usuarios Suspendidos' : 'Directorio de Miembros',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Volver al Dashboard'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2C2C2C),
                                side: const BorderSide(color: Color(0xFF2C2C2C)),
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _showingSuspended ? 'Usuarios Suspendidos' : 'Directorio de Miembros',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              
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
                        ],
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
                            child: isMobile
                                ? Column(
                                    children: displayedUsers
                                        .map((user) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: _buildUserCard(user),
                                            ))
                                        .toList(),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final availableWidth = constraints.maxWidth;
                                      final isCompact = availableWidth < 1200;
                                      final nameCellWidth = isCompact ? 190.0 : 240.0;
                                      final emailCellWidth = isCompact ? 240.0 : 320.0;
                                      final careerCellWidth = isCompact ? 170.0 : 220.0;
                                      const statusCellWidth = 110.0;
                                      const actionCellWidth = 80.0;
                                      const colSpacing = 14.0;
                                      const horizontalMargin = 8.0;
                                      final requiredWidth =
                                          nameCellWidth +
                                          emailCellWidth +
                                          careerCellWidth +
                                          statusCellWidth +
                                          actionCellWidth +
                                          (colSpacing * 4) +
                                          (horizontalMargin * 2);

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: requiredWidth > availableWidth
                                                ? requiredWidth
                                                : availableWidth,
                                          ),
                                          child: DataTable(
                                            columnSpacing: colSpacing,
                                            horizontalMargin: horizontalMargin,
                                            headingRowColor: WidgetStateProperty.resolveWith(
                                              (states) => Colors.grey.withValues(alpha: 0.1),
                                            ),
                                            columns: [
                                              const DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                                              const DataColumn(label: Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold))),
                                              const DataColumn(label: Text('Carrera', style: TextStyle(fontWeight: FontWeight.bold))),
                                              const DataColumn(
                                                label: SizedBox(
                                                  width: statusCellWidth,
                                                  child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const DataColumn(
                                                label: SizedBox(
                                                  width: actionCellWidth,
                                                  child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                            rows: displayedUsers.map((user) {
                                              final bool isActive = normalizeUserStatus(user['status']) == 'Activo';
                                              final String userName = (user['name'] ?? '').toString();
                                              final String userEmail = (user['email'] ?? '').toString();
                                              final String userCareer = (user['career'] ?? '').toString();
                                              final baseStyle = TextStyle(
                                                color: isActive ? Colors.black : Colors.grey,
                                              );

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
                                                            (user['name'] != null && user['name'].toString().trim().isNotEmpty)
                                                                ? user['name'].toString().trim().substring(0, 1).toUpperCase()
                                                                : 'U',
                                                            style: TextStyle(
                                                              color: isActive ? const Color(0xFFC93C20) : Colors.grey[700],
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        _buildClampedCellText(
                                                          userName,
                                                          width: nameCellWidth,
                                                          style: TextStyle(
                                                            decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                                            color: isActive ? Colors.black : Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    _buildClampedCellText(
                                                      userEmail,
                                                      width: emailCellWidth,
                                                      style: baseStyle,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    _buildClampedCellText(
                                                      userCareer,
                                                      width: careerCellWidth,
                                                      style: baseStyle,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      width: statusCellWidth,
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: _buildStatusChip(user['status'].toString()),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      width: actionCellWidth,
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: IconButton(
                                                          icon: Icon(isActive ? Icons.block : Icons.check_circle_outline),
                                                          color: isActive ? Colors.orange : Colors.green,
                                                          tooltip: isActive ? 'Suspender usuario' : 'Reactivar usuario',
                                                          onPressed: () => _toggleUserStatus(user['id'], user['status']),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
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
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = normalizeUserStatus(user['status']) == 'Activo';
    final userName = (user['name'] ?? 'Usuario MetroSwap').toString().trim();
    final userEmail = (user['email'] ?? 'Sin correo').toString().trim();
    final userCareer = (user['career'] ?? 'No especificada').toString().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? const Color(0xFFC93C20).withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
                child: Text(
                  userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                  style: TextStyle(
                    color: isActive ? const Color(0xFFC93C20) : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userName.isEmpty ? 'Usuario MetroSwap' : userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                    color: isActive ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMobileInfoLine('Correo', userEmail.isEmpty ? '-' : userEmail),
          const SizedBox(height: 6),
          _buildMobileInfoLine('Carrera', userCareer.isEmpty ? '-' : userCareer),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStatusChip(user['status'].toString()),
              OutlinedButton.icon(
                onPressed: () => _toggleUserStatus(user['id'], user['status']),
                icon: Icon(isActive ? Icons.block : Icons.check_circle_outline),
                label: Text(isActive ? 'Suspender' : 'Reactivar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isActive ? Colors.orange : Colors.green,
                  side: BorderSide(color: isActive ? Colors.orange : Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isActive = normalizeUserStatus(status) == 'Activo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        normalizeUserStatus(status),
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
            'No tienes permisos de administrador para gestionar perfiles.',
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

  Widget _buildClampedCellText(
    String value, {
    required TextStyle style,
    required double width,
  }) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return SizedBox(
      width: width,
      child: Tooltip(
        message: text,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: style,
        ),
      ),
    );
  }
}
