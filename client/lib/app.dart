import 'package:flutter/material.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_scope.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_scope.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/calls/presentation/controllers/call_controller.dart';
import 'features/calls/presentation/controllers/call_signaling_listener.dart';
import 'features/chat/data/services/chat_websocket_service.dart';
import 'features/home/presentation/pages/home_page.dart';

class App extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final CallController? callController;

  const App({
    super.key,
    this.authController,
    this.themeController,
    this.callController,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthController _authController;
  late final bool _isInternalAuthController;
  late final ThemeController _themeController;
  late final bool _isInternalThemeController;
  late final CallController _callController;
  late final bool _isInternalCallController;
  CallSignalingListener? _callSignalingListener;

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

    if (widget.callController != null) {
      _callController = widget.callController!;
      _isInternalCallController = false;
    } else {
      _callController = CallController();
      _isInternalCallController = true;
    }

    _callSignalingListener = CallSignalingListener(
      callController: _callController,
    );

    _authController.addListener(_syncAuthWithCall);
  }

  void _syncAuthWithCall() {
    if (_authController.isAuthenticated &&
        _authController.accessToken != null &&
        _authController.currentUser != null) {
      _callController.updateAuth(
        token: _authController.accessToken!,
        currentUserId: _authController.currentUser!.id,
      );
      // Connect WebSocket if not yet connected
      ChatWebSocketService().connect(token: _authController.accessToken!);
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_syncAuthWithCall);
    _callSignalingListener?.dispose();
    if (_isInternalAuthController) {
      _authController.dispose();
    }
    if (_isInternalThemeController) {
      _themeController.dispose();
    }
    if (_isInternalCallController) {
      _callController.dispose();
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
              navigatorKey: CallSignalingListener.navigatorKey,
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
