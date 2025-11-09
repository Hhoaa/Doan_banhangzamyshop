import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  AuthProvider() {
    // Lắng nghe thay đổi phiên đăng nhập từ Supabase để cập nhật UI ngay
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      try {
        if (data.session?.user != null) {
          final u = await SupabaseAuthService.getCurrentUser();
          // Chặn admin/staff trên web bán hàng
          if (kIsWeb && (u?.maRole == 1 || u?.maRole == 2)) {
            await SupabaseAuthService.logout();
            setError('Only customer accounts (role = 3) can access the sales web.');
            setUser(null);
          } else {
            setUser(u);
          }
        } else {
          setUser(null);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.loginWithEmail(email, password);
      if (user != null) {
        // Kiểm tra role: chặn admin/staff trên mobile app và web bán hàng
        if ((!kIsWeb && (user.maRole == 1 || user.maRole == 2)) || (kIsWeb && (user.maRole == 1 || user.maRole == 2))) {
          await SupabaseAuthService.logout(); // Đăng xuất ngay lập tức
          setError(kIsWeb
              ? 'Only customer accounts (role = 3) can access the sales web.'
              : 'Tài khoản Admin và Quản trị viên không thể đăng nhập vào ứng dụng bán hàng. Vui lòng sử dụng tài khoản khách hàng.');
          return false;
        }
        setUser(user);
        return true;
      } else {
        setError('Đăng nhập thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng nhập: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String fullName, String phone) async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.register(email, password, fullName, phone);
      if (user != null) {
        setUser(user);
        return true;
      } else {
        setError('Đăng ký thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng ký: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.loginWithGoogle();
      if (user != null) {
        // Kiểm tra role: chặn admin (1) và staff (2) khỏi mobile app
        if (!kIsWeb && (user.maRole == 1 || user.maRole == 2)) {
          await SupabaseAuthService.logout(); // Đăng xuất ngay lập tức
          setError('Tài khoản Admin và Quản trị viên không thể đăng nhập vào ứng dụng bán hàng. Vui lòng sử dụng tài khoản khách hàng.');
          return false;
        }
        setUser(user);
        return true;
      } else {
        setError('Đăng nhập Google thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng nhập Google: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginWithApple() async {
    setLoading(true);
    setError(null);

    try {
      final user = await SupabaseAuthService.loginWithApple();
      if (user != null) {
        // Kiểm tra role: chặn admin (1) và staff (2) khỏi mobile app
        if (!kIsWeb && (user.maRole == 1 || user.maRole == 2)) {
          await SupabaseAuthService.logout(); // Đăng xuất ngay lập tức
          setError('Tài khoản Admin và Quản trị viên không thể đăng nhập vào ứng dụng bán hàng. Vui lòng sử dụng tài khoản khách hàng.');
          return false;
        }
        setUser(user);
        return true;
      } else {
        setError('Đăng nhập Apple thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đăng nhập Apple: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> sendOTP(String email) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.sendOTP(email);
      if (success) {
        return true;
      } else {
        setError('Gửi OTP thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi gửi OTP: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.verifyOTP(email, otp);
      if (success) {
        // Sau khi verify OTP thành công, kiểm tra role của user
        final user = await SupabaseAuthService.getCurrentUser();
        if (user != null) {
          // Kiểm tra role: chặn admin (1) và staff (2) khỏi mobile app
          if (!kIsWeb && (user.maRole == 1 || user.maRole == 2)) {
            await SupabaseAuthService.logout(); // Đăng xuất ngay lập tức
            setError('Tài khoản Admin và Quản trị viên không thể đăng nhập vào ứng dụng bán hàng. Vui lòng sử dụng tài khoản khách hàng.');
            return false;
          }
          setUser(user);
        }
        return true;
      } else {
        setError('Xác thực OTP thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi xác thực OTP: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.forgotPassword(email);
      if (success) {
        return true;
      } else {
        setError('Gửi email khôi phục thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi khôi phục mật khẩu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    setLoading(true);
    setError(null);

    try {
      final success = await SupabaseAuthService.changePassword(newPassword);
      if (success) {
        return true;
      } else {
        setError('Đổi mật khẩu thất bại');
        return false;
      }
    } catch (e) {
      setError('Lỗi đổi mật khẩu: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    setError(null);

    try {
      await SupabaseAuthService.logout();
      setUser(null);
      // Reset state khác nếu cần (giỏ hàng, thông báo...)
    } catch (e) {
      setError('Lỗi đăng xuất: $e');
    } finally {
      setLoading(false);
    }
  }

  void clearError() {
    setError(null);
  }

  // Kiểm tra user hiện tại khi app khởi động
  Future<void> checkCurrentUser() async {
    setLoading(true);
    try {
      print('🔍 AuthProvider: Checking current user...');
      final user = await SupabaseAuthService.getCurrentUser();
      print('🔍 AuthProvider: User found: ${user?.tenNguoiDung}');
      
      // Kiểm tra role: chặn admin (1) và staff (2) khỏi mobile app
      if (user != null && !kIsWeb && (user.maRole == 1 || user.maRole == 2)) {
        print('🔍 AuthProvider: Admin/Staff detected on mobile, logging out...');
        await SupabaseAuthService.logout();
        setUser(null);
        return;
      }
      
      setUser(user);
    } catch (e) {
      print('Error checking current user: $e');
      setUser(null);
    } finally {
      setLoading(false);
    }
  }

  // Reload user từ database (dùng khi cập nhật thông tin user)
  Future<void> refreshUser() async {
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      if (user != null) {
        // Kiểm tra role: chặn admin (1) và staff (2) khỏi mobile app
        if (!kIsWeb && (user.maRole == 1 || user.maRole == 2)) {
          await SupabaseAuthService.logout();
          setUser(null);
          return;
        }
        setUser(user);
      } else {
        setUser(null);
      }
    } catch (e) {
      print('Error refreshing user: $e');
      // Không set error để không làm gián đoạn UI
    }
  }
}
