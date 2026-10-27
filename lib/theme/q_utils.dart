import 'package:flutter/material.dart';

IconData qIcon(String name) {
  switch (name) {
    case 'home':
      return Icons.home_outlined;
    case 'compass':
      return Icons.explore_outlined;
    case 'chat':
      return Icons.chat_bubble_outline_rounded;
    case 'user':
      return Icons.person_outline_rounded;
    case 'users':
      return Icons.people_outline_rounded;
    case 'plus':
      return Icons.add_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'sun':
      return Icons.light_mode_outlined;
    case 'moon':
      return Icons.dark_mode_outlined;
    case 'arrowLeft':
      return Icons.arrow_back_ios_new_rounded;
    case 'arrowRight':
      return Icons.arrow_forward_rounded;
    case 'heart':
      return Icons.favorite_border_rounded;
    case 'message':
      return Icons.chat_bubble_outline_rounded;
    case 'trash':
      return Icons.delete_outline_rounded;
    case 'grid':
      return Icons.grid_view_rounded;
    case 'shield':
      return Icons.shield_outlined;
    case 'eye':
      return Icons.visibility_outlined;
    case 'ban':
      return Icons.block_rounded;
    case 'key':
      return Icons.key_rounded;
    case 'edit':
      return Icons.edit_outlined;
    case 'chevron':
      return Icons.chevron_right_rounded;
    case 'logout':
      return Icons.logout_rounded;
    case 'sparkles':
      return Icons.auto_awesome_rounded;
    case 'bell':
      return Icons.notifications_none_rounded;
    case 'check':
      return Icons.check_rounded;
    case 'close':
      return Icons.close_rounded;
    case 'send':
      return Icons.send_rounded;
    case 'lock':
      return Icons.lock_outline_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'chart':
      return Icons.bar_chart_rounded;
    case 'more':
      return Icons.more_horiz_rounded;
    case 'info':
      return Icons.info_outline_rounded;
    case 'clock':
      return Icons.schedule_rounded;
    case 'tag':
      return Icons.sell_outlined;
    case 'at':
      return Icons.alternate_email_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

String timeAgo(int ts) {
  final diff = DateTime.now().millisecondsSinceEpoch - ts;
  if (diff < 60000) return '刚刚';
  if (diff < 3600000) return '${diff ~/ 60000} 分钟前';
  if (diff < 86400000) return '${diff ~/ 3600000} 小时前';
  if (diff < 172800000) return '昨天';
  if (diff < 604800000) return '${diff ~/ 86400000} 天前';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${d.month} 月 ${d.day} 日';
}

String dateStr(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 6) return '夜深了';
  if (h < 11) return '早上好';
  if (h < 14) return '中午好';
  if (h < 18) return '下午好';
  return '晚上好';
}

int daysSince(int ts) {
  final days = (DateTime.now().millisecondsSinceEpoch - ts) ~/ 86400000;
  return days < 1 ? 1 : days;
}


Color? parseHexColor(String value) {
  final v = value.trim();
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) return null;
  return Color(int.parse('FF${v.substring(1)}', radix: 16));
}
