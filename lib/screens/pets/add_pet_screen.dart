import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPetScreen extends StatefulWidget {
  @override
  _AddPetScreenState createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _ageController = TextEditingController();
  final _descController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _ageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // Subir imagen si existe
      if (_image != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_nameController.text}.jpg';
        
        await Supabase.instance.client.storage
            .from('pet-images')
            .upload(fileName, _image!);

        imageUrl = Supabase.instance.client.storage
            .from('pet-images')
            .getPublicUrl(fileName);
      }

      // Obtener shelter_id del usuario actual
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final shelterResponse = await Supabase.instance.client
          .from('shelters')
          .select('id')
          .eq('user_id', userId)
          .single();

      // Insertar mascota
      await Supabase.instance.client.from('pets').insert({
        'shelter_id': shelterResponse['id'],
        'name': _nameController.text.trim(),
        'species': _speciesController.text.trim(),
        'age': int.parse(_ageController.text),
        'description': _descController.text.trim(),
        'image_url': imageUrl,
        'status': 'disponible',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('¡Mascota agregada exitosamente!')),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
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
      appBar: AppBar(
        title: Text('Agregar Mascota'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de imagen
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 220,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Toca para agregar foto',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24),
                          // Nombre
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre de la mascota',
              prefixIcon: Icon(Icons.pets),
            ),
            validator: (val) =>
                val!.isEmpty ? 'Ingresa el nombre' : null,
          ),
          SizedBox(height: 16),

          // Especie
          TextFormField(
            controller: _speciesController,
            decoration: InputDecoration(
              labelText: 'Especie (ej: Perro, Gato)',
              prefixIcon: Icon(Icons.category),
            ),
            validator: (val) =>
                val!.isEmpty ? 'Ingresa la especie' : null,
          ),
          SizedBox(height: 16),

          // Edad
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Edad (años)',
              prefixIcon: Icon(Icons.cake),
            ),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val!.isEmpty) return 'Ingresa la edad';
              if (int.tryParse(val) == null) return 'Edad inválida';
              return null;
            },
          ),
          SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            validator: (val) =>
                val!.isEmpty ? 'Ingresa una descripción' : null,
          ),
          SizedBox(height: 32),

          // Botón guardar
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                )
              : ElevatedButton(
                  onPressed: _submit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text(
                        'Guardar Mascota',
                        style: TextStyle(
                          fontSize: 16,
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
                  ),
                ),
        ],
      ),
    ),
  ),
);
}
}