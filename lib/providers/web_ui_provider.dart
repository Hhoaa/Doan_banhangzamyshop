import 'package:flutter/foundation.dart';

class WebUiProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String? _selectedCategoryName;
  String? _selectedStaticPage; // e.g. 'lookbook', 'about'

  int get selectedIndex => _selectedIndex;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryName => _selectedCategoryName;
  String? get selectedStaticPage => _selectedStaticPage;

  void goToTab(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategoryName(String? name) {
    _selectedCategoryName = name;
    // Switching to a product category clears static page highlight
    _selectedStaticPage = null;
    notifyListeners();
  }

  void setSelectedStaticPage(String? page) {
    // Accepts 'lookbook', 'about' or null to clear
    _selectedStaticPage = page;
    if (page != null) {
      // When opening a static page, clear product category highlight
      _selectedCategoryName = null;
    }
    notifyListeners();
  }
}


