import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pet_model.dart';
import '../pets/pet_detail_screen.dart';
import '../pets/add_pet_screen.dart';
import '../chat/chat_screen.dart';
import '../map/map_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;
  bool _isRefugio = false;
  int _selectedIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkUserType();
    _loadPets();
  }

  Future<void> _checkUserType() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('user_type')
          .eq('id', userId)
          .single();
      
      setState(() {
        _isRefugio = response['user_type'] == 'refugio';
      });
    } catch (e) {
      print('Error checking user type: $e');
    }
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('status', 'disponible');
      
      setState(() {
        _pets = (response as List).map((e) => Pet.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar mascotas: ${e.toString()}';
        _isLoading = false;
      });
      
      // Mostrar snackbar de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al cargar mascotas')),
              ],
            ),
            backgroundColor: Colors.red[700],
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadPets,
            ),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildPetsList(),
      ChatScreen(),
      MapScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 8),
            Text('PetAdopt'),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_isRefugio && _selectedIndex == 0)
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              tooltip: 'Agregar Mascota',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddPetScreen()),
                );
                if (result == true) {
                  _loadPets();
                }
              },
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    // Estado de loading
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando mascotas...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Estado de error
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              SizedBox(height: 16),
              Text(
                'Oops! Algo salió mal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPets,
                icon: Icon(Icons.refresh),
                label: Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estado vacío
    if (_pets.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                size: 80,
                color: Colors.grey[300],
              ),
              SizedBox(height: 16),
              Text(
                'No hay mascotas disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _isRefugio 
                    ? 'Comienza agregando tu primera mascota'
                    : 'Vuelve pronto para ver nuevas mascotas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              if (_isRefugio) ...[
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddPetScreen()),
                    );
                    if (result == true) {
                      _loadPets();
                    }
                  },
                  icon: Icon(Icons.add),
                  label: Text('Agregar Mascota'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Lista de mascotas con RefreshIndicator
    return RefreshIndicator(
      onRefresh: _loadPets,
      color: Colors.teal,
      child: GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return _buildPetCard(pet);
        },
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetDetailScreen(pet: pet),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con loading
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  pet.imageUrl != null
                      ? Image.network(
                          pet.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.pets,
                              size: 50,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                  // Badge de estado
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.status,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Información
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.pets,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${pet.species} • ${pet.age} años',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}