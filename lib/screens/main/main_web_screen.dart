import 'package:flutter/material.dart';
import '../web/web_shell.dart';
import '../web/home_web_screen.dart';
import '../web/products_web_screen.dart';
import '../web/cart_web_screen.dart';
import '../web/profile_web_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/web_ui_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_auth_service.dart';

class MainWebScreen extends StatefulWidget {
  const MainWebScreen({super.key});

  @override
  State<MainWebScreen> createState() => _MainWebScreenState();
}

class _MainWebScreenState extends State<MainWebScreen> {
  int _index = 0;
  bool _isCheckingRole = true;

  // Bottom destinations are not used on wide web layout; keep rail only.

  final List<Widget> _screens = const [
    HomeWebScreen(),
    ProductsWebScreen(),
    CartWebScreen(),
    ProfileWebScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      // Kiểm tra role: chỉ cho phép role = 3 (user) vào web
      if (authProvider.user!.maRole != 3) {
        // Đăng xuất và hiển thị thông báo
        await SupabaseAuthService.logout();
        authProvider.setUser(null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chỉ tài khoản khách hàng (role = 3) mới được truy cập vào web bán hàng.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() {
        _isCheckingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra role khi user thay đổi
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.user != null && authProvider.user!.maRole != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkUserRole();
      });
    }

    if (_isCheckingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final webUi = context.watch<WebUiProvider>();
        _index = webUi.selectedIndex;
        return Row(
          children: [
            Expanded(child: WebShell(child: _screens[_index])),
          ],
        );
      },
    );
  }
}
