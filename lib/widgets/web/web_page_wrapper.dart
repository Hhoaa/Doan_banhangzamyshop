import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../screens/web/web_shell.dart';

/// Wrapper widget để đảm bảo các màn hình navigate trên web đều có header và footer
class WebPageWrapper extends StatelessWidget {
  final Widget child;
  final bool showWebHeader;
  final bool showTopBar;
  final bool showFooter;

  const WebPageWrapper({
    super.key,
    required this.child,
    this.showWebHeader = true,
    this.showTopBar = false,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Nếu không phải web, chỉ trả về child
      return child;
    }

    return WebShell(
      showWebHeader: showWebHeader,
      showTopBar: showTopBar,
      showFooter: showFooter,
      child: child,
    );
  }

  /// Helper method để wrap một route khi navigate trên web
  static Route<T> wrapRoute<T>({
    required Widget child,
    bool showWebHeader = true,
    bool showTopBar = false,
    bool showFooter = true,
  }) {
    return MaterialPageRoute<T>(
      builder: (context) => WebPageWrapper(
        showWebHeader: showWebHeader,
        showTopBar: showTopBar,
        showFooter: showFooter,
        child: child,
      ),
    );
  }
}

