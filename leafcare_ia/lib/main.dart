import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LeafCareApp());
}

class LeafCareApp extends StatelessWidget {
  const LeafCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeafCare AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}
