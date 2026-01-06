import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: AppConstants.geminiApiKey,
    );
    
    _chat = _model.startChat(history: [
      Content.text(
        'Eres un asistente virtual experto en cuidado de mascotas llamado PetBot. '
        'Responde preguntas sobre salud, alimentación, comportamiento y cuidados de perros y gatos. '
        'Sé amable, conciso y usa emojis ocasionalmente. '
        'Si no sabes algo, recomienda consultar a un veterinario.'
      ),
    ]);
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? 'No pude procesar tu mensaje 😔';
    } catch (e) {
      return 'Error al conectar con el asistente. Por favor intenta de nuevo. 🔄';
    }
  }

  void resetChat() {
    _chat = _model.startChat(history: [
      Content.text(
        'Eres un asistente virtual experto en cuidado de mascotas llamado PetBot. '
        'Responde preguntas sobre salud, alimentación, comportamiento y cuidados de perros y gatos. '
        'Sé amable, conciso y usa emojis ocasionalmente.'
      ),
    ]);
  }
}