class ApiConstants {
  static const String baseUrl = 'https://edenhub.io';
  static const String apiVersion = '/api/v1';
  static const String fullApiUrl = '$baseUrl$apiVersion';
  
  // Endpoints
  static const String authEndpoint = '/auth';
  static const String chatsEndpoint = '/chats';
  static const String modelsEndpoint = '/models';
  static const String chatCompletionsEndpoint = '/chat/completions';
}
