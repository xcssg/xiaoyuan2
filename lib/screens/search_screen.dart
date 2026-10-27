import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    final app = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
    _q = app.searchQuery.trim();
    _controller.text = _q;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    final app = AppScope.of(context);
    final query = value.trim();
    app.searchQuery = query;
    setState(() => _q = query);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final q = _q;
    final List<Post> posts = q.isEmpty ? <Post>[] : store.posts(q: q);
    final List<AppUser> users = q.isEmpty ? <AppUser>[] : store.searchUsers(q);

    return Column(
      children: [
        QTopBar(
          title: '搜索',
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 4, 18, 112 + bottomInset),
            children: [
              Row(
                children: [
                  Expanded(
                    child: QSearchField(
                      controller: _controller,
                      hint: '搜索帖子、失物、同学',
                      height: 44,
                      onSubmitted: _search,
                    ),
                  ),
                  const SizedBox(width: 9),
                  QIconButton(
                    icon: Icons.arrow_forward_rounded,
                    accent: true,
                    size: 44,
                    iconSize: 19,
                    onTap: () => _search(_controller.text),
                  ),
                ],
              ),
              if (q.isEmpty) ...[
                _ResultLabel(text: '大家都在搜'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in ['AirPods', '图书馆', '组队', '校园卡', '番茄炒蛋'])
                      QChip(
                        label: s,
                        icon: Icons.search_rounded,
                        onTap: () {
                          _controller.text = s;
                          _search(s);
                        },
                      ),
                  ],
                ),
                const QSectionHead(title: '热门帖子'),
                for (final post in store.posts(sort: 'hot', limit: 3)) ...[
                  QPostCard(
                    post: post,
                    onTap: () => app.navigate(AppRoute.post(post.id)),
                  ),
                  const SizedBox(height: 11),
                ],
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 9),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '找到 '),
                        TextSpan(
                          text: '${posts.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        const TextSpan(text: ' 条帖子 · '),
                        TextSpan(
                          text: '${users.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        const TextSpan(text: ' 位同学'),
                      ],
                    ),
                    style: TextStyle(fontSize: 11.5, color: t.text3),
                  ),
                ),
                for (final post in posts) ...[
                  QPostCard(
                    post: post,
                    onTap: () => app.navigate(AppRoute.post(post.id)),
                  ),
                  const SizedBox(height: 11),
                ],
                if (users.isNotEmpty) _ResultLabel(text: '相关同学'),
                for (final user in users) ...[
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
                        QAvatar(user: user, size: 40),
                        const SizedBox(width: 11),
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
                                        color: t.text,
                                      ),
                                    ),
                                  ),
                                  if (user.isAdmin) ...[
                                    const SizedBox(width: 5),
                                    const QPill(text: '管理员'),
                                  ],
                                  if (user.banned) ...[
                                    const SizedBox(width: 5),
                                    const QPill(text: '已封禁', style: QPillStyle.danger),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${user.username} · ${user.bio}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10.5, color: t.text3),
                              ),
                            ],
                          ),
                        ),
                        if (user.online && !user.banned) ...[
                          const SizedBox(width: 8),
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
                  ),
                ],
                if (posts.isEmpty && users.isEmpty)
                  const QEmptyState(
                    icon: Icons.search_rounded,
                    title: '没有找到相关内容',
                    desc: '换个关键词试试，比如「图书馆」',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultLabel extends StatelessWidget {
  const _ResultLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 9),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, color: t.text3),
      ),
    );
  }
}
