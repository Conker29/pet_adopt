import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Gemini AI
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Validar que las variables estén cargadas
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty && 
           geminiApiKey.isNotEmpty;
  }
}