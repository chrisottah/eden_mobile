# Eden Mobile

A cross-platform mobile application for Eden AI, built with Flutter.

## Features

- 🔐 Multi-provider authentication (Email, Google OAuth, KingsChat OAuth)
- 💬 Real-time chat with AI models
- 📱 Native iOS and Android support
- 🎨 Beautiful, intuitive UI inspired by Conduit
- 🔄 Synchronized authentication with web platform
- 💾 Secure local storage for tokens and chat history

## Tech Stack

- **Framework:** Flutter
- **Backend:** OpenWebUI v0.7.2
- **State Management:** Provider
- **Storage:** flutter_secure_storage
- **WebView:** flutter_inappwebview

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- iOS: Xcode 14+
- Android: Android Studio with SDK 21+

### Installation

```bash
# Install dependencies
flutter pub get

# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android
```

### Configuration

Base URL: `https://edenhub.io`

## Project Structure

```
lib/
├── core/           # Constants, theme, utilities
├── data/           # Models and repositories
├── services/       # API client, auth service
├── screens/        # UI screens
└── widgets/        # Reusable widgets
```

## License

Proprietary - Eden AI
