import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../services/auth_service.dart';

class LoginWebViewScreen extends StatefulWidget {
  final Function(String token) onLoginSuccess;

  const LoginWebViewScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
}

class _LoginWebViewScreenState extends State<LoginWebViewScreen> {
  final AuthService _authService = AuthService();
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;

  // CSS to hide website UI and style for native look
  final String _injectedCSS = '''
    /* Hide website navigation and footer */
    header, nav, footer, .navbar, .header, .footer {
      display: none !important;
    }
    
    /* Make login container full screen */
    body {
      margin: 0 !important;
      padding: 0 !important;
      background: #ffffff !important;
    }
    
    .auth-container, .login-container {
      max-width: 100% !important;
      padding: 20px !important;
      margin: 0 !important;
    }
    
    /* Style buttons to look native */
    button, .btn, input[type="submit"] {
      border-radius: 12px !important;
      padding: 16px !important;
      font-size: 16px !important;
      font-weight: 600 !important;
      border: none !important;
      transition: all 0.2s !important;
    }
    
    .oauth-button, .google-login, .kingschat-login {
      box-shadow: 0 2px 8px rgba(0,0,0,0.1) !important;
    }
  ''';

  // JavaScript to monitor for successful login
  final String _tokenCheckerJS = '''
    (function() {
      const checkToken = () => {
        const token = localStorage.getItem('token');
        if (token) {
          window.flutter_inappwebview.callHandler('tokenFound', token);
        }
      };
      
      // Check immediately
      checkToken();
      
      // Monitor localStorage changes
      const originalSetItem = localStorage.setItem;
      localStorage.setItem = function(key, value) {
        originalSetItem.apply(this, arguments);
        if (key === 'token') {
          window.flutter_inappwebview.callHandler('tokenFound', value);
        }
      };
      
      // Poll every 500ms as backup
      setInterval(checkToken, 500);
    })();
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://edenhub.io/auth'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                cacheEnabled: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                
                // Add handler for token detection
                controller.addJavaScriptHandler(
                  handlerName: 'tokenFound',
                  callback: (args) async {
                    if (args.isNotEmpty) {
                      final token = _authService.extractTokenFromJs(args[0].toString());
                      if (token != null && token.isNotEmpty) {
                        await _handleLoginSuccess(token);
                      }
                    }
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) async {
                setState(() => _isLoading = false);
                
                // Inject CSS for native styling
                await controller.injectCSSCode(source: _injectedCSS);
                
                // Inject JS to monitor token
                await controller.evaluateJavascript(source: _tokenCheckerJS);
              },
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onConsoleMessage: (controller, consoleMessage) {
                print('WebView Console: ${consoleMessage.message}');
              },
            ),
            
            // Loading indicator
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            
            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLoginSuccess(String token) async {
    // Save token
    await _authService.saveToken(token);
    
    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
      
      // Wait a moment for visual feedback
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Notify parent
      widget.onLoginSuccess(token);
    }
  }
}