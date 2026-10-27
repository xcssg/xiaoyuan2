import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final app = AppScope.of(context);
    final ok = await showQConfirm(
      context,
      title: '退出登录？',
      desc: '退出后需要重新输入账号密码才能发布内容。',
      confirmText: '退出登录',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await app.store.logout();
    if (!context.mounted) return;
    app.reset(AppRoute.auth);
    app.toast('已退出登录');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final u = store.current;
    if (u == null) return const SizedBox.shrink();
    final myPosts = store.myPosts(u.id);
    final likes = store.myLikes(u.id);
    final days = daysSince(u.joinedAt);
    final theme = app.isDark;
    final titleColor = parseHexColor(u.nameColor) ?? t.text;
    final doneTasks = store.tasks.where((task) => task.claimed).length;
    final ownedItems = store.shopItems.where((item) => item.owned).length;

    return Column(
      children: [
        QTopBar(
          title: '我的',
          actions: [
            QIconButton(
              icon: theme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              onTap: app.toggleTheme,
              iconSize: 19,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 112 + bottomInset),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: t.border),
                  boxShadow: t.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -70,
                        top: -90,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF5B9BFF).withOpacity(.35),
                                const Color(0xFF5B9BFF).withOpacity(0),
                              ],
                              stops: const [0, .7],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                QAvatar(user: u, size: 58),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              u.nickname.isEmpty ? '@${u.username}' : u.nickname,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                                color: titleColor,
                                                letterSpacing: -.4,
                                              ),
                                            ),
                                          ),
                                          if (u.title.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            QTitleBadge(
                                              title: u.title,
                                              granted: u.grantedTitle.isNotEmpty &&
                                                  u.title == u.grantedTitle,
                                            ),
                                          ],
                                          if (u.isAdmin) ...[
                                            const SizedBox(width: 7),
                                            const QPill(
                                              text: '管理员',
                                              icon: Icons.shield_outlined,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '@${u.username} · 加入 $days 天',
                                        style: TextStyle(fontSize: 11.5, color: t.text3),
                                      ),
                                      if (u.className.isNotEmpty || u.realName.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(Icons.school_outlined, size: 12, color: t.text3),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '${u.className}${u.className.isNotEmpty && u.realName.isNotEmpty ? ' · ' : ''}${u.realName}${u.showProfile ? '' : ' · 仅自己可见'}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11, color: t.text2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Pressable(
                                  onTap: () => app.navigate(AppRoute.editProfile),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: t.brand.withOpacity(.10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit_outlined, size: 16, color: t.brand),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              u.bio.isEmpty ? '这位同学还没有写简介' : u.bio,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.6,
                                color: t.text2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: t.line),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _ProfileStat(value: '${myPosts.length}', label: '发帖'),
                                Container(width: 1, height: 30, color: t.line),
                                _ProfileStat(value: '$likes', label: '获赞'),
                                Container(width: 1, height: 30, color: t.line),
                                _ProfileStat(value: '${u.points}', label: '积分'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (u.isAdmin) ...[
                const SizedBox(height: 14),
                Pressable(
                  onTap: () => app.navigate(AppRoute.admin()),
                  scale: .98,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: t.adminGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2352BE).withOpacity(.34),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '管理员后台',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '内容审核 · 用户管理 · 贴吧维护',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white.withOpacity(.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.white.withOpacity(.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _GrowthCard(
                points: u.points,
                doneTasks: doneTasks,
                totalTasks: store.tasks.length,
                ownedItems: ownedItems,
                onTasks: () => app.navigate(AppRoute.tasks),
                onShop: () => app.navigate(AppRoute.shop),
              ),
              QSectionHead(
                title: '我的帖子',
                trailing: Text(
                  '${myPosts.length} 条',
                  style: TextStyle(fontSize: 12, color: t.text3),
                ),
              ),
              if (myPosts.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: t.border),
                  ),
                  child: Text(
                    '还没有发布过帖子',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: t.text3),
                  ),
                )
              else
                for (var i = 0; i < myPosts.take(3).length; i++) ...[
                  QPostCard(
                    post: myPosts[i],
                    onTap: () => app.navigate(AppRoute.post(myPosts[i].id)),
                  ),
                  if (i < 2) const SizedBox(height: 11),
                ],
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: t.border),
                  boxShadow: t.cardShadow,
                ),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: Icons.manage_accounts_outlined,
                      title: '编辑资料',
                      subtitle: '头像 · 昵称 · 班级 · 装扮',
                      onTap: () => app.navigate(AppRoute.editProfile),
                    ),
                    _MenuRow(
                      icon: Icons.info_outline_rounded,
                      title: '关于乌市职专墙',
                      subtitle: '版本 ${store.version}',
                      color: t.warn,
                      onTap: () => showQDialog(
                        context,
                        title: '关于乌市职专墙',
                        desc: '${store.aboutText}\n\n${store.version} · UVSS',
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.logout_rounded,
                      title: '退出登录',
                      subtitle: '退出当前账号',
                      color: t.danger,
                      dangerText: true,
                      last: true,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '乌市职专墙 UVSS · ${store.version}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: t.text3,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.points,
    required this.doneTasks,
    required this.totalTasks,
    required this.ownedItems,
    required this.onTasks,
    required this.onShop,
  });

  final int points;
  final int doneTasks;
  final int totalTasks;
  final int ownedItems;
  final VoidCallback onTasks;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: t.brandGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: t.brandShadow,
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '成长中心',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '完成任务赚积分，兑换头像框、昵称颜色和称号',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: t.text3),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$points',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: t.brand,
                      letterSpacing: -.5,
                    ),
                  ),
                  Text('积分', style: TextStyle(fontSize: 10, color: t.text3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GrowthButton(
                  icon: Icons.task_alt_rounded,
                  title: '每日任务',
                  subtitle: totalTasks == 0 ? '暂无任务' : '$doneTasks / $totalTasks 已完成',
                  onTap: onTasks,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _GrowthButton(
                  icon: Icons.storefront_outlined,
                  title: '积分商店',
                  subtitle: '已拥有 $ownedItems 件装扮',
                  onTap: onShop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthButton extends StatelessWidget {
  const _GrowthButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .97,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.field,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: t.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: t.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: t.text3),
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: t.text3),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
    this.dangerText = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool dangerText;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final c = color ?? t.brand;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.withOpacity(.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: dangerText ? t.danger : t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10.5, color: t.text3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 17, color: t.text3),
          ],
        ),
      ),
    );
  }
}
