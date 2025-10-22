// lib/src/features/admin/presentation/screens/users_management_screen.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/admin/admin_service.dart';
import 'package:ping_go/src/widgets/snackbars/custom_snackbar.dart';

class UsersManagementScreen extends StatefulWidget {
  final int adminId;
  final Map<String, dynamic> adminUser;

  const UsersManagementScreen({
    super.key,
    required this.adminId,
    required this.adminUser,
  });

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _selectedFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final response = await AdminService.getUsers(
        adminId: widget.adminId,
        tipoUsuario: _selectedFilter,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _users = response['data']['usuarios'] ?? [];
          _isLoading = false;
        });
      } else {
        CustomSnackbar.showError(context, message: 'Error al cargar usuarios');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      CustomSnackbar.showError(context, message: 'Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Gestión de Usuarios', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFFF00)),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, email o teléfono',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFFFF00)),
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  onChanged: (_) => _loadUsers(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Clientes', 'cliente'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Conductores', 'conductor'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admins', 'administrador'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFFF00)),
                  )
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron usuarios',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFFFFF00),
                        backgroundColor: Colors.black,
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return _buildUserCard(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = value);
        _loadUsers();
      },
      backgroundColor: Colors.black,
      selectedColor: const Color(0xFFFFFF00).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFFFF00) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFFFFF00) : Colors.white30,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['es_activo'] == 1;
    final tipoUsuario = user['tipo_usuario'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getUserTypeColor(tipoUsuario).withOpacity(0.2),
          child: Text(
            (user['nombre']?[0] ?? '?').toUpperCase(),
            style: TextStyle(
              color: _getUserTypeColor(tipoUsuario),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${user['nombre']} ${user['apellido']}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user['email'] ?? '',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(tipoUsuario).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tipoUsuario,
                    style: TextStyle(
                      color: _getUserTypeColor(tipoUsuario),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF1A1A1A),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFFFFFF00), size: 20),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    color: isActive ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'Desactivar' : 'Activar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleUserAction(value, user),
        ),
      ),
    );
  }

  Color _getUserTypeColor(String tipo) {
    switch (tipo) {
      case 'administrador':
        return Colors.red;
      case 'conductor':
        return Colors.blue;
      case 'cliente':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(dynamic action, Map<String, dynamic> user) async {
    final userId = int.tryParse(user['id']?.toString() ?? '0') ?? 0;

    if (action == 'edit') {
      CustomSnackbar.showInfo(context, message: 'Función de edición en desarrollo');
    } else if (action == 'deactivate' || action == 'activate') {
      final newState = action == 'activate';
      final response = await AdminService.updateUser(
        adminId: widget.adminId,
        userId: userId,
        esActivo: newState,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          context,
          message: newState ? 'Usuario activado' : 'Usuario desactivado',
        );
        _loadUsers();
      } else {
        CustomSnackbar.showError(context, message: 'Error al actualizar usuario');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
