import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitFadingCircle(color: AppColors.primary, size: size),
    );
  }
}
