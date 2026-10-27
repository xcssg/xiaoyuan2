import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme/q_colors.dart';
import '../theme/q_utils.dart';
import '../widgets/common.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Set<String> _buying = {};

  Future<void> _buy(ShopItem item) async {
    if (_buying.contains(item.id)) return;
    final app = AppScope.of(context);
    setState(() => _buying.add(item.id));
    try {
      await app.store.buyItem(item.id);
      if (!mounted) return;
      app.toast('兑换成功，已为你自动装备', type: ToastType.success);
    } on StoreException catch (e) {
      if (!mounted) return;
      app.toast(e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _buying.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.store;
    final t = QColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final items = store.shopItems;
    final points = store.current?.points ?? 0;

    final groups = <String, List<ShopItem>>{
      'frame': items.where((item) => item.type == 'frame').toList(),
      'color': items.where((item) => item.type == 'color').toList(),
      'title': items.where((item) => item.type == 'title').toList(),
    };

    return Column(
      children: [
        QTopBar(
          title: '积分商店',
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: t.brandGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: t.brandShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '用积分装扮自己',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '兑换后自动装备，也可在编辑资料里切换',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(.78)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$points',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _Group(
                title: '头像框',
                icon: Icons.account_circle_outlined,
                items: groups['frame']!,
                currentUser: store.current,
                buying: _buying,
                onBuy: _buy,
              ),
              _Group(
                title: '昵称颜色',
                icon: Icons.palette_outlined,
                items: groups['color']!,
                currentUser: store.current,
                buying: _buying,
                onBuy: _buy,
              ),
              _Group(
                title: '专属称号',
                icon: Icons.workspace_premium_outlined,
                items: groups['title']!,
                currentUser: store.current,
                buying: _buying,
                onBuy: _buy,
              ),
              const SizedBox(height: 8),
              Text(
                '积分可以通过任务中心获取，专属称号也可以由管理员直接授予。',
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

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.icon,
    required this.items,
    required this.currentUser,
    required this.buying,
    required this.onBuy,
  });

  final String title;
  final IconData icon;
  final List<ShopItem> items;
  final AppUser? currentUser;
  final Set<String> buying;
  final ValueChanged<ShopItem> onBuy;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 15, color: t.text3),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text2, letterSpacing: .2),
              ),
            ],
          ),
        ),
        for (final item in items) ...[
          QCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _Preview(item: item, user: currentUser),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: t.text3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (item.equipped)
                  const QPill(text: '使用中', style: QPillStyle.ok)
                else if (item.owned)
                  const QPill(text: '已拥有', style: QPillStyle.soft)
                else
                  Pressable(
                    onTap: buying.contains(item.id) ? null : () => onBuy(item),
                    scale: .95,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: t.brandGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: t.brandShadow,
                      ),
                      child: Center(
                        child: Text(
                          buying.contains(item.id) ? '兑换中' : '${item.price} 积分',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item, required this.user});

  final ShopItem item;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    switch (item.type) {
      case 'frame':
        return QAvatar(user: user, size: 42, frame: item.value);
      case 'color':
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: parseHexColor(item.value) ?? t.brand,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: (parseHexColor(item.value) ?? t.brand).withOpacity(.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        );
      default:
        return Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3C4),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.workspace_premium_rounded, size: 21, color: Color(0xFFB45309)),
        );
    }
  }
}
