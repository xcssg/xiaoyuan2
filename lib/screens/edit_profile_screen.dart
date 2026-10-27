import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final Store _store;
  late final AppUser _user;
  late final TextEditingController _nickname;
  late final TextEditingController _realName;
  late final TextEditingController _className;
  late final TextEditingController _bio;
  late int _avatar;
  late bool _showProfile;
  String _frameId = '';
  String _colorId = '';
  String _title = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final app = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
    _store = app.store;
    _user = _store.current!;
    _nickname = TextEditingController(text: _user.nickname);
    _realName = TextEditingController(text: _user.realName);
    _className = TextEditingController(text: _user.className);
    _bio = TextEditingController(text: _user.bio);
    _avatar = _user.avatar;
    _showProfile = _user.showProfile;
    _frameId = _user.equippedFrameId;
    _colorId = _user.equippedColorId;
    _title = _user.title;
  }

  @override
  void dispose() {
    _nickname.dispose();
    _realName.dispose();
    _className.dispose();
    _bio.dispose();
    super.dispose();
  }

  String _valueOfItem(String id) {
    for (final item in _store.shopItems) {
      if (item.id == id) return item.value;
    }
    return '';
  }

  Future<void> _save() async {
    if (_saving) return;
    final app = AppScope.of(context);
    if (_nickname.text.trim().isEmpty) {
      app.toast('昵称不能为空', type: ToastType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await _store.updateProfile(
        nickname: _nickname.text.trim(),
        realName: _realName.text.trim(),
        className: _className.text.trim(),
        bio: _bio.text.trim(),
        showProfile: _showProfile,
        avatar: _avatar,
        equippedFrameId: _frameId,
        equippedColorId: _colorId,
        title: _title,
      );
      if (!mounted) return;
      app.pop();
      app.toast('资料已更新', type: ToastType.success);
    } on StoreException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      app.toast(e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final frames = _store.ownedItems('frame');
    final colors = _store.ownedItems('color');
    final titles = _store.ownedItems('title').map((item) => item.value).toSet().toList();
    if (_user.grantedTitle.isNotEmpty && !titles.contains(_user.grantedTitle)) {
      titles.add(_user.grantedTitle);
    }
    if (_title.isNotEmpty && !titles.contains(_title)) {
      titles.add(_title);
    }
    final frameValue = _valueOfItem(_frameId);
    final colorValue = _valueOfItem(_colorId);
    final previewJson = _user.toJson();
    previewJson['nickname'] = _nickname.text.trim().isEmpty ? _user.nickname : _nickname.text.trim();
    previewJson['avatar'] = _avatar;
    previewJson['avatarFrame'] = frameValue;
    previewJson['nameColor'] = colorValue;
    previewJson['title'] = _title;
    final previewUser = AppUser.fromJson(previewJson);

    return Column(
      children: [
        QTopBar(
          title: '编辑资料',
          large: false,
          leading: QIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: app.pop,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 28 + bottomInset),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.brand.withOpacity(t.dark ? .20 : .10),
                      t.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border),
                  boxShadow: t.cardShadow,
                ),
                child: Column(
                  children: [
                    QAvatar(user: previewUser, size: 82, frame: frameValue),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            previewUser.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: parseHexColor(colorValue) ?? t.text,
                              letterSpacing: -.4,
                            ),
                          ),
                        ),
                        if (_title.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          QTitleBadge(title: _title),
                        ],
                      ],
                    ),
                    if (_className.text.trim().isNotEmpty || _realName.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${_className.text.trim()}${_className.text.trim().isNotEmpty && _realName.text.trim().isNotEmpty ? ' · ' : ''}${_realName.text.trim()}${_showProfile ? '' : ' · 仅自己可见'}',
                        style: TextStyle(fontSize: 11.5, color: t.text3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel('选择头像'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < 6; i++)
                    Pressable(
                      onTap: () => setState(() => _avatar = i),
                      scale: .94,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: t.avatarGradients[i],
                          border: Border.all(
                            color: _avatar == i ? t.brand : Colors.white.withOpacity(.3),
                            width: _avatar == i ? 2.5 : 1,
                          ),
                          boxShadow: _avatar == i ? t.brandShadow : null,
                        ),
                        child: _avatar == i
                            ? const Icon(Icons.check_rounded, size: 19, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel('昵称'),
              QField(controller: _nickname, hint: '展示给其他同学的名字', icon: Icons.person_outline_rounded, maxLength: 12),
              const SizedBox(height: 14),
              _SectionLabel('真实姓名'),
              QField(controller: _realName, hint: '仅用于身份登记，可选择不公开', icon: Icons.badge_outlined, maxLength: 20),
              const SizedBox(height: 14),
              _SectionLabel('班级'),
              QField(controller: _className, hint: '例如 23计算机1班', icon: Icons.school_outlined, maxLength: 20),
              const SizedBox(height: 14),
              _SectionLabel('个人简介'),
              QTextArea(controller: _bio, hint: '介绍一下自己吧', maxLength: 100, minHeight: 88),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: t.field,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18, color: t.text3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('公开班级和姓名', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.text)),
                          const SizedBox(height: 2),
                          Text(_showProfile ? '其他同学可以看到你的班级和姓名' : '仅管理员可见', style: TextStyle(fontSize: 10.5, color: t.text3)),
                        ],
                      ),
                    ),
                    QSwitch(on: _showProfile, onTap: () => setState(() => _showProfile = !_showProfile)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('头像框'),
              if (frames.isEmpty)
                _EmptyOwned(text: '还没有头像框', onShop: () => app.navigate(AppRoute.shop))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OptionChip(label: '不使用', active: _frameId.isEmpty, onTap: () => setState(() => _frameId = '')),
                    for (final item in frames)
                      _OptionChip(
                        label: item.name,
                        active: _frameId == item.id,
                        preview: QAvatar(user: previewUser, size: 20, frame: item.value),
                        onTap: () => setState(() => _frameId = item.id),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              _SectionLabel('昵称颜色'),
              if (colors.isEmpty)
                _EmptyOwned(text: '还没有昵称颜色', onShop: () => app.navigate(AppRoute.shop))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OptionChip(label: '默认', active: _colorId.isEmpty, onTap: () => setState(() => _colorId = '')),
                    for (final item in colors)
                      _OptionChip(
                        label: item.name,
                        active: _colorId == item.id,
                        preview: _ColorDot(color: parseHexColor(item.value) ?? t.brand),
                        onTap: () => setState(() => _colorId = item.id),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              _SectionLabel('称号'),
              if (titles.isEmpty)
                _EmptyOwned(text: '还没有称号，可由管理员授予或兑换', onShop: () => app.navigate(AppRoute.shop))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OptionChip(label: '不显示', active: _title.isEmpty, onTap: () => setState(() => _title = '')),
                    for (final title in titles)
                      _OptionChip(
                        label: title,
                        active: _title == title,
                        preview: const Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xFFB45309)),
                        onTap: () => setState(() => _title = title),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              QButton(
                label: _saving ? '保存中…' : '保存资料',
                icon: Icons.check_rounded,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text2, letterSpacing: .2),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.preview,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? t.brand.withOpacity(.10) : t.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: active ? t.brand : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview != null) ...[preview!, const SizedBox(width: 6)],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? t.brand : t.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyOwned extends StatelessWidget {
  const _EmptyOwned({required this.text, required this.onShop});

  final String text;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 11.5, color: t.text3))),
          QTextButton(label: '去积分商店', onTap: onShop),
        ],
      ),
    );
  }
}
