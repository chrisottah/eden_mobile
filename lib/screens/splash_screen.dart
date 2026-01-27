import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'auth/login_webview_screen.dart';
import 'chat/chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup fade animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    // Check authentication after short delay
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation to play
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is already authenticated
    final isAuthenticated = await _authService.isAuthenticated();
    
    if (!mounted) return;
    
    if (isAuthenticated) {
      // Navigate to chat screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else {
      // Navigate to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginWebViewScreen(
            onLoginSuccess: (token) {
              // After successful login, navigate to chat
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'E',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // App Name
              const Text(
                'Eden AI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Your Intelligent Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
