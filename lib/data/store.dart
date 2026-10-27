import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'models.dart';

class Store extends ChangeNotifier {
  Store(this._api);

  static const String themeKey = 'wszz_wall_theme';

  final ApiClient _api;

  final List<CampusModule> modules = const [
    CampusModule(
      key: 'lost',
      name: '寻物',
      label: '校园寻物',
      desc: '丢东西、捡东西，都来这里碰个运气',
      icon: 'search',
      color: Color(0xFF3B82F6),
    ),
    CampusModule(
      key: 'rant',
      name: '吐槽',
      label: '校园吐槽',
      desc: '校内大小事，不吐不快',
      icon: 'bolt',
      color: Color(0xFFF59E0B),
    ),
    CampusModule(
      key: 'confess',
      name: '表白',
      label: '校园表白',
      desc: '把心动说出口，匿名也可以',
      icon: 'heart',
      color: Color(0xFFEC4899),
    ),
    CampusModule(
      key: 'find',
      name: '找人',
      label: '校园找人',
      desc: '找同学、找队友、找一面之缘',
      icon: 'users',
      color: Color(0xFF14B8A6),
    ),
    CampusModule(
      key: 'general',
      name: '综合',
      label: '综合板块',
      desc: '没有归类的贴吧都在这里',
      icon: 'grid',
      color: Color(0xFF64748B),
    ),
  ];

  List<AppUser> _users = [];
  List<DiscussionBar> _bars = [];
  List<Post> _posts = [];
  List<AppMessage> _messages = [];
  List<DailyTask> _tasks = [];
  List<ShopItem> _shopItems = [];
  List<Announcement> _announcements = [];
  AppSettings _settings = const AppSettings();
  String? _sessionId;

  Future<void> bootstrap() async {
    final data = await _api.get('/api/bootstrap');
    if (data is! Map) throw StoreException('服务器返回数据异常');
    final map = Map<String, dynamic>.from(data);

    final rawUser = map['user'];
    _sessionId = rawUser is Map ? rawUser['id'] as String? : null;
    _users = _parseList(map['users'], AppUser.fromJson);
    _bars = _parseList(map['bars'], DiscussionBar.fromJson);
    _posts = _parseList(map['posts'], Post.fromJson);
    _messages = _parseList(map['messages'], AppMessage.fromJson);
    _tasks = _parseList(map['tasks'], DailyTask.fromJson);
    _shopItems = _parseList(map['shopItems'], ShopItem.fromJson);
    _announcements = _parseList(map['announcements'], Announcement.fromJson);
    final rawSettings = map['settings'];
    _settings = rawSettings is Map
        ? AppSettings.fromJson(Map<String, dynamic>.from(rawSettings))
        : const AppSettings();
    notifyListeners();
  }

  Future<void> refresh() => bootstrap();

  Future<Map<String, String>> fetchCaptcha() async {
    final data = await _api.get('/api/auth/captcha');
    if (data is! Map) throw StoreException('验证码获取失败');
    return {
      'token': data['token'] as String? ?? '',
      'question': data['question'] as String? ?? '',
    };
  }

  List<DailyTask> get tasks => List.unmodifiable(_tasks);
  List<ShopItem> get shopItems => List.unmodifiable(_shopItems);
  List<Announcement> get announcements => List.unmodifiable(_announcements);
  AppSettings get settings => _settings;
  String get aboutText => _settings.aboutText.isEmpty
      ? '乌市职专墙是面向校园的互助社区。'
      : _settings.aboutText;
  String get version => _settings.version;
  List<Announcement> get pendingImportantAnnouncements =>
      _announcements.where((a) => a.important && !a.read).toList();
  Announcement? get latestAnnouncement =>
      _announcements.isEmpty ? null : _announcements.first;

  List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) builder) {
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((item) => builder(Map<String, dynamic>.from(item)))
        .toList();
  }

  /* ---------------- 模块 / 贴吧 ---------------- */

  CampusModule moduleOf(String key) {
    for (final m in modules) {
      if (m.key == key) return m;
    }
    return modules.first;
  }

  List<DiscussionBar> bars([String? moduleKey]) {
    var list = List<DiscussionBar>.from(_bars);
    if (moduleKey != null && moduleKey != 'all') {
      list = list.where((b) => b.module == moduleKey).toList();
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  DiscussionBar? bar(String id) {
    for (final b in _bars) {
      if (b.id == id) return b;
    }
    return null;
  }

  int countPosts(String barId) =>
      _posts.where((p) => !p.deleted && p.barId == barId).length;

  int countModule(String moduleKey) {
    return _posts.where((p) {
      if (p.deleted) return false;
      final b = bar(p.barId);
      return b != null && b.module == moduleKey;
    }).length;
  }

  int memberCount(String barId) {
    return _posts
        .where((p) => !p.deleted && p.barId == barId)
        .map((p) => p.authorId)
        .toSet()
        .length;
  }

  List<ShopItem> ownedItems(String type) =>
      _shopItems.where((item) => item.type == type && item.owned).toList();

  Future<DiscussionBar> addBar({
    required String name,
    String? desc,
  }) async {
    final data = await _api.post('/api/admin/bars', {
      'name': name,
      'desc': desc ?? '',
    });
    final item = DiscussionBar.fromJson(Map<String, dynamic>.from(data as Map));
    _bars.add(item);
    notifyListeners();
    return item;
  }

  Future<void> updateBar(
    String id, {
    required String name,
    String? desc,
  }) async {
    final data = await _api.patch('/api/admin/bars/$id', {
      'name': name,
      'desc': desc ?? '',
    });
    final item = DiscussionBar.fromJson(Map<String, dynamic>.from(data as Map));
    final index = _bars.indexWhere((b) => b.id == id);
    if (index >= 0) _bars[index] = item;
    notifyListeners();
  }

  Future<void> deleteBar(String id) async {
    await _api.delete('/api/admin/bars/$id');
    _bars.removeWhere((b) => b.id == id);
    for (final post in _posts) {
      if (post.barId == id) post.deleted = true;
    }
    notifyListeners();
  }

  /* ---------------- 用户 ---------------- */

  AppUser? getUser(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  AppUser? get current => _sessionId == null ? null : getUser(_sessionId!);

  bool get isAdmin {
    final u = current;
    return u != null && u.isAdmin && !u.banned;
  }

  Future<AppUser> login(String username, String password) async {
    final data = await _api.post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    final map = Map<String, dynamic>.from(data as Map);
    await _api.setToken(map['token'] as String);
    await bootstrap();
    final user = current;
    if (user == null) throw StoreException('登录失败，请重试');
    return user;
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String nickname,
    required String realName,
    required String className,
    required bool showProfile,
    required String captchaToken,
    required String captchaAnswer,
  }) async {
    final data = await _api.post('/api/auth/register', {
      'username': username,
      'password': password,
      'nickname': nickname,
      'realName': realName,
      'className': className,
      'showProfile': showProfile,
      'captchaToken': captchaToken,
      'captchaAnswer': captchaAnswer,
    });
    final map = Map<String, dynamic>.from(data as Map);
    await _api.setToken(map['token'] as String);
    await bootstrap();
    final user = current;
    if (user == null) throw StoreException('注册失败，请重试');
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // 网络异常时也要清除本机登录态
    }
    await _api.clearToken();
    _sessionId = null;
    _users = [];
    _bars = [];
    _posts = [];
    _messages = [];
    _tasks = [];
    _shopItems = [];
    _announcements = [];
    _settings = const AppSettings();
    notifyListeners();
  }

  List<AppUser> users() {
    final list = List<AppUser>.from(_users);
    list.sort((a, b) {
      if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
      return b.joinedAt.compareTo(a.joinedAt);
    });
    return list;
  }

  List<AppUser> searchUsers(String q) {
    final kw = q.trim().toLowerCase();
    final list = users();
    if (kw.isEmpty) return list;
    return list
        .where((u) =>
            u.username.toLowerCase().contains(kw) ||
            u.nickname.toLowerCase().contains(kw))
        .toList();
  }

  Map<String, int> stats() {
    return {
      'total': _users.length,
      'online': _users.where((u) => u.online && !u.banned).length,
      'banned': _users.where((u) => u.banned).length,
    };
  }

  Future<void> toggleBan(String id) async {
    final data = await _api.post('/api/admin/users/$id/ban');
    final user = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    final index = _users.indexWhere((u) => u.id == id);
    if (index >= 0) _users[index] = user;
    notifyListeners();
  }

  Future<void> setPassword(String id, String password) async {
    await _api.post('/api/admin/users/$id/password', {'password': password});
  }

  List<Post> myPosts(String userId) {
    final list = _posts
        .where((p) => !p.deleted && p.authorId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int myLikes(String userId) =>
      myPosts(userId).fold(0, (sum, p) => sum + p.likes);

  /* ---------------- 帖子 ---------------- */

  Post? post(String id, {bool includeDeleted = false}) {
    for (final p in _posts) {
      if (p.id == id && (includeDeleted || !p.deleted)) return p;
    }
    return null;
  }

  List<Post> posts({String? barId, String? q, String sort = 'new', int? limit}) {
    var list = _posts.where((p) => !p.deleted).toList();
    if (barId != null && barId.isNotEmpty) {
      list = list.where((p) => p.barId == barId).toList();
    }
    if (q != null && q.trim().isNotEmpty) {
      final kw = q.trim().toLowerCase();
      list = list.where((p) {
        final b = bar(p.barId);
        final author = getUser(p.authorId);
        return p.title.toLowerCase().contains(kw) ||
            p.content.toLowerCase().contains(kw) ||
            (b != null && b.name.toLowerCase().contains(kw)) ||
            (author != null && author.nickname.toLowerCase().contains(kw));
      }).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (sort == 'hot') {
      list.sort((a, b) {
        final sa = a.likes + a.comments.length * 3;
        final sb = b.likes + b.comments.length * 3;
        return sb.compareTo(sa);
      });
    }
    if (limit != null) list = list.take(limit).toList();
    return list;
  }

  Future<Post> createPost({
    required String barId,
    required String title,
    required String content,
    required bool anonymous,
    String? image,
  }) async {
    final data = await _api.post('/api/posts', {
      'barId': barId,
      'title': title,
      'content': content,
      'anonymous': anonymous,
      if (image != null && image.isNotEmpty) 'image': image,
    });
    final post = Post.fromJson(Map<String, dynamic>.from(data as Map));
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  Future<void> uploadAvatar(String dataUrl) async {
    final data = await _api.post('/api/me/avatar', {'image': dataUrl});
    _applyUserPayload(data);
  }

  Future<void> adjustPoints(String userId, int delta) async {
    final data = await _api.post('/api/admin/users/$userId/points', {'delta': delta});
    final user = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index >= 0) _users[index] = user;
    notifyListeners();
  }

  Future<List<Post>> pendingPosts() async {
    final data = await _api.get('/api/admin/posts/pending');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Post.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Post> reviewPost(String postId, {required bool approve, String reason = ''}) async {
    final data = await _api.post('/api/admin/posts/$postId/review', {
      'approve': approve,
      if (!approve) 'reason': reason,
    });
    final post = Post.fromJson(Map<String, dynamic>.from(data as Map));
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      _posts[index] = post;
    } else if (approve) {
      _posts.insert(0, post);
    }
    notifyListeners();
    return post;
  }

  Future<List<Map<String, dynamic>>> pendingAvatars() async {
    final data = await _api.get('/api/admin/avatars');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> reviewAvatar(String userId, {required bool approve}) async {
    final data = await _api.post('/api/admin/avatars/$userId/review', {'approve': approve});
    final user = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index >= 0) _users[index] = user;
    notifyListeners();
  }

  Future<void> addComment(String postId, String content) async {
    final data = await _api.post('/api/posts/$postId/comments', {
      'content': content,
    });
    _replacePost(Post.fromJson(Map<String, dynamic>.from(data as Map)));
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final data = await _api.post('/api/posts/$postId/like');
    _replacePost(Post.fromJson(Map<String, dynamic>.from(data as Map)));
    notifyListeners();
  }

  bool isLiked(String postId) {
    final user = current;
    if (user == null) return false;
    final p = post(postId);
    return p != null && p.likedBy.contains(user.id);
  }

  Future<void> deletePost(String id) async {
    await _api.delete('/api/posts/$id');
    final p = post(id, includeDeleted: true);
    p?.deleted = true;
    notifyListeners();
  }

  void _replacePost(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index >= 0) {
      _posts[index] = post;
    } else {
      _posts.insert(0, post);
    }
  }

  Future<void> updateProfile({
    required String nickname,
    required String realName,
    required String className,
    required String bio,
    required bool showProfile,
    required int avatar,
    required String equippedFrameId,
    required String equippedColorId,
    required String title,
  }) async {
    final data = await _api.patch('/api/me/profile', {
      'nickname': nickname,
      'realName': realName,
      'className': className,
      'bio': bio,
      'showProfile': showProfile,
      'avatar': avatar,
      'equippedFrameId': equippedFrameId,
      'equippedColorId': equippedColorId,
      'title': title,
    });
    _applyUserPayload(data);
  }

  Future<void> buyItem(String itemId) async {
    final data = await _api.post('/api/shop/buy', {'itemId': itemId});
    _applyUserPayload(data);
  }

  Future<void> claimTask(String taskId) async {
    final data = await _api.post('/api/tasks/$taskId/claim');
    _applyUserPayload(data);
  }

  Future<void> grantTitle(String userId, String title) async {
    final data = await _api.post('/api/admin/users/$userId/title', {'title': title});
    final user = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index >= 0) _users[index] = user;
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String type,
    required int points,
  }) async {
    await _api.post('/api/admin/tasks', {
      'title': title,
      'description': description,
      'type': type,
      'points': points,
    });
    await bootstrap();
  }

  Future<void> deleteTask(String id) async {
    await _api.delete('/api/admin/tasks/$id');
    await bootstrap();
  }

  Future<void> addAnnouncement({
    required String title,
    required String content,
    required bool important,
  }) async {
    await _api.post('/api/admin/announcements', {
      'title': title,
      'content': content,
      'important': important,
    });
    await bootstrap();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _api.delete('/api/admin/announcements/$id');
    await bootstrap();
  }

  Future<void> updateSettings(String aboutText) async {
    final data = await _api.patch('/api/admin/settings', {'aboutText': aboutText});
    if (data is Map) {
      _settings = AppSettings.fromJson(Map<String, dynamic>.from(data));
      notifyListeners();
    }
  }

  Future<void> markAnnouncementRead(String id) async {
    await _api.post('/api/announcements/$id/read');
    final index = _announcements.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final old = _announcements[index];
      _announcements[index] = Announcement(
        id: old.id,
        title: old.title,
        content: old.content,
        important: old.important,
        read: true,
        createdAt: old.createdAt,
      );
    }
    notifyListeners();
  }

  void _applyUserPayload(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final rawUser = map['user'];
    if (rawUser is Map) {
      final user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index >= 0) {
        _users[index] = user;
      } else {
        _users.add(user);
      }
      _sessionId = user.id;
    }
    if (map['tasks'] != null) {
      _tasks = _parseList(map['tasks'], DailyTask.fromJson);
    }
    if (map['shopItems'] != null) {
      _shopItems = _parseList(map['shopItems'], ShopItem.fromJson);
    }
    notifyListeners();
  }

  /* ---------------- 消息 ---------------- */

  List<AppMessage> messages() {
    final list = List<AppMessage>.from(_messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get unreadCount => _messages.where((m) => m.unread).length;

  Future<void> markAllRead() async {
    await _api.post('/api/messages/read-all');
    for (final m in _messages) {
      m.unread = false;
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _api.post('/api/messages/$id/read');
    for (final m in _messages) {
      if (m.id == id) m.unread = false;
    }
    notifyListeners();
  }
}
