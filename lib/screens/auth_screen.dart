import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nickname = TextEditingController();
  final _realName = TextEditingController();
  final _className = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _captcha = TextEditingController();
  String _tab = 'login';
  String? _error;
  bool _busy = false;
  bool _showProfile = false;
  String _captchaQuestion = '';
  String _captchaToken = '';
  bool _captchaLoading = false;

  @override
  void dispose() {
    _nickname.dispose();
    _realName.dispose();
    _className.dispose();
    _username.dispose();
    _password.dispose();
    _captcha.dispose();
    super.dispose();
  }

  void _setTab(String tab) {
    setState(() {
      _tab = tab;
      _error = null;
    });
    if (tab == 'register' && _captchaToken.isEmpty) {
      _loadCaptcha();
    }
  }

  Future<void> _loadCaptcha() async {
    if (_captchaLoading) return;
    setState(() {
      _captchaLoading = true;
      _captchaQuestion = '';
      _captchaToken = '';
      _captcha.clear();
    });
    try {
      final data = await AppScope.of(context).store.fetchCaptcha();
      if (!mounted) return;
      setState(() {
        _captchaQuestion = data['question'] ?? '';
        _captchaToken = data['token'] ?? '';
        _captchaLoading = false;
      });
    } on StoreException catch (e) {
      if (!mounted) return;
      setState(() => _captchaLoading = false);
      AppScope.of(context).toast(e.message, type: ToastType.error);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final app = AppScope.of(context);
    final store = app.store;
    final username = _username.text.trim();
    final password = _password.text;
    final register = _tab == 'register';
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入账号和密码');
      return;
    }
    if (register) {
      if (_realName.text.trim().isEmpty) {
        setState(() => _error = '请填写姓名');
        return;
      }
      if (_className.text.trim().isEmpty) {
        setState(() => _error = '请填写班级');
        return;
      }
      if (_captchaToken.isEmpty) {
        setState(() => _error = '验证码未加载，请点击刷新');
        _loadCaptcha();
        return;
      }
      if (_captcha.text.trim().isEmpty) {
        setState(() => _error = '请输入验证码计算结果');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final AppUser user = register
          ? await store.register(
              username: username,
              password: password,
              nickname: _nickname.text.trim(),
              realName: _realName.text.trim(),
              className: _className.text.trim(),
              showProfile: _showProfile,
              captchaToken: _captchaToken,
              captchaAnswer: _captcha.text.trim(),
            )
          : await store.login(username, password);
      if (!mounted) return;
      setState(() => _busy = false);
      app.reset(AppRoute.home);
      app.toast(
        register ? '注册成功，欢迎加入乌市职专墙' : '欢迎回来，${user.nickname}',
        type: ToastType.success,
      );
    } on StoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      app.toast(e.message, type: ToastType.error);
      if (register) _loadCaptcha();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = QColors.of(context);
    final isLogin = _tab == 'login';
    final headline = TextStyle(
      fontSize: 30,
      height: 1.32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      color: t.text,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 40),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '乌市职专墙',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: t.text,
                            letterSpacing: -.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'CAMPUS WALL',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: t.text3,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    QIconButton(
                      icon: app.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      onTap: app.toggleTheme,
                      iconSize: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text('找回丢失的，', style: headline),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientTitle(text: '遇见心动的', style: headline),
                    Text('。', style: headline),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '校园寻物 · 吐槽 · 表白 · 找人，一个就够',
                  style: TextStyle(fontSize: 12.5, color: t.text2),
                ),
                const SizedBox(height: 26),
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: t.glass,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: t.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: t.dark
                                ? Colors.black.withOpacity(.5)
                                : const Color(0x291F4A96),
                            blurRadius: 60,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QSeg(
                            options: const [
                              QSegOption('login', '登录'),
                              QSegOption('register', '注册'),
                            ],
                            value: _tab,
                            onChanged: _setTab,
                          ),
                          const SizedBox(height: 16),
                          if (!isLogin) ...[
                            QField(
                              controller: _realName,
                              hint: '真实姓名（仅用于身份登记）',
                              icon: Icons.badge_outlined,
                              maxLength: 20,
                            ),
                            const SizedBox(height: 11),
                            QField(
                              controller: _className,
                              hint: '班级（例如 23计算机1班）',
                              icon: Icons.school_outlined,
                              maxLength: 20,
                            ),
                            const SizedBox(height: 11),
                            QField(
                              controller: _nickname,
                              hint: '昵称（不填则使用姓名）',
                              icon: Icons.person_outline_rounded,
                              maxLength: 12,
                            ),
                            const SizedBox(height: 11),
                          ],
                          QField(
                            controller: _username,
                            hint: isLogin ? '学号 / 账号' : '账号（3-16 位字母 / 数字）',
                            icon: isLogin ? Icons.person_outline_rounded : Icons.alternate_email_rounded,
                            maxLength: 16,
                          ),
                          const SizedBox(height: 11),
                          QField(
                            controller: _password,
                            hint: isLogin ? '密码' : '密码（至少 6 位）',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                            onSubmitted: (_) {
                              if (isLogin && !_busy) _submit();
                            },
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 11),
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: t.field,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calculate_outlined, size: 18, color: t.text3),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _captchaLoading
                                          ? '正在获取验证码…'
                                          : (_captchaQuestion.isEmpty ? '验证码加载失败' : _captchaQuestion),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _captchaQuestion.isEmpty ? t.text3 : t.text,
                                      ),
                                    ),
                                  ),
                                  Pressable(
                                    onTap: _captchaLoading ? null : _loadCaptcha,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.refresh_rounded, size: 19, color: t.brand),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 11),
                            QField(
                              controller: _captcha,
                              hint: '输入计算结果',
                              icon: Icons.verified_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_busy) _submit();
                              },
                            ),
                            const SizedBox(height: 11),
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
                                        Text(
                                          '公开班级和姓名',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: t.text,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _showProfile ? '其他同学可以在资料里看到' : '仅管理员可见',
                                          style: TextStyle(fontSize: 10.5, color: t.text3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  QSwitch(
                                    on: _showProfile,
                                    onTap: () => setState(() => _showProfile = !_showProfile),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 11),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                              decoration: BoxDecoration(
                                color: t.dangerSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(fontSize: 11.5, height: 1.5, color: t.danger),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                isLogin ? '还没有账号？' : '注册后自动登录',
                                style: TextStyle(fontSize: 11, color: t.text3),
                              ),
                              const Spacer(),
                              QTextButton(
                                label: isLogin ? '立即注册' : '返回登录',
                                onTap: () => _setTab(isLogin ? 'register' : 'login'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          QButton(
                            label: _busy
                                ? (isLogin ? '登录中…' : '注册中…')
                                : (isLogin ? '进入乌市职专墙' : '注册并登录'),
                            onTap: _busy ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '登录即代表同意《社区公约》与《隐私说明》\n乌市职专墙 · 校园社区',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, height: 1.7, color: t.text3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
