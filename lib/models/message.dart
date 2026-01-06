class Message {
  // ID único del mensaje
  final String id;
  
  // El texto del mensaje
  final String text;

  // Indica si el mensaje es del usuario (true) o de la IA (false)
  final bool isUser;
  
  // Timestamp: fecha y hora en que se creó el mensaje
  final DateTime timestamp;

  // Constructor del mensaje
  // 'required' indica que estos parámetros son obligatorios
  Message({
    String? id, // Opcional, se genera automáticamente si no se proporciona
    required this.text,
    required this.isUser,
    DateTime? timestamp, // Opcional, si no se proporciona usa la hora actual
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();
  
  // Método helper para formatear la hora en formato legible
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Método helper para formatear la fecha completa
  String get formattedDateTime {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}