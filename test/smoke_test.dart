import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wszz_wall/app_state.dart';
import 'package:wszz_wall/data/api_client.dart';
import 'package:wszz_wall/data/store.dart';
import 'package:wszz_wall/main.dart';

void main() {
  testWidgets('所有页面均可渲染且无布局异常', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = Store(FakeApi(prefs));
    await store.bootstrap();
    final app = AppState(store, prefs);
    app.reset(AppRoute.home);

    await tester.pumpWidget(WszzWallApp(app: app));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final routes = <AppRoute>[
      AppRoute.home,
      AppRoute.bars,
      AppRoute.bar('b1'),
      AppRoute.post('p1'),
      AppRoute.compose,
      AppRoute.search,
      AppRoute.messages,
      AppRoute.me,
      AppRoute.admin('overview'),
      AppRoute.admin('content'),
      AppRoute.admin('users'),
      AppRoute.admin('bars'),
    ];

    for (final route in routes) {
      app.reset(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester.takeException(),
        isNull,
        reason: '路由 ${route.name} 渲染异常',
      );
    }

    app.setDark(true);
    app.reset(AppRoute.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);

    app.setDark(false);
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}

class FakeApi extends ApiClient {
  FakeApi(super.prefs);

  static final int _now = DateTime.now().millisecondsSinceEpoch;

  static final Map<String, dynamic> _bootstrap = {
    'user': {
      'id': 'u1',
      'username': 'admin',
      'nickname': '校园小管家',
      'role': 'admin',
      'banned': false,
      'online': true,
      'avatar': 5,
      'bio': '乌市职专墙管理员',
      'joinedAt': _now - 86400000 * 400,
    },
    'users': [
      {
        'id': 'u1',
        'username': 'admin',
        'nickname': '校园小管家',
        'role': 'admin',
        'banned': false,
        'online': true,
        'avatar': 5,
        'bio': '乌市职专墙管理员',
        'joinedAt': _now - 86400000 * 400,
      },
      {
        'id': 'u2',
        'username': 'xiaoyu',
        'nickname': '林小雨',
        'role': 'user',
        'banned': false,
        'online': true,
        'avatar': 2,
        'bio': '新闻系大二',
        'joinedAt': _now - 86400000 * 200,
      },
    ],
    'bars': [
      {
        'id': 'b1',
        'module': 'lost',
        'name': '寻物吧',
        'desc': '丢东西、捡东西，都来这里碰个运气',
        'icon': 'search',
        'members': 1286,
        'createdAt': _now - 86400000 * 400,
      },
    ],
    'posts': [
      {
        'id': 'p1',
        'barId': 'b1',
        'authorId': 'u2',
        'title': '在图书馆三楼捡到一张校园卡',
        'content': '已经交到一楼服务台，失主带着学生证去认领就好。',
        'anonymous': false,
        'likes': 24,
        'likedBy': [],
        'comments': [
          {
            'id': 'c1',
            'authorId': 'u1',
            'content': '好人一生平安',
            'createdAt': _now - 60000,
          },
        ],
        'createdAt': _now - 60000 * 12,
        'deleted': false,
      },
    ],
    'messages': [
      {
        'id': 'm1',
        'type': 'system',
        'title': '欢迎来到乌市职专墙',
        'text': '请友善发言，共同维护校园社区环境。',
        'createdAt': _now - 60000,
        'unread': true,
      },
    ],
  };

  @override
  Future<dynamic> get(String path) async => _bootstrap;

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async => {'ok': true};

  @override
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async => {'ok': true};

  @override
  Future<dynamic> delete(String path) async => {'ok': true};

  @override
  Future<void> setToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}
