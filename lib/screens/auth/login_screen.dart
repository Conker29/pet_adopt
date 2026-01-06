import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _userType = 'adoptante';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        // Login
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Registro
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (response.user != null) {
          // Crear perfil
          await Supabase.instance.client.from('profiles').insert({
            'id': response.user!.id,
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'user_type': _userType,
          });
          
          // Si es refugio, crear entrada en shelters
          if (_userType == 'refugio') {
            await Supabase.instance.client.from('shelters').insert({
              'user_id': response.user!.id,
              'name': _nameController.text.trim(),
              'latitude': -0.1807, // Quito - Coordenadas por defecto
              'longitude': -78.4678,
            });
          }
        }
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      String errorMessage = 'Error de autenticación';
      
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Credenciales incorrectas';
      } else if (e.message.contains('Email already registered')) {
        errorMessage = 'Este email ya está registrado';
      } else if (e.message.contains('Invalid email')) {
        errorMessage = 'Email inválido';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[400]!, Colors.teal[700]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        Text(
                          'PetAdopt',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 32),
                        
                        // Nombre (solo en registro)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Ingresa tu nombre' : null,
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val!.isEmpty) return 'Ingresa tu email';
                            if (!val.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Contraseña
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (val) {
                            if (val!.isEmpty) return 'Ingresa tu contraseña';
                            if (val.length < 6)
                              return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Tipo de usuario (solo en registro)
                        if (!_isLogin) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[100],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, color: Colors.grey[600]),
                                SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _userType,
                                      isExpanded: true,
                                      items: [
                                        DropdownMenuItem(
                                          value: 'adoptante',
                                          child: Text('Adoptante'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'refugio',
                                          child: Text('Refugio'),
                                        ),
                                      ],
                                      onChanged: (val) =>
                                          setState(() => _userType = val!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                        ] else
                          SizedBox(height: 24),
                        
                        // Botón principal
                        _isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                              )
                            : ElevatedButton(
                                onPressed: _submit,
                                child: Text(
                                  _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                        SizedBox(height: 16),
                        
                        // Toggle login/registro
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? '¿No tienes cuenta? Regístrate'
                                : '¿Ya tienes cuenta? Inicia sesión',
                            style: TextStyle(color: Colors.teal[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}