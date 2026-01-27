import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Language Switcher Widget
/// Cho phép người dùng đổi giữa Tiếng Việt và English
class LanguageSwitcher extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const LanguageSwitcher({
    super.key,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.currentLocale;
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
    widget.onLanguageChanged(locale);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      onSelected: _changeLanguage,
      initialValue: _selectedLocale,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<Locale>(
          value: const Locale('vi'),
          child: Row(
            children: [
              const Text('🇻🇳 '),
              SizedBox(width: AppSpacing.sm),
              const Text('Tiếng Việt'),
              if (_selectedLocale.languageCode == 'vi')
                SizedBox(width: AppSpacing.md),
              if (_selectedLocale.languageCode == 'vi')
                const Icon(Icons.check, color: Color(0xFF23C4C1)),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              const Text('🇬🇧 '),
              SizedBox(width: AppSpacing.sm),
              const Text('English'),
              if (_selectedLocale.languageCode == 'en')
                SizedBox(width: AppSpacing.md),
              if (_selectedLocale.languageCode == 'en')
                const Icon(Icons.check, color: Color(0xFF23C4C1)),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.language, color: Color(0xFF23C4C1)),
      tooltip: 'Change Language',
    );
  }
}
