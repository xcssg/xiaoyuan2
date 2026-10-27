import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.tab});

  final String tab;

  static const _tabs = [
    ('overview', '概览'),
    ('content', '内容'),
    ('users', '用户'),
    ('bars', '贴吧'),
    ('operations', '运营'),
    ('settings', '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    if (!store.isAdmin) {
      return Column(
        children: [
          QTopBar(
            title: '管理后台',
            large: false,
            leading: QIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: app.pop,
            ),
          ),
          const Expanded(
            child: QEmptyState(
              icon: Icons.shield_outlined,
              title: '仅管理员可访问',
              desc: '请使用管理员账号登录后重试',
            ),
          ),
        ],
      );
    }

    final titles = {
      'overview': '管理后台',
      'content': '内容管理',
      'users': '用户管理',
      'bars': '贴吧管理',
      'operations': '公告与任务',
      'settings': '社区设置',
    };

    Widget? action;
    if (tab == 'overview') {
      action = const QPill(text: '管理员', icon: Icons.shield_outlined);
    } else if (tab == 'content') {
      action = QPill(
        text: '${store.posts().length} 条',
        style: QPillStyle.soft,
      );
    } else if (tab == 'users') {
      action = QPill(text: '${store.stats()['total']} 人', style: QPillStyle.soft);
    } else if (tab == 'bars') {
      action = QIconButton(
        icon: Icons.add_rounded,
        accent: true,
        iconSize: 19,
        onTap: () => _newBar(context),
      );
    } else {
      action = const QPill(text: '管理员', icon: Icons.shield_outlined);
    }

    return Column(
      children: [
        QTopBar(
          title: titles[tab] ?? '管理后台',
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
          actions: [if (action != null) action],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          child: _AdminTabs(
            active: tab,
            onSelect: (value) => app.replace(AppRoute.admin(value)),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: () {
              final i = ['overview', 'content', 'users', 'bars', 'operations', 'settings'].indexOf(tab);
              return i < 0 ? 0 : i;
            }(),
            children: [
              _OverviewTab(
                bottomInset: bottomInset,
                onOpenPost: (id) => app.navigate(AppRoute.post(id)),
                onOpenTab: (value) => app.replace(AppRoute.admin(value)),
              ),
              _ContentTab(
                bottomInset: bottomInset,
                initialQuery: app.adminQuery,
                filter: app.adminBar,
                onOpenPost: (id) => app.navigate(AppRoute.post(id)),
              ),
              _UsersTab(
                bottomInset: bottomInset,
                initialQuery: app.userQuery,
                filter: app.userFilter,
                onOpenTab: (value) => app.replace(AppRoute.admin(value)),
              ),
              _BarsTab(
                bottomInset: bottomInset,
                onNewBar: () => _newBar(context),
              ),
              _OperationsTab(bottomInset: bottomInset),
              _SettingsTab(bottomInset: bottomInset),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   标签
   ============================================================ */

class _AdminTabs extends StatelessWidget {
  const _AdminTabs({required this.active, required this.onSelect});

  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          for (final item in AdminScreen._tabs)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(item.$1),
                scale: .97,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active == item.$1
                        ? (t.dark ? const Color(0xFF262B35) : t.surfaceSolid)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: active == item.$1 && !t.dark
                        ? [
                            BoxShadow(
                              color: const Color(0x1A102E60),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active == item.$1 ? FontWeight.w600 : FontWeight.w400,
                      color: active == item.$1 ? t.text : t.text2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ============================================================
   概览
   ============================================================ */

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.bottomInset,
    required this.onOpenPost,
    required this.onOpenTab,
  });

  final double bottomInset;
  final ValueChanged<String> onOpenPost;
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final stats = store.stats();
    final newToday = store
        .posts()
        .where((p) => DateTime.now().millisecondsSinceEpoch - p.createdAt < 86400000)
        .length;
    final recent = store.posts(limit: 4);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daily = List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final next = day.add(const Duration(days: 1));
      final count = store.posts().where((post) =>
          post.createdAt >= day.millisecondsSinceEpoch &&
          post.createdAt < next.millisecondsSinceEpoch).length;
      final labels = ['一', '二', '三', '四', '五', '六', '日'];
      return (label: labels[day.weekday - 1], count: count);
    });
    final maxDaily = daily.fold<int>(0, (max, item) => item.count > max ? item.count : max);
    final totalDaily = daily.fold<int>(0, (sum, item) => sum + item.count);

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 6, 18, 34 + bottomInset),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF142F6E), Color(0xFF2F6BFF), Color(0xFF6AA8FF)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E4AA8).withOpacity(.34),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  right: -70,
                  top: -90,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.22)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 23,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            const Text(
                              'ADMIN CONSOLE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '校园社区管理',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '今天新增 $newToday 条帖子 · 共 ${store.bars().length} 个贴吧',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline_rounded,
                value: '${stats['total']}',
                label: '用户总数',
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                icon: Icons.visibility_outlined,
                value: '${stats['online']}',
                label: '当前在线',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                icon: Icons.block_rounded,
                value: '${stats['banned']}',
                label: '已封禁',
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        QCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '近 7 日发帖',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '共 $totalDaily 条',
                    style: TextStyle(fontSize: 10.5, color: t.text3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < daily.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${daily[i].count}',
                              style: TextStyle(fontSize: 8.5, color: t.text3),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 22,
                              height: daily[i].count == 0
                                  ? 3
                                  : 8 + (daily[i].count / (maxDaily == 0 ? 1 : maxDaily)) * 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    t.brand2,
                                    t.brand.withOpacity(.25),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  topRight: Radius.circular(7),
                                  bottomLeft: Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              daily[i].label,
                              style: TextStyle(fontSize: 9, color: t.text3),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.delete_outline_rounded,
                title: '内容管理',
                desc: '删除违规帖子',
                color: const Color(0xFFEF4444),
                onTap: () => onOpenTab('content'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _QuickCard(
                icon: Icons.people_outline_rounded,
                title: '用户管理',
                desc: '封禁 / 修改密码',
                color: const Color(0xFF3B82F6),
                onTap: () => onOpenTab('users'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.explore_outlined,
                title: '贴吧管理',
                desc: '新增 / 改名 / 删除',
                color: const Color(0xFF14B8A6),
                onTap: () => onOpenTab('bars'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _QuickCard(
                icon: Icons.home_outlined,
                title: '返回社区',
                desc: '查看前台效果',
                color: const Color(0xFF8B5CF6),
                onTap: app.popToHome,
              ),
            ),
          ],
        ),
        QSectionHead(
          title: '最近发布',
          trailing: Text(
            '共 ${store.posts().length} 条',
            style: TextStyle(fontSize: 12, color: t.text3),
          ),
        ),
        for (final post in recent) ...[
          Pressable(
            onTap: () => onOpenPost(post.id),
            scale: .985,
            child: Container(
              padding: const EdgeInsets.all(13),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: t.border),
                boxShadow: t.cardShadow,
              ),
              child: Row(
                children: [
                  QBarIcon(
                    icon: Icons.edit_outlined,
                    color: store.moduleOf(store.bar(post.barId)?.module ?? 'lost').color,
                    size: 38,
                    iconSize: 17,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${store.getUser(post.authorId)?.nickname ?? '已注销'} · ${store.bar(post.barId)?.name ?? '-'} · ${timeAgo(post.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: t.text3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 17, color: t.text3),
                ],
              ),
            ),
          ),
        ],
        if (recent.isEmpty)
          const QEmptyState(
            icon: Icons.edit_outlined,
            title: '还没有帖子',
            desc: '社区刚刚创建，等待第一条内容',
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -24,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(.10),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.5,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: t.text3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .97,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: t.text3),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   内容管理
   ============================================================ */

class _ContentTab extends StatefulWidget {
  const _ContentTab({
    required this.bottomInset,
    required this.initialQuery,
    required this.filter,
    required this.onOpenPost,
  });

  final double bottomInset;
  final String initialQuery;
  final String filter;
  final ValueChanged<String> onOpenPost;

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  late final TextEditingController _controller;
  List<Post> _pending = [];
  bool _pendingLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final app = AppScope.of(context);
    setState(() => _pendingLoading = true);
    try {
      final list = await app.store.pendingPosts();
      if (!mounted) return;
      setState(() {
        _pending = list;
        _pendingLoading = false;
      });
    } on StoreException {
      if (!mounted) return;
      setState(() => _pendingLoading = false);
    }
  }

  Future<void> _approve(Post post) async {
    final app = AppScope.of(context);
    try {
      await app.store.reviewPost(post.id, approve: true);
      app.toast('已通过审核', type: ToastType.success);
      await _loadPending();
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _reject(Post post) async {
    final app = AppScope.of(context);
    final data = await showQForm(
      context,
      title: '填写不通过原因',
      desc: '原因会通过消息发送给发帖同学。',
      fields: [
        QFormFieldSpec(
          name: 'reason',
          label: '不通过原因',
          hint: '例如：内容与本吧主题无关',
          minLength: 2,
          maxLength: 60,
        ),
      ],
      confirmText: '提交',
    );
    if (data == null || !mounted) return;
    try {
      await app.store.reviewPost(post.id, approve: false, reason: data['reason'] ?? '');
      app.toast('已通知发帖同学', type: ToastType.success);
      await _loadPending();
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Widget _pendingCard(Post post) {
    final t = QColors.of(context);
    final store = AppScope.of(context).store;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: t.warn.withOpacity(.35)),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const QPill(text: '待审核', style: QPillStyle.soft),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${store.getUser(post.authorId)?.nickname ?? '已注销'} · ${store.bar(post.barId)?.name ?? '未知贴吧'} · ${timeAgo(post.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: t.text3),
          ),
          const SizedBox(height: 5),
          Text(
            post.content.replaceAll('\n', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, height: 1.5, color: t.text2),
          ),
          if (post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                qImageUrl(post.imageUrl),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              _TinyButton(
                icon: Icons.check_rounded,
                label: '通过',
                onTap: () => _approve(post),
              ),
              const SizedBox(width: 7),
              _TinyButton(
                icon: Icons.close_rounded,
                label: '不通过',
                danger: true,
                onTap: () => _reject(post),
              ),
              const SizedBox(width: 7),
              _TinyButton(
                icon: Icons.visibility_outlined,
                label: '查看',
                onTap: () => widget.onOpenPost(post.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Post post) async {
    final app = AppScope.of(context);
    final ok = await showQConfirm(
      context,
      title: '删除这条帖子？',
      desc: '「${post.title}」将从社区中移除，删除后不可恢复。',
      confirmText: '删除',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await app.store.deletePost(post.id);
      app.toast('帖子已删除', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final filter = widget.filter;
    final q = widget.initialQuery;
    var list = store.posts(q: q);
    if (filter != 'all') {
      list = list.where((p) => p.barId == filter).toList();
    }
    final bars = store.bars();

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 34 + widget.bottomInset),
      children: [
        Row(
          children: [
            Expanded(
              child: QSearchField(
                controller: _controller,
                hint: '搜索标题、正文或作者',
                onSubmitted: (value) {
                  app.setAdminQuery(value);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            QIconButton(
              icon: Icons.arrow_forward_rounded,
              accent: true,
              iconSize: 18,
              onTap: () {
                app.setAdminQuery(_controller.text);
                FocusScope.of(context).unfocus();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_pending.isNotEmpty) ...[
          Row(
            children: [
              Text(
                '待审核帖子',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.text),
              ),
              const SizedBox(width: 6),
              QPill(text: '${_pending.length}', style: QPillStyle.soft),
              const Spacer(),
              QTextButton(label: '刷新', onTap: _loadPending),
            ],
          ),
          const SizedBox(height: 8),
          for (final post in _pending) _pendingCard(post),
          const SizedBox(height: 3),
        ],
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              QChip(
                label: '全部',
                active: filter == 'all',
                onTap: () => app.setAdminBar('all'),
              ),
              for (final bar in bars) ...[
                const SizedBox(width: 8),
                QChip(
                  label: bar.name,
                  active: filter == bar.id,
                  onTap: () => app.setAdminBar(bar.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final post in list) ...[
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: t.border),
              boxShadow: t.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.text,
                        ),
                      ),
                    ),
                    if (post.anonymous) ...[
                      const SizedBox(width: 5),
                      const QPill(text: '匿名', style: QPillStyle.soft),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.getUser(post.authorId)?.nickname ?? '已注销'} · ${store.bar(post.barId)?.name ?? '未知贴吧'} · ${timeAgo(post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: t.text3),
                ),
                const SizedBox(height: 5),
                Text(
                  post.content.replaceAll('\n', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: t.text3),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 11, color: t.text3),
                    const SizedBox(width: 3),
                    Text('${post.likes}', style: TextStyle(fontSize: 10, color: t.text3)),
                    const SizedBox(width: 12),
                    Icon(Icons.chat_bubble_outline_rounded, size: 11, color: t.text3),
                    const SizedBox(width: 3),
                    Text('${post.comments.length}', style: TextStyle(fontSize: 10, color: t.text3)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TinyButton(
                      icon: Icons.visibility_outlined,
                      label: '查看',
                      onTap: () => widget.onOpenPost(post.id),
                    ),
                    const SizedBox(width: 7),
                    _TinyButton(
                      icon: Icons.delete_outline_rounded,
                      label: '删除',
                      danger: true,
                      onTap: () => _delete(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (list.isEmpty)
          const QEmptyState(
            icon: Icons.delete_outline_rounded,
            title: '没有匹配的帖子',
            desc: '试试调整筛选条件或关键词',
          ),
      ],
    );
  }
}

/* ============================================================
   用户管理
   ============================================================ */

class _UsersTab extends StatefulWidget {
  const _UsersTab({
    required this.bottomInset,
    required this.initialQuery,
    required this.filter,
    required this.onOpenTab,
  });

  final double bottomInset;
  final String initialQuery;
  final String filter;
  final ValueChanged<String> onOpenTab;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late final TextEditingController _controller;
  List<Map<String, dynamic>> _avatars = [];
  bool _loadingAvatars = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvatars());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleBan(AppUser user) async {
    final app = AppScope.of(context);
    final banning = !user.banned;
    final ok = await showQConfirm(
      context,
      title: banning ? '封禁该用户？' : '解除封禁？',
      desc: banning
          ? '「${user.nickname}」将无法登录、发帖和评论，已发布内容仍会保留。'
          : '解除后，该用户将恢复登录和发言权限。',
      confirmText: banning ? '封禁' : '解封',
      danger: banning,
    );
    if (!ok) return;
    try {
      await app.store.toggleBan(user.id);
      app.toast(banning ? '用户已封禁' : '用户已解封', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _grantTitle(AppUser user) async {
    final app = AppScope.of(context);
    final data = await showQForm(
      context,
      title: '授予专属称号',
      desc: '当前称号：${user.grantedTitle.isEmpty ? '无' : user.grantedTitle}。留空可取消称号。',
      fields: [
        QFormFieldSpec(
          name: 'title',
          label: '称号',
          initialValue: user.grantedTitle,
          hint: '例如：校园先锋',
          required: false,
          maxLength: 12,
        ),
      ],
      confirmText: '保存',
    );
    if (data == null || !mounted) return;
    try {
      await app.store.grantTitle(user.id, data['title'] ?? '');
      app.toast('称号已更新', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _resetPassword(AppUser user) async {
    final app = AppScope.of(context);
    final data = await showQForm(
      context,
      title: '修改登录密码',
      desc: '为「${user.nickname}」设置新的登录密码，建议告知本人后尽快修改。',
      fields: const [
        QFormFieldSpec(
          name: 'password',
          label: '新密码',
          hint: '至少 6 位',
          password: true,
          minLength: 6,
          maxLength: 20,
        ),
      ],
      confirmText: '保存',
    );
    if (data == null || !mounted) return;
    try {
      await app.store.setPassword(user.id, data['password'] ?? '');
      app.toast('登录密码已更新', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _adjustPoints(AppUser user) async {
    final app = AppScope.of(context);
    final data = await showQForm(
      context,
      title: '调整积分',
      desc: '「${user.nickname}」当前 ${user.points} 积分。正数为增加，负数为扣减。',
      fields: const [
        QFormFieldSpec(
          name: 'delta',
          label: '积分变动',
          hint: '例如 50 或 -20',
          minLength: 1,
          maxLength: 6,
        ),
      ],
      confirmText: '确认调整',
    );
    if (data == null || !mounted) return;
    final delta = int.tryParse((data['delta'] ?? '').trim());
    if (delta == null || delta == 0) {
      app.toast('请输入非零的整数', type: ToastType.error);
      return;
    }
    try {
      await app.store.adjustPoints(user.id, delta);
      app.toast('积分已调整', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _loadAvatars() async {
    final app = AppScope.of(context);
    setState(() => _loadingAvatars = true);
    try {
      final list = await app.store.pendingAvatars();
      if (!mounted) return;
      setState(() {
        _avatars = list;
        _loadingAvatars = false;
      });
    } on StoreException {
      if (!mounted) return;
      setState(() => _loadingAvatars = false);
    }
  }

  Future<void> _reviewAvatar(Map<String, dynamic> entry, bool approve) async {
    final app = AppScope.of(context);
    final raw = entry['user'];
    if (raw is! Map) return;
    final user = AppUser.fromJson(Map<String, dynamic>.from(raw));
    try {
      await app.store.reviewAvatar(user.id, approve: approve);
      app.toast(approve ? '头像已通过' : '已拒绝该头像', type: ToastType.success);
      await _loadAvatars();
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Widget _avatarCard(Map<String, dynamic> entry) {
    final t = QColors.of(context);
    final raw = entry['user'];
    if (raw is! Map) return const SizedBox.shrink();
    final user = AppUser.fromJson(Map<String, dynamic>.from(raw));
    final url = qImageUrl(entry['pendingUrl'] as String? ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              url,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                color: t.field,
                child: Icon(Icons.person_outline_rounded, size: 20, color: t.text3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username} · 待审核新头像',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: t.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TinyButton(
            icon: Icons.check_rounded,
            label: '通过',
            onTap: () => _reviewAvatar(entry, true),
          ),
          const SizedBox(width: 6),
          _TinyButton(
            icon: Icons.close_rounded,
            label: '拒绝',
            danger: true,
            onTap: () => _reviewAvatar(entry, false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final q = widget.initialQuery;
    final filter = widget.filter;
    var list = store.searchUsers(q);
    if (filter == 'active') {
      list = list.where((u) => !u.banned).toList();
    } else if (filter == 'banned') {
      list = list.where((u) => u.banned).toList();
    }
    final stats = store.stats();

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 34 + widget.bottomInset),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline_rounded,
                value: '${stats['total']}',
                label: '总用户',
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                icon: Icons.visibility_outlined,
                value: '${stats['online']}',
                label: '在线',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                icon: Icons.block_rounded,
                value: '${stats['banned']}',
                label: '封禁',
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        if (_loadingAvatars)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_avatars.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '待审核头像',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.text),
              ),
              const SizedBox(width: 6),
              QPill(text: '${_avatars.length}', style: QPillStyle.soft),
              const Spacer(),
              QTextButton(label: '刷新', onTap: _loadAvatars),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in _avatars) _avatarCard(entry),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: QSearchField(
                controller: _controller,
                hint: '搜索昵称或账号',
                onSubmitted: (value) {
                  app.setUserQuery(value);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            QIconButton(
              icon: Icons.arrow_forward_rounded,
              accent: true,
              iconSize: 18,
              onTap: () {
                app.setUserQuery(_controller.text);
                FocusScope.of(context).unfocus();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              QChip(
                label: '全部',
                active: filter == 'all',
                onTap: () => app.setUserFilter('all'),
              ),
              const SizedBox(width: 8),
              QChip(
                label: '正常',
                active: filter == 'active',
                onTap: () => app.setUserFilter('active'),
              ),
              const SizedBox(width: 8),
              QChip(
                label: '已封禁',
                active: filter == 'banned',
                onTap: () => app.setUserFilter('banned'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final user in list) ...[
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: t.border),
              boxShadow: t.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    QAvatar(user: user, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: parseHexColor(user.nameColor) ?? t.text,
                                  ),
                                ),
                              ),
                              if (user.isAdmin) ...[
                                const SizedBox(width: 5),
                                const QPill(
                                  text: '管理员',
                                  icon: Icons.shield_outlined,
                                ),
                              ],
                              if (user.title.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                QTitleBadge(
                                  title: user.title,
                                  granted: user.grantedTitle.isNotEmpty &&
                                      user.title == user.grantedTitle,
                                ),
                              ],
                              if (user.banned) ...[
                                const SizedBox(width: 5),
                                const QPill(
                                  text: '已封禁',
                                  style: QPillStyle.danger,
                                ),
                              ],
                              if (user.online && !user.banned) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: t.ok,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: t.ok.withOpacity(.14),
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username} · 加入 ${daysSince(user.joinedAt)} 天',
                            style: TextStyle(fontSize: 10.5, color: t.text3),
                          ),
                          if (user.realName.isNotEmpty || user.className.isNotEmpty)
                            Text(
                              '${user.className}${user.className.isNotEmpty && user.realName.isNotEmpty ? ' · ' : ''}${user.realName}${user.showProfile ? ' · 公开' : ' · 不公开'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: t.text3),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (user.isAdmin)
                      const QPill(
                        text: '受保护账号',
                        icon: Icons.shield_outlined,
                        style: QPillStyle.soft,
                      )
                    else
                      _TinyButton(
                        icon: user.banned
                            ? Icons.check_rounded
                            : Icons.block_rounded,
                        label: user.banned ? '解封' : '封禁',
                        danger: !user.banned,
                        onTap: () => _toggleBan(user),
                      ),
                    _TinyButton(
                      icon: Icons.key_rounded,
                      label: '修改密码',
                      onTap: () => _resetPassword(user),
                    ),
                    _TinyButton(
                      icon: Icons.workspace_premium_outlined,
                      label: '称号',
                      onTap: () => _grantTitle(user),
                    ),
                    _TinyButton(
                      icon: Icons.stars_outlined,
                      label: '积分',
                      onTap: () => _adjustPoints(user),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (list.isEmpty)
          const QEmptyState(
            icon: Icons.people_outline_rounded,
            title: '没有匹配的用户',
            desc: '换个关键词或筛选条件试试',
          ),
      ],
    );
  }
}

/* ============================================================
   公告 / 每日任务
   ============================================================ */

class _OperationsTab extends StatelessWidget {
  const _OperationsTab({required this.bottomInset});

  final double bottomInset;

  String _typeLabel(String type) {
    switch (type) {
      case 'login':
        return '登录';
      case 'post':
        return '发帖';
      case 'comment':
        return '评论';
      case 'like':
        return '点赞';
      default:
        return '打卡';
    }
  }

  Future<void> _addAnnouncement(BuildContext context) async {
    final app = AppScope.of(context);
    final data = await showQForm(
      context,
      title: '发布公告',
      desc: '重要公告会在用户进入软件时弹窗展示，需阅读 3 秒后才能关闭。',
      fields: const [
        QFormFieldSpec(name: 'title', label: '公告标题', hint: '例如：本周校园活动安排', maxLength: 30),
        QFormFieldSpec(name: 'content', label: '公告内容', hint: '写清楚时间、地点和注意事项', multiline: true, maxLength: 2000),
        QFormFieldSpec(
          name: 'important',
          label: '公告类型',
          initialValue: '0',
          options: [QFormOption('0', '普通公告'), QFormOption('1', '重要公告（弹窗）')],
        ),
      ],
      confirmText: '发布',
    );
    if (data == null || !context.mounted) return;
    try {
      await app.store.addAnnouncement(
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        important: data['important'] == '1',
      );
      app.toast('公告已发布', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _deleteAnnouncement(BuildContext context, Announcement item) async {
    final app = AppScope.of(context);
    final ok = await showQConfirm(
      context,
      title: '删除这条公告？',
      desc: '「${item.title}」删除后用户将不再看到。',
      confirmText: '删除',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await app.store.deleteAnnouncement(item.id);
      app.toast('公告已删除', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _addTask(BuildContext context) async {
    final app = AppScope.of(context);
    final data = await showQForm(
      context,
      title: '新增每日任务',
      desc: '登录、发帖、评论、点赞会在完成操作后自动发放积分；打卡任务需要用户手动领取。',
      fields: const [
        QFormFieldSpec(name: 'title', label: '任务名称', hint: '例如：发布一条帖子', maxLength: 20),
        QFormFieldSpec(name: 'description', label: '任务说明', hint: '简单说明如何完成', required: false, maxLength: 60),
        QFormFieldSpec(
          name: 'type',
          label: '任务类型',
          initialValue: 'manual',
          options: [
            QFormOption('login', '每日登录'),
            QFormOption('post', '发布帖子'),
            QFormOption('comment', '发表评论'),
            QFormOption('like', '点赞'),
            QFormOption('manual', '手动打卡'),
          ],
        ),
        QFormFieldSpec(name: 'points', label: '积分奖励', hint: '1 - 100', maxLength: 3),
      ],
      confirmText: '创建',
    );
    if (data == null || !context.mounted) return;
    final points = int.tryParse((data['points'] ?? '').trim()) ?? 0;
    if (points < 1 || points > 100) {
      app.toast('积分需为 1 - 100 的整数', type: ToastType.error);
      return;
    }
    try {
      await app.store.addTask(
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: data['type'] ?? 'manual',
        points: points,
      );
      app.toast('任务已创建', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _deleteTask(BuildContext context, DailyTask task) async {
    final app = AppScope.of(context);
    final ok = await showQConfirm(
      context,
      title: '删除这个任务？',
      desc: '「${task.title}」删除后将不再出现在用户的任务中心。',
      confirmText: '删除',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await app.store.deleteTask(task.id);
      app.toast('任务已删除', type: ToastType.success);
    } on StoreException catch (e) {
      app.toast(e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 34 + bottomInset),
      children: [
        Row(
          children: [
            Text('公告与广播', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.text)),
            const Spacer(),
            QTextButton(label: '+ 发布公告', onTap: () => _addAnnouncement(context)),
          ],
        ),
        if (store.announcements.isEmpty)
          QCard(
            child: Text(
              '还没有公告，发布一条重要公告后用户进入软件会看到弹窗。',
              style: TextStyle(fontSize: 11.5, height: 1.6, color: t.text3),
            ),
          )
        else
          for (final item in store.announcements) ...[
            QCard(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (item.important)
                        const QPill(text: '重要', style: QPillStyle.danger)
                      else
                        const QPill(text: '普通', style: QPillStyle.soft),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, height: 1.55, color: t.text3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(timeAgo(item.createdAt), style: TextStyle(fontSize: 9.5, color: t.text3)),
                      const Spacer(),
                      _TinyButton(
                        icon: Icons.delete_outline_rounded,
                        label: '删除',
                        danger: true,
                        onTap: () => _deleteAnnouncement(context, item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 14),
        Row(
          children: [
            Text('每日任务', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.text)),
            const Spacer(),
            QTextButton(label: '+ 新增任务', onTap: () => _addTask(context)),
          ],
        ),
        if (store.tasks.isEmpty)
          QCard(
            child: Text(
              '还没有每日任务，新增后用户可以在任务中心获取积分。',
              style: TextStyle(fontSize: 11.5, height: 1.6, color: t.text3),
            ),
          )
        else
          for (final task in store.tasks) ...[
            QCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
                              ),
                            ),
                            const SizedBox(width: 5),
                            QPill(text: _typeLabel(task.type), style: QPillStyle.soft),
                            const SizedBox(width: 5),
                            QPill(text: '+${task.points}', style: QPillStyle.brand),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: t.text3),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TinyButton(
                    icon: Icons.delete_outline_rounded,
                    label: '删除',
                    danger: true,
                    onTap: () => _deleteTask(context, task),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 6),
        Text(
          '积分商店中的头像框、昵称颜色和称号为固定装扮；专属称号可在用户管理中单独授予。',
          style: TextStyle(fontSize: 10.5, height: 1.6, color: t.text3),
        ),
      ],
    );
  }
}

/* ============================================================
   社区设置
   ============================================================ */

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({required this.bottomInset});

  final double bottomInset;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late final TextEditingController _about;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final app = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
    _about = TextEditingController(text: app.store.aboutText);
  }

  @override
  void dispose() {
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.store.updateSettings(_about.text.trim());
      if (!mounted) return;
      setState(() => _saving = false);
      app.toast('关于文案已更新', type: ToastType.success);
    } on StoreException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      app.toast(e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 34 + widget.bottomInset),
      children: [
        Text(
          '关于乌市职专墙',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.text),
        ),
        const SizedBox(height: 4),
        Text(
          '这段文案会显示在「我的 → 关于乌市职专墙」。',
          style: TextStyle(fontSize: 11, color: t.text3),
        ),
        const SizedBox(height: 12),
        QTextArea(
          controller: _about,
          hint: '写一段社区介绍…',
          maxLength: 2000,
          minHeight: 220,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.field,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 17, color: t.text3),
              const SizedBox(width: 8),
              Text('当前版本：${store.version}（固定）', style: TextStyle(fontSize: 11.5, color: t.text2)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        QButton(
          label: _saving ? '保存中…' : '保存设置',
          icon: Icons.check_rounded,
          onTap: _saving ? null : _save,
        ),
      ],
    );
  }
}

/* ============================================================
   贴吧管理
   ============================================================ */

class _BarsTab extends StatelessWidget {
  const _BarsTab({required this.bottomInset, required this.onNewBar});

  final double bottomInset;
  final VoidCallback onNewBar;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final mods = store.modules;

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 34 + bottomInset),
      children: [
        Text(
          '新增、改名或删除贴吧。删除贴吧会同时下架该吧内的所有帖子。',
          style: TextStyle(fontSize: 11, height: 1.6, color: t.text3),
        ),
        const SizedBox(height: 6),
        for (final mod in mods) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: t.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${mod.label} · ${store.bars(mod.key).length}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .8,
                    color: t.text3,
                  ),
                ),
              ],
            ),
          ),
          for (final bar in store.bars(mod.key))
            Container(
              padding: const EdgeInsets.all(13),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: t.border),
                boxShadow: t.cardShadow,
              ),
              child: Row(
                children: [
                  QBarIcon(
                    icon: qIcon(bar.icon),
                    color: mod.color,
                    size: 40,
                    iconSize: 19,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bar.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bar.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: t.text3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${store.countPosts(bar.id)} 帖子 · ${store.memberCount(bar.id)} 位同学',
                          style: TextStyle(fontSize: 10, color: t.text3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RowIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => _editBar(context, bar),
                  ),
                  const SizedBox(width: 6),
                  _RowIconButton(
                    icon: Icons.delete_outline_rounded,
                    danger: true,
                    onTap: () => _deleteBar(context, bar),
                  ),
                ],
              ),
            ),
          if (store.bars(mod.key).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '该模块下还没有贴吧',
                style: TextStyle(fontSize: 11.5, color: t.text3),
              ),
            ),
        ],
        const SizedBox(height: 12),
        QButton(
          label: '新建贴吧',
          icon: Icons.add_rounded,
          height: 46,
          onTap: onNewBar,
        ),
      ],
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .93,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: danger ? t.dangerSoft : t.field,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 15, color: danger ? t.danger : t.text2),
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  const _TinyButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .95,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: danger ? t.dangerSoft : t.field,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: danger ? Colors.transparent : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: danger ? t.danger : t.text2),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: danger ? t.danger : t.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   贴吧操作
   ============================================================ */

Future<void> _newBar(BuildContext context) async {
  final app = AppScope.of(context);
  final data = await showQForm(
    context,
    title: '新建贴吧',
    desc: '填写贴吧名称和介绍即可创建。',
    fields: const [
      QFormFieldSpec(
        name: 'name',
        label: '贴吧名称',
        hint: '例如：二手交易吧',
        minLength: 2,
        maxLength: 12,
      ),
      QFormFieldSpec(
        name: 'desc',
        label: '一句介绍',
        hint: '这个贴吧是做什么的？',
        required: false,
        maxLength: 30,
      ),
    ],
    confirmText: '创建',
  );
  if (data == null || !context.mounted) return;
  try {
    await app.store.addBar(
      name: data['name'] ?? '',
      desc: data['desc'],
    );
    app.toast('贴吧已创建', type: ToastType.success);
  } on StoreException catch (e) {
    app.toast(e.message, type: ToastType.error);
  }
}

Future<void> _editBar(BuildContext context, DiscussionBar bar) async {
  final app = AppScope.of(context);
  final data = await showQForm(
    context,
    title: '编辑贴吧',
    desc: '可以修改贴吧名称和介绍。',
    fields: [
      QFormFieldSpec(
        name: 'name',
        label: '贴吧名称',
        initialValue: bar.name,
        minLength: 2,
        maxLength: 12,
      ),
      QFormFieldSpec(
        name: 'desc',
        label: '一句介绍',
        initialValue: bar.desc,
        required: false,
        maxLength: 30,
      ),
    ],
    confirmText: '保存',
  );
  if (data == null || !context.mounted) return;
  try {
    await app.store.updateBar(
      bar.id,
      name: data['name'] ?? bar.name,
      desc: data['desc'],
    );
    app.toast('贴吧信息已更新', type: ToastType.success);
  } on StoreException catch (e) {
    app.toast(e.message, type: ToastType.error);
  }
}

Future<void> _deleteBar(BuildContext context, DiscussionBar bar) async {
  final app = AppScope.of(context);
  final count = app.store.countPosts(bar.id);
  final ok = await showQConfirm(
    context,
    title: '删除「${bar.name}」？',
    desc: '该贴吧下的 $count 条帖子会一并下架，此操作不可恢复。',
    confirmText: '删除贴吧',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  try {
    await app.store.deleteBar(bar.id);
    app.toast('贴吧已删除', type: ToastType.success);
  } on StoreException catch (e) {
    app.toast(e.message, type: ToastType.error);
  }
}
