import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final user = store.current;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final unread = store.unreadCount;
    final mods = store.modules;
    final hot = store.posts(sort: 'hot', limit: 4);

    return Column(
      children: [
        QTopBar(
          subtitle: '${greeting()}，${user.nickname}',
          title: '乌市职专墙',
          actions: [
            QIconButton(
              icon: app.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              onTap: app.toggleTheme,
              iconSize: 19,
            ),
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 4, 18, 112 + bottomInset),
            children: [
              Pressable(
                onTap: () => app.navigate(AppRoute.search),
                child: _SearchBar(),
              ),
              const SizedBox(height: 16),
              _HeroCard(
                onCreate: () => app.navigate(AppRoute.compose),
              ),
              const SizedBox(height: 12),
              Pressable(
                onTap: () => app.navigate(AppRoute.post('p10')),
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
                          color: t.brand.withOpacity(.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '公告',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: t.brand,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '失物招领处已搬迁至学生活动中心 105 室',
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
                childAspectRatio: 1.32,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final mod in mods)
                    _ModuleCard(
                      moduleKey: mod.key,
                      onTap: () {
                        final list = store.bars(mod.key);
                        app.navigate(list.isEmpty
                            ? AppRoute.bars
                            : AppRoute.bar(list.first.id));
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
                      Text(
                        '全部贴吧',
                        style: TextStyle(fontSize: 12, color: t.text3),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: t.text3),
                    ],
                  ),
                ),
              ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: t.text3,
                  letterSpacing: .8,
                ),
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
  const _HeroCard({required this.onCreate});

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
                            'CAMPUS WALL',
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
                      '已有 1,286 位同学在乌市职专墙互相帮忙',
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
    final bars = store.bars(moduleKey);
    final members = bars.isEmpty ? 0 : bars.first.members;
    return Pressable(
      onTap: onTap,
      scale: .975,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -30,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mod.color.withOpacity(.13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mod.color.withOpacity(.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(qIcon(mod.icon), size: 21, color: mod.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mod.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                      letterSpacing: -.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${store.countModule(mod.key)} 条帖子 · $members 成员',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: t.text3),
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
