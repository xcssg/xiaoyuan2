import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.presetBarId});

  final String? presetBarId;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  String? _barId;
  bool _anonymous = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final app = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
    final bars = app.store.bars();
    final preferred = widget.presetBarId ?? app.composeBarId;
    _barId = bars.any((b) => b.id == preferred)
        ? preferred
        : (bars.isEmpty ? null : bars.first.id);
    _anonymous = app.composeAnonymous;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final app = AppScope.of(context);
    if (_barId == null) {
      app.toast('请选择要发布到的贴吧', type: ToastType.error);
      return;
    }
    setState(() => _busy = true);
    try {
      final post = await app.store.createPost(
        barId: _barId!,
        title: _title.text,
        content: _content.text,
        anonymous: _anonymous,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _anonymous = false;
      });
      app.setComposeAnonymous(false);
      app.toast('发布成功', type: ToastType.success);
      app.replace(AppRoute.post(post.id));
    } on StoreException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      app.toast(e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bars = store.bars();

    if (bars.isEmpty) {
      return Column(
        children: [
          QTopBar(
            title: '发布帖子',
            large: false,
            leading: QIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: app.pop,
            ),
          ),
          const Expanded(
            child: QEmptyState(
              icon: Icons.explore_outlined,
              title: '还没有可用的贴吧',
              desc: '请先联系管理员创建贴吧',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        QTopBar(
          title: '发布帖子',
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 34 + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              _FieldLabel('发布到'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final bar in bars)
                    _BarSelect(
                      bar: bar,
                      active: bar.id == _barId,
                      onTap: () {
                        setState(() => _barId = bar.id);
                        app.setComposeBar(bar.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldLabel('标题'),
              QField(
                controller: _title,
                hint: '用一句话说清楚（至少 4 个字）',
                icon: Icons.edit_outlined,
                maxLength: 40,
              ),
              const SizedBox(height: 16),
              _FieldLabel('正文'),
              QTextArea(
                controller: _content,
                hint: '补充细节，让同学更容易帮到你…',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: t.brand.withOpacity(.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: t.brand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '匿名发布',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: t.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '表白、吐槽时隐藏身份，管理员仍可追溯',
                            style: TextStyle(fontSize: 11, color: t.text3),
                          ),
                        ],
                      ),
                    ),
                    QSwitch(
                      on: _anonymous,
                      onTap: () {
                        setState(() => _anonymous = !_anonymous);
                        app.setComposeAnonymous(_anonymous);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: t.text3),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '请勿发布个人敏感信息；线下见面请选择公共场所。违规内容会被管理员删除。',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.6,
                        color: t.text3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              QButton(
                label: _busy ? '发布中…' : '发布帖子',
                icon: Icons.send_rounded,
                onTap: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 7),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.text2,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _BarSelect extends StatelessWidget {
  const _BarSelect({
    required this.bar,
    required this.active,
    required this.onTap,
  });

  final DiscussionBar bar;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    final mod = AppScope.of(context).store.moduleOf(bar.module);
    final fg = active ? mod.color : t.text2;
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? mod.color.withOpacity(.12) : t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? mod.color : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(qIcon(bar.icon), size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              bar.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
