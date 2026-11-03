import 'package:flutter/material.dart';
import 'package:leafcare_ia/app/config/app_router.dart';
import 'package:leafcare_ia/app/config/app_theme.dart';

class LeafCareApp extends StatelessWidget {
  const LeafCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LeafCare AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
