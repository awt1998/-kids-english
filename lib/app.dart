import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/home/design_preview_screen.dart';

class KidsEnglishApp extends StatelessWidget {
  const KidsEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids English',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // The interface is Arabic (right-to-left); learning content is English.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const DesignPreviewScreen(),
    );
  }
}
