import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/supabase_favorite_service.dart';
import '../models/user.dart' as app_user;

class FavoritesProvider extends ChangeNotifier {
  final Set<int> _favoriteProductIds = <int>{};
  int? _loadedForUserId;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool isFavorite(int productId) => _favoriteProductIds.contains(productId);
  Set<int> get favoriteIds => Set.unmodifiable(_favoriteProductIds);

  void handleAuthChanged(app_user.User? user) {
    final nextUserId = user?.maNguoiDung;

    if (nextUserId == null) {
      if (_favoriteProductIds.isNotEmpty || _loadedForUserId != null) {
        _favoriteProductIds.clear();
        _loadedForUserId = null;
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (_loadedForUserId == nextUserId) {
      return;
    }

    _favoriteProductIds.clear();
    _loadedForUserId = null;
    notifyListeners();
    unawaited(loadFavorites(nextUserId));
  }

  Future<void> ensureLoaded(int userId) async {
    if (_loadedForUserId == userId && _favoriteProductIds.isNotEmpty) return;
    await loadFavorites(userId);
  }

  Future<void> loadFavorites(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      final products = await SupabaseFavoriteService.getFavoriteProducts(userId);
      _favoriteProductIds
        ..clear()
        ..addAll(products.map((p) => p.maSanPham));
      _loadedForUserId = userId;
    } catch (_) {
      // ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(int userId, int productId) async {
    final ok = await SupabaseFavoriteService.addToFavorites(userId, productId);
    if (ok) {
      _favoriteProductIds.add(productId);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> remove(int userId, int productId) async {
    final ok = await SupabaseFavoriteService.removeFromFavorites(userId, productId);
    if (ok) {
      _favoriteProductIds.remove(productId);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> toggle(int userId, int productId) async {
    if (isFavorite(productId)) {
      final removed = await remove(userId, productId);
      return removed ? false : true;
    } else {
      final added = await add(userId, productId);
      return added ? true : false;
    }
  }

  void syncFavorites(int userId, Iterable<int> productIds) {
    _favoriteProductIds
      ..clear()
      ..addAll(productIds);
    _loadedForUserId = userId;
    _isLoading = false;
    notifyListeners();
  }
}


