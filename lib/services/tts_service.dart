import 'package:flutter_tts/flutter_tts.dart';

/// Servicio para Text-to-Speech (Texto a Voz)
/// Utiliza el motor TTS nativo del sistema operativo
class TtsService {
  // Instancia única del servicio (Singleton pattern)
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  // Instancia de FlutterTts
  final FlutterTts _flutterTts = FlutterTts();
  
  // Estado de reproducción
  bool _isPlaying = false;
  
  // ID del mensaje actual que se está reproduciendo
  String? _currentMessageId;

  /// Inicializa el servicio TTS con configuraciones
  Future<void> initialize() async {
    try {
      // Configuración para Android
      await _flutterTts.setLanguage("es-ES"); // Español
      await _flutterTts.setSpeechRate(0.5);   // Velocidad normal (0.0 - 1.0)
      await _flutterTts.setVolume(1.0);       // Volumen máximo (0.0 - 1.0)
      await _flutterTts.setPitch(1.0);        // Tono normal (0.5 - 2.0)

      // Callbacks para monitorear el estado
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _currentMessageId = null;
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        _currentMessageId = null;
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        _currentMessageId = null;
      });
    } catch (e) {
      print('Error inicializando TTS: $e');
    }
  }

  /// Reproduce un texto en voz alta
  /// 
  /// [text] - El texto a reproducir
  /// [messageId] - Identificador único del mensaje (opcional)
  /// 
  /// Retorna true si se inició la reproducción exitosamente
  Future<bool> speak(String text, {String? messageId}) async {
    try {
      // Si ya está reproduciendo, detener primero
      if (_isPlaying) {
        await stop();
      }

      _currentMessageId = messageId;
      
      // Limpiar el texto de Markdown para mejor pronunciación
      final cleanText = _cleanMarkdown(text);
      
      await _flutterTts.speak(cleanText);
      return true;
    } catch (e) {
      print('Error al reproducir texto: $e');
      return false;
    }
  }

  /// Detiene la reproducción actual
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      _currentMessageId = null;
    } catch (e) {
      print('Error al detener TTS: $e');
    }
  }

  /// Pausa la reproducción actual
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error al pausar TTS: $e');
    }
  }

  /// Verifica si actualmente está reproduciendo
  bool get isPlaying => _isPlaying;

  /// Obtiene el ID del mensaje actual que se está reproduciendo
  String? get currentMessageId => _currentMessageId;

  /// Verifica si un mensaje específico se está reproduciendo
  bool isPlayingMessage(String messageId) {
    return _isPlaying && _currentMessageId == messageId;
  }

  /// Cambia el idioma del TTS
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      print('Error al cambiar idioma: $e');
    }
  }

  /// Cambia la velocidad de reproducción
  /// [rate] debe estar entre 0.0 (muy lento) y 1.0 (muy rápido)
  Future<void> setSpeechRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(clampedRate);
    } catch (e) {
      print('Error al cambiar velocidad: $e');
    }
  }

  /// Cambia el tono de la voz
  /// [pitch] debe estar entre 0.5 (grave) y 2.0 (agudo)
  Future<void> setPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(clampedPitch);
    } catch (e) {
      print('Error al cambiar tono: $e');
    }
  }

  /// Limpia el texto de Markdown para mejor pronunciación
  String _cleanMarkdown(String text) {
    String cleaned = text;
    
    // Remover enlaces markdown [texto](url)
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
    
    // Remover negritas y cursivas
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^\*]+)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*([^\*]+)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_([^_]+)_'), r'$1');
    
    // Remover código inline
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    
    // Remover bloques de código
    cleaned = cleaned.replaceAll(RegExp(r'```[^`]*```'), 'código');
    
    // Remover encabezados markdown (#, ##, ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s+'), '');
    
    // Remover listas con guiones o asteriscos
    cleaned = cleaned.replaceAll(RegExp(r'^[\-\*]\s+', multiLine: true), '');
    
    // Remover saltos de línea múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), '. ');
    
    return cleaned.trim();
  }

  /// Obtiene la lista de idiomas disponibles
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      print('Error al obtener idiomas: $e');
      return [];
    }
  }

  /// Libera los recursos del servicio
  Future<void> dispose() async {
    await stop();
  }
}