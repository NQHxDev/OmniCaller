import 'package:flutter/material.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_scope.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_scope.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

class App extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const App({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthController _authController;
  late final bool _isInternalAuthController;
  late final ThemeController _themeController;
  late final bool _isInternalThemeController;

  @override
  void initState() {
    super.initState();
    if (widget.authController != null) {
      _authController = widget.authController!;
      _isInternalAuthController = false;
    } else {
      _authController = AuthController();
      _isInternalAuthController = true;
      _authController.initialize();
    }

    if (widget.themeController != null) {
      _themeController = widget.themeController!;
      _isInternalThemeController = false;
    } else {
      _themeController = ThemeController();
      _isInternalThemeController = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalAuthController) {
      _authController.dispose();
    }
    if (_isInternalThemeController) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: ThemeScope(
        controller: _themeController,
        child: ListenableBuilder(
          listenable: Listenable.merge([_authController, _themeController]),
          builder: (context, _) {
            return MaterialApp(
              title: 'OmniCaller',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2563EB),
                  brightness: Brightness.light,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2563EB),
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: _themeController.themeMode,
              home: _authController.isInitializing
                  ? const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _authController.isAuthenticated
                      ? const HomePage()
                      : const LoginPage(),
            );
          },
        ),
      ),
    );
  }
}
