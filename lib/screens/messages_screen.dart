import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final list = store.messages();
    final unread = store.unreadCount;

    return Column(
      children: [
        QTopBar(
          title: '消息',
          actions: [
            if (unread > 0)
              QTextButton(
                label: '全部已读',
                onTap: () async {
                  try {
                    await store.markAllRead();
                    app.toast('已全部标记为已读', type: ToastType.success);
                  } on StoreException catch (e) {
                    app.toast(e.message, type: ToastType.error);
                  }
                },
              )
            else
              const QPill(text: '已读', style: QPillStyle.ok),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 112 + bottomInset),
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _MessageRow(
                  message: list[i],
                  onTap: () async {
                    try {
                      await store.markRead(list[i].id);
                    } on StoreException catch (e) {
                      app.toast(e.message, type: ToastType.error);
                    }
                  },
                ),
              ],
              const SizedBox(height: 18),
              Text(
                '消息中心',
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

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.onTap});

  final AppMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final isLike = message.type == 'like';
    final isSystem = message.type == 'system';
    final color = isLike
        ? const Color(0xFFEC4899)
        : isSystem
            ? t.warn
            : t.brand;
    final icon = isLike
        ? Icons.favorite_border_rounded
        : isSystem
            ? Icons.notifications_none_rounded
            : Icons.chat_bubble_outline_rounded;

    return Pressable(
      onTap: onTap,
      scale: .985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                      ),
                      if (isSystem) ...[
                        const SizedBox(width: 6),
                        const QPill(text: '系统', style: QPillStyle.soft),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: t.text2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo(message.createdAt),
                    style: TextStyle(fontSize: 10.5, color: t.text3),
                  ),
                ],
              ),
            ),
            if (message.unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: t.brand,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: t.brand.withOpacity(.14),
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
