import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pet_model.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  PetDetailScreen({required this.pet});

  @override
  _PetDetailScreenState createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _isLoading = false;
  bool _alreadyRequested = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('adoption_requests')
          .select()
          .eq('pet_id', widget.pet.id)
          .eq('adopter_id', userId);

      setState(() {
        _alreadyRequested = response.isNotEmpty;
      });
    } catch (e) {
      print('Error checking request: $e');
    }
  }

  Future<void> _requestAdoption() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('adoption_requests').insert({
        'pet_id': widget.pet.id,
        'adopter_id': userId,
        'shelter_id': widget.pet.shelterId,
        'message': 'Solicitud de adopción para ${widget.pet.name}',
        'status': 'pendiente',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('¡Solicitud enviada exitosamente!')),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al enviar solicitud')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.pet.imageUrl != null
                  ? Image.network(
                      widget.pet.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.pets,
                            size: 100,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.pets,
                        size: 100,
                        color: Colors.grey[500],
                      ),
                    ),
            ),
            backgroundColor: Colors.teal,
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.pet.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.pet.status,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Información básica
                  _buildInfoCard(
                    icon: Icons.pets,
                    title: 'Especie',
                    value: widget.pet.species,
                  ),
                  SizedBox(height: 12),
                  
                  _buildInfoCard(
                    icon: Icons.cake,
                    title: 'Edad',
                    value: '${widget.pet.age} año${widget.pet.age != 1 ? 's' : ''}',
                  ),
                  SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.pet.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),

      // Botón flotante
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: _alreadyRequested
            ? Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pending, color: Colors.orange[800]),
                    SizedBox(width: 8),
                    Text(
                      'Solicitud pendiente',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _requestAdoption,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite),
                        SizedBox(width: 8),
                        Text(
                          'Solicitar Adopción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.teal, size: 24),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}