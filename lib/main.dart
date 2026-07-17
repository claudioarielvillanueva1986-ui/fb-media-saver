import 'package:flutter/material.dart';
import 'services/ads_service.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.instance.init();
  runApp(const FbMediaSaverApp());
}

class FbMediaSaverApp extends StatelessWidget {
  const FbMediaSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1877F2), // azul Facebook
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1877F2),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
