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
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _tab = 'login';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _nickname.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setTab(String tab) {
    setState(() {
      _tab = tab;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final app = AppScope.of(context);
    final store = app.store;
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入账号和密码');
      return;
    }
    if (_tab == 'register' && _nickname.text.trim().isEmpty) {
      setState(() => _error = '请填写昵称');
      return;
    }
    final register = _tab == 'register';
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
                              controller: _nickname,
                              hint: '昵称（展示给其他同学）',
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
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_busy) _submit();
                            },
                          ),
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
