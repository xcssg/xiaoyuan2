import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final Set<String> _claiming = {};

  Future<void> _claim(DailyTask task) async {
    if (_claiming.contains(task.id)) return;
    final app = AppScope.of(context);
    setState(() => _claiming.add(task.id));
    try {
      await app.store.claimTask(task.id);
      if (!mounted) return;
      app.toast('领取成功，+${task.points} 积分', type: ToastType.success);
    } on StoreException catch (e) {
      if (!mounted) return;
      app.toast(e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _claiming.remove(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final tasks = store.tasks;
    final points = store.current?.points ?? 0;
    final done = tasks.where((task) => task.claimed).length;

    return Column(
      children: [
        QTopBar(
          title: '任务中心',
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
          actions: [
            QPill(text: '$points 积分', icon: Icons.stars_rounded),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 28 + bottomInset),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: t.adminGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2352BE).withOpacity(.30),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '积分',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(.8),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '今日 $done / ${tasks.length}',
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '完成任务获取积分，兑换头像框、昵称颜色和专属装扮。',
                      style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(.72)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '每日 0 点刷新',
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(.55)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (tasks.isEmpty)
                const QEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: '今天还没有任务',
                  desc: '管理员添加任务后会显示在这里',
                )
              else
                for (final task in tasks) ...[
                  _TaskRow(
                    task: task,
                    claiming: _claiming.contains(task.id),
                    onClaim: () => _claim(task),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 8),
              Text(
                '自动任务在完成对应操作后立即发放积分；打卡任务需要手动领取。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, height: 1.6, color: t.text3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.claiming,
    required this.onClaim,
  });

  final DailyTask task;
  final bool claiming;
  final VoidCallback onClaim;

  IconData get _icon {
    switch (task.type) {
      case 'login':
        return Icons.wb_sunny_outlined;
      case 'post':
        return Icons.edit_outlined;
      case 'comment':
        return Icons.chat_bubble_outline_rounded;
      case 'like':
        return Icons.favorite_border_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  String get _typeLabel {
    switch (task.type) {
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

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final manual = task.type == 'manual';
    return QCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.brand.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_icon, size: 19, color: t.brand),
          ),
          const SizedBox(width: 11),
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
                    QPill(text: _typeLabel, style: QPillStyle.soft),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: t.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (task.completed)
            QPill(text: '+${task.points} 已完成', style: QPillStyle.ok)
          else if (manual)
            Pressable(
              onTap: claiming ? null : onClaim,
              scale: .95,
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  gradient: t.brandGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    claiming ? '领取中' : '领取 +${task.points}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            QPill(text: '+${task.points} 未完成', style: QPillStyle.soft),
        ],
      ),
    );
  }
}
