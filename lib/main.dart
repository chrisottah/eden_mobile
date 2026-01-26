import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Add your providers here
      ],
      child: const EdenApp(),
    ),
  );
}
