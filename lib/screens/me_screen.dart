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

  void _accountInfo(BuildContext context) {
    final app = AppScope.of(context);
    final u = app.store.current;
    if (u == null) return;
    final days = daysSince(u.joinedAt);
    showQDialog(
      context,
      title: '账号信息',
      content: Column(
        children: [
          _InfoRow(label: '昵称', value: u.nickname),
          _InfoRow(label: '账号', value: u.username),
          _InfoRow(label: '身份', value: u.isAdmin ? '管理员' : '学生用户'),
          _InfoRow(label: '加入时间', value: '${dateStr(u.joinedAt)}（$days 天）'),
          _InfoRow(label: '账号状态', value: u.banned ? '已封禁' : '正常'),
        ],
      ),
    );
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
                                              u.nickname,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                                color: t.text,
                                                letterSpacing: -.4,
                                              ),
                                            ),
                                          ),
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
                                    ],
                                  ),
                                ),
                                QPill(
                                  text: u.online ? '在线' : '离线',
                                  style: u.online ? QPillStyle.ok : QPillStyle.soft,
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
                                _ProfileStat(value: '$days', label: '加入天数'),
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
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '外观主题',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '白天 / 夜晚',
                          style: TextStyle(fontSize: 10.5, color: t.text3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeCard(
                            night: false,
                            active: !theme,
                            title: '白天模式',
                            desc: '蓝白 · 清爽明亮',
                            onTap: () => app.setDark(false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ThemeCard(
                            night: true,
                            active: theme,
                            title: '夜晚模式',
                            desc: '黑灰 · 低光护眼',
                            onTap: () => app.setDark(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      icon: Icons.person_outline_rounded,
                      title: '账号信息',
                      subtitle: '查看账号与权限详情',
                      onTap: () => _accountInfo(context),
                    ),
                    _MenuRow(
                      icon: Icons.info_outline_rounded,
                      title: '关于乌市职专墙',
                      subtitle: '版本 0.1',
                      color: t.warn,
                      onTap: () => showQDialog(
                        context,
                        title: '关于乌市职专墙',
                        desc: '乌市职专墙是面向校园的互助社区，包含寻物、吐槽、表白、找人四个模块。\n\n当前为联网版本，账号与内容保存在学校社区服务器。\n\nVERSION 0.1 · CAMPUS WALL',
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
                '乌市职专墙 CAMPUS WALL · V0.1',
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: t.text3),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.night,
    required this.active,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final bool night;
  final bool active;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? t.brand.withOpacity(.07) : t.field,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: active ? t.brand : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: night
                      ? const [Color(0xFF12151C), Color(0xFF1E222C)]
                      : const [Color(0xFFF2F7FF), Color(0xFFDCEAFF)],
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.black.withOpacity(.06)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 10,
                    height: 9,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: .46,
                      child: _PreviewBar(night: night, opacity: .22),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 25,
                    height: 9,
                    child: _PreviewBar(night: night),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 40,
                    height: 9,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: .62,
                      child: _PreviewBar(night: night, opacity: .12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
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

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.night, this.opacity = 0});

  final bool night;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final base = night ? Colors.white : const Color(0xFF2F6BFF);
    return Container(
      decoration: BoxDecoration(
        color: base.withOpacity(opacity > 0 ? opacity : (night ? .16 : .22)),
        borderRadius: BorderRadius.circular(5),
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
