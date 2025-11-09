import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';

class HomeWebScreen extends StatelessWidget {
  const HomeWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const HomeScreen(),
    );
  }
}


