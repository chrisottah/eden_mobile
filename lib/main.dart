import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';

void main() {
  // Ensures the Flutter engine is fully initialized before 
  // we try to access plugins like flutter_secure_storage.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // Providing AuthService here resolves the "children.isNotEmpty" crash
        // and makes authentication logic available throughout the app.
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ApiClient>(create: (_) => ApiClient()),
      ],
      child: const EdenApp(),
    ),
  );
}