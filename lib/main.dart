import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/web_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EdenAIApp());
}

class EdenAIApp extends StatelessWidget {
  const EdenAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eden AI',
      debugShowCheckedModeBanner: false,
      // 🚀 Syncs app theme with phone settings
      themeMode: ThemeMode.system, 
      
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Matches deep dark web apps
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F), foregroundColor: Colors.white),
      ),
      
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const WebShellScreen(),
      },
    );
  }
}