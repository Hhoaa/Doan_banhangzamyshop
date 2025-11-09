import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final bool showIcon;
  final bool showText;
  final EdgeInsets? padding;

  const LanguageSelector({
    super.key,
    this.showIcon = true,
    this.showText = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return InkWell(
      onTap: () => _showLanguageDialog(context, languageProvider),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                Icons.language,
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
            if (showIcon && showText) const SizedBox(width: 4),
            if (showText)
              Text(
                languageProvider.isVietnamese ? 'VN' : 'EN',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('change_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text(l10n.vietnamese),
              trailing: languageProvider.isVietnamese
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                languageProvider.setLanguage(const Locale('vi'));
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.blue),
              title: Text(l10n.english),
              trailing: languageProvider.isEnglish
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                languageProvider.setLanguage(const Locale('en'));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

