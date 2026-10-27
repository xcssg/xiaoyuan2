import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/store.dart';

enum ToastType { info, success, error }

class QToastData {
  QToastData({required this.id, required this.message, required this.type});

  final int id;
  final String message;
  final ToastType type;
}

class AppRoute {
  const AppRoute(this.name, {this.id, this.tab, this.barId});

  final String name;
  final String? id;
  final String? tab;
  final String? barId;

  static const auth = AppRoute('auth');
  static const home = AppRoute('home');
  static const bars = AppRoute('bars');
  static const compose = AppRoute('compose');
  static const search = AppRoute('search');
  static const messages = AppRoute('messages');
  static const me = AppRoute('me');

  static AppRoute bar(String id) => AppRoute('bar', id: id);
  static AppRoute post(String id) => AppRoute('post', id: id);
  static AppRoute composeTo(String barId) => AppRoute('compose', barId: barId);
  static AppRoute admin([String tab = 'overview']) => AppRoute('admin', tab: tab);

  String get key => '$name:${id ?? ''}:${tab ?? ''}:${barId ?? ''}';

  bool get showDock =>
      name == 'home' ||
      name == 'bars' ||
      name == 'bar' ||
      name == 'search' ||
      name == 'messages' ||
      name == 'me';
}

class AppState extends ChangeNotifier {
  AppState(this.store, this.prefs) {
    final saved = prefs.getString(Store.themeKey);
    _darkMode = ValueNotifier<bool>(saved == 'dark');
    _stack = <AppRoute>[
      store.current != null ? AppRoute.home : AppRoute.auth,
    ];
    store.addListener(_onStoreChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (store.current == null || _refreshing) return;
      _refreshing = true;
      store.refresh().whenComplete(() {
        _refreshing = false;
      }).catchError((_) {});
    });
  }

  final Store store;
  final SharedPreferences prefs;

  late final ValueNotifier<bool> _darkMode;
  ValueNotifier<bool> get darkMode => _darkMode;

  late List<AppRoute> _stack;

  List<AppRoute> get stack => List.unmodifiable(_stack);
  AppRoute get route => _stack.last;

  final List<QToastData> _toasts = [];
  final Map<int, Timer> _toastTimers = {};
  int _toastSeq = 0;
  Timer? _refreshTimer;
  bool _refreshing = false;

  List<QToastData> get toasts => List.unmodifiable(_toasts);

  String barsFilter = 'all';
  String barSort = 'new';
  String? composeBarId;
  bool composeAnonymous = false;
  String searchQuery = '';
  String adminQuery = '';
  String adminBar = 'all';
  String userQuery = '';
  String userFilter = 'all';

  bool get isDark => _darkMode.value;

  void _onStoreChanged() => notifyListeners();

  void setBarsFilter(String value) {
    barsFilter = value;
    notifyListeners();
  }

  void setBarSort(String value) {
    barSort = value;
    notifyListeners();
  }

  void setComposeBar(String? id) {
    composeBarId = id;
    notifyListeners();
  }

  void setComposeAnonymous(bool value) {
    composeAnonymous = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setAdminQuery(String value) {
    adminQuery = value;
    notifyListeners();
  }

  void setAdminBar(String value) {
    adminBar = value;
    notifyListeners();
  }

  void setUserQuery(String value) {
    userQuery = value;
    notifyListeners();
  }

  void setUserFilter(String value) {
    userFilter = value;
    notifyListeners();
  }

  void toggleTheme() {
    final next = !_darkMode.value;
    _darkMode.value = next;
    prefs.setString(Store.themeKey, next ? 'dark' : 'light');
  }

  void setDark(bool value) {
    if (_darkMode.value == value) return;
    _darkMode.value = value;
    prefs.setString(Store.themeKey, value ? 'dark' : 'light');
  }

  /* ---------------- 导航 ---------------- */

  void navigate(AppRoute next) {
    if (_stack.last.key == next.key) return;
    _stack.add(next);
    notifyListeners();
  }

  void replace(AppRoute next) {
    _stack[_stack.length - 1] = next;
    notifyListeners();
  }

  void reset(AppRoute next) {
    _stack = [next];
    notifyListeners();
  }

  void pop() {
    if (_stack.length > 1) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  void popToHome() {
    _stack = [AppRoute.home];
    notifyListeners();
  }

  bool get canPop => _stack.length > 1;

  /* ---------------- 提示 ---------------- */

  void toast(String message, {ToastType type = ToastType.info}) {
    final id = ++_toastSeq;
    _toasts.add(QToastData(id: id, message: message, type: type));
    notifyListeners();
    _toastTimers[id] = Timer(const Duration(milliseconds: 2100), () {
      _toasts.removeWhere((t) => t.id == id);
      _toastTimers.remove(id);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    for (final timer in _toastTimers.values) {
      timer.cancel();
    }
    store.removeListener(_onStoreChanged);
    _darkMode.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
