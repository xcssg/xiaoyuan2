import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'config.dart';
import 'data/api_client.dart';
import 'data/models.dart';
import 'data/store.dart';
import 'screens/admin_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/bar_screen.dart';
import 'screens/bars_screen.dart';
import 'screens/compose_screen.dart';
import 'screens/home_screen.dart';
import 'screens/me_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/post_screen.dart';
import 'screens/search_screen.dart';
import 'theme/app_theme.dart';
import 'theme/q_colors.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  SharedPreferences? _prefs;
  ApiClient? _api;
  AppState? _app;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final api = ApiClient(prefs);
      final store = Store(api);
      await store.bootstrap();
      if (!mounted) {
        api.dispose();
        return;
      }
      _app?.dispose();
      _api?.dispose();
      setState(() {
        _prefs = prefs;
        _api = api;
        _app = AppState(store, prefs);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreException ? error.message : '无法连接服务器，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _app?.dispose();
    _api?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: '乌市职专墙',
        debugShowCheckedModeBanner: false,
        theme: buildQTheme(Brightness.light),
        home: const _SplashScreen(),
      );
    }
    if (_error != null || _app == null) {
      return MaterialApp(
        title: '乌市职专墙',
        debugShowCheckedModeBanner: false,
        theme: buildQTheme(Brightness.light),
        home: _ServerErrorScreen(
          message: _error ?? '服务器未就绪',
          onRetry: _boot,
        ),
      );
    }
    return WszzWallApp(app: _app!);
  }
}

class WszzWallApp extends StatelessWidget {
  const WszzWallApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: app.darkMode,
      builder: (context, dark, _) {
        return MaterialApp(
          title: '乌市职专墙',
          debugShowCheckedModeBanner: false,
          theme: buildQTheme(Brightness.light),
          darkTheme: buildQTheme(Brightness.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: AppScope(state: app, child: const RootShell()),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 64),
            const SizedBox(height: 18),
            Text(
              '乌市职专墙',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: t.text,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'CAMPUS WALL',
              style: TextStyle(
                fontSize: 9.5,
                color: t.text3,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: t.brand,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '正在连接服务器…',
              style: TextStyle(fontSize: 12, color: t.text3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerErrorScreen extends StatelessWidget {
  const _ServerErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 64),
              const SizedBox(height: 20),
              Text(
                '暂时无法连接服务器',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.7, color: t.text2),
              ),
              const SizedBox(height: 8),
              Text(
                kApiBaseUrl,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: t.text3),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: QButton(label: '重新连接', onTap: onRetry, height: 46),
              ),
              const SizedBox(height: 14),
              Text(
                '请确认手机网络正常，或联系管理员检查服务器。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: t.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  Widget _screen(AppState app) {
    final route = app.route;
    switch (route.name) {
      case 'auth':
        return const AuthScreen();
      case 'home':
        return const HomeScreen();
      case 'bars':
        return const BarsScreen();
      case 'bar':
        return BarScreen(barId: route.id ?? '');
      case 'post':
        return PostScreen(postId: route.id ?? '');
      case 'compose':
        return ComposeScreen(presetBarId: route.barId);
      case 'search':
        return const SearchScreen();
      case 'messages':
        return const MessagesScreen();
      case 'me':
        return const MeScreen();
      case 'admin':
        return AdminScreen(tab: route.tab ?? 'overview');
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final route = app.route;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: t.dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: t.bg,
        systemNavigationBarIconBrightness:
            t.dark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: !app.canPop,
        onPopInvoked: (didPop) {
          if (didPop) return;
          if (MediaQuery.viewInsetsOf(context).bottom > 0) {
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          }
          app.pop();
        },
        child: Scaffold(
          backgroundColor: t.bg,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              const Positioned.fill(child: AppBackground()),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previous,
                        if (current != null) current,
                      ],
                    ),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .018),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(route.key),
                      child: _screen(app),
                    ),
                  ),
                ),
              ),
              if (route.showDock && !keyboardVisible)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14 + bottomInset,
                  child: QDock(app: app),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 112 + bottomInset,
                child: QToastLayer(app: app),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
