import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class BarScreen extends StatelessWidget {
  const BarScreen({super.key, required this.barId});

  final String barId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bar = store.bar(barId);

    if (bar == null) {
      return Column(
        children: [
          QTopBar(
            title: '贴吧',
            large: false,
            leading: QIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: app.pop,
            ),
          ),
          const Expanded(
            child: QEmptyState(
              icon: Icons.explore_outlined,
              title: '贴吧不存在',
              desc: '该贴吧可能已被管理员删除',
            ),
          ),
        ],
      );
    }

    final mod = store.moduleOf(bar.module);
    final sort = app.barSort;
    final list = store.posts(barId: barId, sort: sort);

    return Column(
      children: [
        QTopBar(
          title: bar.name,
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
          actions: [
            QIconButton(
              icon: Icons.search_rounded,
              onTap: () => app.navigate(AppRoute.search),
              iconSize: 19,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 112 + bottomInset),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border),
                  boxShadow: t.cardShadow,
                ),
                child: Row(
                  children: [
                    QBarIcon(
                      icon: qIcon(bar.icon),
                      color: mod.color,
                      size: 54,
                      iconSize: 25,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bar.name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: t.text,
                              letterSpacing: -.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bar.desc,
                            style: TextStyle(fontSize: 11.5, color: t.text3),
                          ),
                          const SizedBox(height: 7),
                          QPill(
                            text: '${store.countPosts(bar.id)} 条帖子 · ${bar.members} 位成员',
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
                    child: QSeg(
                      options: const [
                        QSegOption('new', '最新'),
                        QSegOption('hot', '最热'),
                      ],
                      value: sort,
                      onChanged: app.setBarSort,
                    ),
                  ),
                  const SizedBox(width: 8),
                  QPill(text: '${list.length} 条', style: QPillStyle.soft),
                ],
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                QEmptyState(
                  icon: Icons.edit_outlined,
                  title: '这里还很安静',
                  desc: '成为第一个发帖的同学吧',
                  action: SizedBox(
                    width: 132,
                    child: QButton(
                      label: '发第一帖',
                      height: 38,
                      onTap: () => app.navigate(AppRoute.composeTo(bar.id)),
                    ),
                  ),
                )
              else
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0) const SizedBox(height: 11),
                  QPostCard(
                    post: list[i],
                    onTap: () => app.navigate(AppRoute.post(list[i].id)),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
