import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final value = (_scroll.hasClients ? _scroll.offset : 0) / 64;
    final progress = value.clamp(0.0, 1.0);
    if ((progress - _progress).abs() > .01) {
      setState(() => _progress = progress);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openAnnouncement(BuildContext context, Announcement item) async {
    final app = AppScope.of(context);
    showQDialog(
      context,
      title: item.title,
      desc: item.content,
      confirmText: '知道了',
    );
    try {
      await app.store.markAnnouncementRead(item.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final user = store.current;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    if (user == null) return const SizedBox.shrink();
    final unread = store.unreadCount;
    final mods = store.modules.where((m) => m.key != 'general').toList();
    final hot = store.posts(sort: 'hot', limit: 10);
    final announcement = store.latestAnnouncement;
    final people = store.users().where((u) => !u.banned).length;

    return Column(
      children: [
        Container(
          color: t.bgTop.withOpacity(.94),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Row(
            children: [
              Expanded(
                child: IgnorePointer(
                  ignoring: _progress > .95,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [Colors.white, Colors.transparent],
                      stops: [(1 - _progress).clamp(0.0, .999), 1],
                    ).createShader(rect),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${greeting()}，${user.nickname}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: t.text2, letterSpacing: .2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '乌市职专墙',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -.4,
                            color: t.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              QIconButton(
                icon: app.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                onTap: app.toggleTheme,
                iconSize: 19,
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () => app.navigate(AppRoute.me),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    QAvatar(user: user, size: 38),
                    if (unread > 0)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: t.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.bg, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(18, 4, 18, 112 + bottomInset),
            children: [
              Pressable(
                onTap: () => app.navigate(AppRoute.search),
                child: _SearchBar(),
              ),
              const SizedBox(height: 16),
              _HeroCard(
                people: people,
                onCreate: () => app.navigate(AppRoute.compose),
              ),
              if (announcement != null) ...[
                const SizedBox(height: 12),
                Pressable(
                  onTap: () => _openAnnouncement(context, announcement),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: (announcement.important ? t.danger : t.brand).withOpacity(.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            announcement.important ? '重要' : '公告',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: announcement.important ? t.danger : t.brand,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            announcement.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: t.text2),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 15, color: t.text3),
                      ],
                    ),
                  ),
                ),
              ],
              QSectionHead(
                title: '校园四大板块',
                trailing: Text(
                  '${mods.length} 个模块',
                  style: TextStyle(fontSize: 12, color: t.text3),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final mod in mods)
                    _ModuleCard(
                      moduleKey: mod.key,
                      onTap: () {
                        final list = store.bars(mod.key);
                        app.navigate(list.isEmpty ? AppRoute.bars : AppRoute.bar(list.first.id));
                      },
                    ),
                ],
              ),
              QSectionHead(
                title: '正在热聊',
                trailing: Pressable(
                  onTap: () => app.navigate(AppRoute.bars),
                  child: Row(
                    children: [
                      Text('全部贴吧', style: TextStyle(fontSize: 12, color: t.text3)),
                      Icon(Icons.chevron_right_rounded, size: 14, color: t.text3),
                    ],
                  ),
                ),
              ),
              if (hot.isEmpty)
                QCard(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 28, color: t.text3),
                      const SizedBox(height: 8),
                      Text(
                        '还没有帖子',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text2),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '成为第一个发帖的同学吧',
                        style: TextStyle(fontSize: 11, color: t.text3),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 132,
                        child: QButton(
                          label: '去发帖',
                          height: 36,
                          onTap: () => app.navigate(AppRoute.compose),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < hot.length; i++) ...[
                  if (i > 0) const SizedBox(height: 11),
                  QPostCard(
                    post: hot[i],
                    onTap: () => app.navigate(AppRoute.post(hot[i].id)),
                  ),
                ],
              const SizedBox(height: 22),
              Text(
                '— 乌市职专墙 · 让校园更近一点 —',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: t.text3, letterSpacing: .8),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: t.text3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '搜索帖子、失物、同学',
              style: TextStyle(fontSize: 13.5, color: t.text3),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'SEARCH',
              style: TextStyle(
                fontSize: 10,
                color: t.text3,
                letterSpacing: .6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.people, required this.onCreate});

  final int people;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: t.brand.withOpacity(.28),
            blurRadius: 38,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(gradient: t.hero),
          child: Stack(
            children: [
              Positioned(
                right: -72,
                top: -86,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(.26)),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: -74,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 23,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'UVSS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .6,
                              color: Colors.white.withOpacity(.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '丢失的会回来，\n心动的会被看见。',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.7,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '已有 $people 位同学在乌市职专墙互相帮忙',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Pressable(
                      onTap: onCreate,
                      scale: .96,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A286E).withOpacity(.22),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 15, color: Color(0xFF1B4ED6)),
                            SizedBox(width: 6),
                            Text(
                              '发布一条',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B4ED6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.moduleKey, required this.onTap});

  final String moduleKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final store = AppScope.of(context).store;
    final mod = store.moduleOf(moduleKey);
    final posts = store.countModule(mod.key);
    final members = store
        .bars(mod.key)
        .fold<int>(0, (sum, item) => sum + store.memberCount(item.id));

    return Pressable(
      onTap: onTap,
      scale: .975,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -36,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mod.color.withOpacity(.20),
                      mod.color.withOpacity(0),
                    ],
                    stops: const [0, .72],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: mod.color.withOpacity(.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(qIcon(mod.icon), size: 19, color: mod.color),
                  ),
                  const Spacer(),
                  Text(
                    mod.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                      letterSpacing: -.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ModuleMetric(value: '$posts', label: '帖子'),
                      Container(
                        width: 1,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 9),
                        color: t.line,
                      ),
                      _ModuleMetric(value: '$members', label: '同学'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleMetric extends StatelessWidget {
  const _ModuleMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: t.text,
            height: 1,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: t.text3, height: 1),
        ),
      ],
    );
  }
}
