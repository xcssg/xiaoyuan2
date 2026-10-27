import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _comment = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _comment.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = AppScope.of(context);
    final text = _comment.text.trim();
    if (text.isEmpty) {
      app.toast('评论内容不能为空', type: ToastType.error);
      return;
    }
    try {
      await app.store.addComment(widget.postId, text);
      if (!mounted) return;
      _comment.clear();
      app.toast('评论成功', type: ToastType.success);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      });
    } on StoreException catch (e) {
      if (!mounted) return;
      app.toast(e.message, type: ToastType.error);
    }
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
      if (!mounted) return;
      app.pop();
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
    final post = store.post(widget.postId);

    if (post == null) {
      return Column(
        children: [
          QTopBar(
            title: '帖子详情',
            large: false,
            leading: QIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: app.pop,
            ),
          ),
          const Expanded(
            child: QEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: '内容不存在或已被删除',
              desc: '回到贴吧看看其他帖子吧',
            ),
          ),
        ],
      );
    }

    final bar = store.bar(post.barId);
    final mod = store.moduleOf(bar?.module ?? 'lost');
    final author = store.getUser(post.authorId);
    final me = store.current;
    final isAdmin = store.isAdmin;
    final liked = store.isLiked(post.id);
    final canDelete = me != null && (me.isAdmin || post.authorId == me.id);
    final displayName = post.anonymous ? '匿名同学' : (author?.nickname ?? '已注销用户');
    final authorNameColor = post.anonymous ? null : parseHexColor(author?.nameColor ?? '');
    final comments = List<PostComment>.from(post.comments)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomPad = keyboard
        ? 10.0
        : MediaQuery.viewPaddingOf(context).bottom + 10;

    return Column(
      children: [
        QTopBar(
          title: '帖子详情',
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
          actions: [
            if (canDelete)
              QIconButton(
                icon: Icons.delete_outline_rounded,
                color: t.danger,
                onTap: () => _delete(post),
              ),
          ],
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border),
                  boxShadow: t.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        QAvatar(
                          user: author,
                          size: 44,
                          anonymous: post.anonymous,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: authorNameColor ?? t.text,
                                      ),
                                    ),
                                  ),
                                  if (post.anonymous) ...[
                                    const SizedBox(width: 5),
                                    const QPill(text: '匿名', style: QPillStyle.soft),
                                  ],
                                  if (author?.banned == true) ...[
                                    const SizedBox(width: 5),
                                    const QPill(text: '已封禁', style: QPillStyle.danger),
                                  ],
                                  if (!post.anonymous && author != null && author.title.isNotEmpty) ...[
                                    const SizedBox(width: 5),
                                    QTitleBadge(
                                      title: author.title,
                                      granted: author.grantedTitle.isNotEmpty &&
                                          author.title == author.grantedTitle,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    timeAgo(post.createdAt),
                                    style: TextStyle(fontSize: 10.5, color: t.text3),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 2,
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: t.text3,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      bar?.name ?? '未知贴吧',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10.5, color: t.text3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: mod.color.withOpacity(.10),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            mod.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: mod.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.42,
                        letterSpacing: -.4,
                        color: t.text,
                      ),
                    ),
                    if (isAdmin && post.anonymous && author != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: t.warn.withOpacity(.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '匿名帖 · 发帖人：${author.nickname} (@${author.username})',
                          style: TextStyle(fontSize: 10.5, color: t.warn),
                        ),
                      ),
                    ],
                    if (post.status != 'approved') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                        decoration: BoxDecoration(
                          color: (post.status == 'pending' ? t.warn : t.danger).withOpacity(.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          post.status == 'pending'
                              ? '帖子正在等待管理员审核，通过后会展示给其他同学'
                              : '帖子未通过审核：${post.rejectReason.isEmpty ? '内容不符合社区规范' : post.rejectReason}',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: post.status == 'pending' ? t.warn : t.danger,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      post.content,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.85,
                        color: t.text,
                      ),
                    ),
                    if (post.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          qImageUrl(post.imageUrl),
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        QPill(
                          text: mod.label,
                          icon: Icons.sell_outlined,
                        ),
                        if (bar != null)
                          QPill(text: bar.name, style: QPillStyle.soft),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: t.line),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            label: '${liked ? '已赞' : '点赞'} ${post.likes}',
                            active: liked,
                            onTap: () async {
                              try {
                                await store.toggleLike(post.id);
                              } on StoreException catch (e) {
                                app.toast(e.message, type: ToastType.error);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '评论 ${post.comments.length}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.send_rounded,
                            label: '分享',
                            onTap: () => app.toast('分享链接已复制', type: ToastType.success),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '全部评论',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${post.comments.length}',
                    style: TextStyle(fontSize: 11, color: t.text3),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (comments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: t.border),
                  ),
                  child: Text(
                    '还没有评论，来说点什么吧',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: t.text3),
                  ),
                )
              else
                for (final comment in comments) ...[
                  _CommentTile(comment: comment),
                  const SizedBox(height: 9),
                ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPad),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 58,
                padding: const EdgeInsets.only(left: 16, right: 10),
                decoration: BoxDecoration(
                  color: t.glass,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: t.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: t.dark
                          ? Colors.black.withOpacity(.45)
                          : const Color(0x2914326E),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        maxLength: 200,
                        style: TextStyle(fontSize: 13.5, color: t.text),
                        cursorColor: t.brand,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          counterText: '',
                          hintText: '友善评论，让校园更温暖',
                          hintStyle: TextStyle(fontSize: 13.5, color: t.text3),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Pressable(
                      onTap: _send,
                      scale: .94,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: t.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: t.brand.withOpacity(.32),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? t.dangerSoft : t.field,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? t.danger : t.text2),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: active ? t.danger : t.text2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final t = QColors.of(context);
    final user = store.getUser(comment.authorId);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QAvatar(user: user, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.nickname ?? '已注销用户',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: parseHexColor(user?.nameColor ?? '') ?? t.text,
                        ),
                      ),
                    ),
                    if (user != null && user.title.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      QTitleBadge(
                        title: user.title,
                        granted: user.grantedTitle.isNotEmpty &&
                            user.title == user.grantedTitle,
                      ),
                    ],
                    const SizedBox(width: 7),
                    Text(
                      timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: t.text3),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: t.text2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
