import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'web_shell.dart';

class AuthWebPage extends StatelessWidget {
  final Widget child;
  const AuthWebPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return WebShell(
      showWebHeader: true,
      showTopBar: true,
      showFooter: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 24),
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}


