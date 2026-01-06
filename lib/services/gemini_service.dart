import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message.dart';

/// Servicio para comunicarse con la API de Gemini
/// Patrón Repository
/// Este servicio actúa como un repositorio que maneja la comunicación con la API externa
class GeminiService {
  
  /// Obtenemos la API key desde las variables de entorno
  /// Si no existe, lanzamos un error
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY']??'' ;
    if (key == null || key.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY no está configurada. '
        'Asegúrate de tener un archivo .env con la variable GEMINI_API_KEY'
      );
    }
    return key;
  }

  /// URL base de la API de Gemini
  /// Usamos el modelo gemini-2.5-flash
  static const String _baseUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Límite de mensajes del historial a enviar
  /// Solo enviamos los últimos N mensajes para no saturar el contexto
  static const int _historyLimit = 3;

  /// Envía un mensaje con el historial de la conversación
  /// 
  /// [message] - El nuevo mensaje del usuario
  /// [conversationHistory] - Lista completa de mensajes previos
  /// 
  /// Retorna la respuesta de la IA como String
  Future<String> sendMessage(
    String message, 
    List<Message> conversationHistory,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      // Construimos el historial limitado
      final limitedHistory = _buildLimitedHistory(conversationHistory);
      
      // Agregamos el mensaje actual
      final contents = [
        ...limitedHistory,
        {
          'role': 'user',
          'parts': [
            {'text': message}
          ]
        }
      ];

      final body = jsonEncode({
        'contents': contents,
        // Configuración opcional para controlar respuestas
        'generationConfig': {
          'temperature': 0.7,        // Creatividad (0-1)
          'maxOutputTokens': 8192,   // Longitud máxima de la respuesta
        }
      });

      // Hacemos la petición POST a la API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Verificamos que la respuesta sea exitosa (200 OK)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validamos que existan candidatos
        if (data == null || 
            data['candidates'] == null || 
            data['candidates'].isEmpty) {
          throw Exception('Respuesta inválida de la API: ${response.body}');
        }

        // Retornamos el texto de la primera respuesta candidata
        final candidate = data['candidates'][0];

        // Verificamos si hay contenido
        if (candidate == null) {
          throw Exception('No hay contenido en la respuesta: ${response.body}');
        }

        final content = candidate['content'];

        // La respuesta puede tener 'parts' o 'text' directamente
        String? text;

        if (content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'];
        } else if (content['text'] != null) {
          text = content['text'];
        }

        if (text == null || text.isEmpty) {
          throw Exception(
            'No se encontró texto en la respuesta: ${response.body}'
          );
        }
        
        return text;
      } else {
        // Si el código no es 200, lanzamos una excepción con detalles del error
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Capturamos cualquier error (red, parsing, etc.) y lo relanzamos
      throw Exception('Error al comunicarse con Gemini: $e');
    }
  }

  /// Construye un historial limitado en el formato que espera la API de Gemini
  /// 
  /// La API espera un array de objetos con estructura:
  /// {
  ///   "role": "user" | "model",
  ///   "parts": [{"text": "..."}]
  /// }
  /// 
  /// Limitamos a los últimos [_historyLimit] mensajes para no saturar el contexto
  List<Map<String, dynamic>> _buildLimitedHistory(List<Message> history) {
    // Si no hay historial, retornamos lista vacía
    if (history.isEmpty) return [];

    // Tomamos solo los últimos N mensajes
    final limitedMessages = history.length > _historyLimit
        ? history.sublist(history.length - _historyLimit)
        : history;

    // Convertimos cada mensaje al formato de la API
    return limitedMessages.map((message) {
      return {
        'role': message.isUser ? 'user' : 'model',
        'parts': [
          {'text': message.text}
        ]
      };
    }).toList();
  }

  /// Método alternativo para enviar mensaje sin historial
  /// Útil si quieres hacer una consulta independiente
  Future<String> sendSingleMessage(String message) async {
    return sendMessage(message, []);
  }
}