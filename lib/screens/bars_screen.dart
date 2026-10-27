import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class BarsScreen extends StatelessWidget {
  const BarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final filter = app.barsFilter;
    final mods = store.modules;
    final list = store.bars(filter);

    return Column(
      children: [
        QTopBar(
          title: '贴吧广场',
          actions: [
            QIconButton(
              icon: Icons.search_rounded,
              onTap: () => app.navigate(AppRoute.search),
              iconSize: 19,
            ),
          ],
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              QChip(
                label: '全部',
                active: filter == 'all',
                onTap: () => app.setBarsFilter('all'),
              ),
              for (final mod in mods) ...[
                const SizedBox(width: 8),
                QChip(
                  label: mod.name,
                  icon: qIcon(mod.icon),
                  active: filter == mod.key,
                  onTap: () => app.setBarsFilter(mod.key),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 112 + bottomInset),
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(height: 11),
                QBarRow(
                  bar: list[i],
                  onTap: () => app.navigate(AppRoute.bar(list[i].id)),
                ),
              ],
              if (list.isEmpty)
                const QEmptyState(
                  icon: Icons.explore_outlined,
                  title: '这个分类还没有贴吧',
                  desc: '管理员可以在后台创建新的贴吧',
                ),
              const SizedBox(height: 20),
              Text(
                '共 ${store.bars().length} 个贴吧 · 由管理员统一维护',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: t.text3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
