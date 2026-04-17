import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:quickshield_app/providers/auth_provider.dart';
import 'package:quickshield_app/navigation/app_shell.dart';
import 'package:quickshield_app/navigation/admin_shell.dart';
import 'package:quickshield_app/screens/auth/login_screen.dart';
import 'package:quickshield_app/core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const QuickShieldApp());
}

class QuickShieldApp extends StatelessWidget {
  const QuickShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QuickShield',
        theme: QSTheme.build(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isLoggedIn) return const LoginScreen();
            return auth.isAdmin ? const AdminShell() : const AppShell();
          },
        ),
      ),
    );
  }
}