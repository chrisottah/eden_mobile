import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WebShellScreen extends StatefulWidget {
  const WebShellScreen({super.key});

  @override
  State<WebShellScreen> createState() => _WebShellScreenState();
}

class _WebShellScreenState extends State<WebShellScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  PullToRefreshController? _pullToRefreshController;

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
    useWideViewPort: true, 
    loadWithOverviewMode: true, 
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: true,
    userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
  );

  @override
  void initState() {
    super.initState();
    // Set status bar color and edge-to-edge mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Trigger the Permission Popup for Mic and Camera
    _requestPermissions();

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.indigoAccent),
      onRefresh: () async {
        _webViewController?.reload();
      },
    );
  }

  // Requests the OS level permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF171717),
        body: SafeArea(
          child: Column(
            children: [
              if (_progress < 1.0)
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("https://edenhub.io/")),
                  initialSettings: _settings,
                  pullToRefreshController: _pullToRefreshController,
                  onWebViewCreated: (controller) => _webViewController = controller,
                  
                  // Grant permissions to the WebView internally
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },

                  onCreateWindow: (controller, createWindowAction) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return WindowPopup(createWindowAction: createWindowAction);
                      },
                    );
                    return true;
                  },

                  onProgressChanged: (controller, progress) {
                    if (progress == 100) _pullToRefreshController?.endRefreshing();
                    setState(() => _progress = progress / 100);
                  },

                  onLoadStop: (controller, url) async {
                    // Inject CSS to clean up mobile view duplicate elements
                    await controller.evaluateJavascript(source: """
                      (function() {
                        const style = document.createElement('style');
                        style.innerHTML = `
                          header.web-only-header, .mobile-url-bar { 
                            display: none !important; 
                          }
                          body, html { 
                            overflow-x: hidden !important; 
                          }
                        `;
                        document.head.appendChild(style);
                      })();
                    """);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowPopup extends StatelessWidget {
  final CreateWindowAction createWindowAction;
  const WindowPopup({super.key, required this.createWindowAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Sign In", style: TextStyle(color: Colors.white)),
      ),
      body: InAppWebView(
        windowId: createWindowAction.windowId,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
        ),
        onCloseWindow: (controller) {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}