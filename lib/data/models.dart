import 'package:flutter/material.dart';

class StoreException implements Exception {
  StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CampusModule {
  const CampusModule({
    required this.key,
    required this.name,
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
  });

  final String key;
  final String name;
  final String label;
  final String desc;
  final String icon;
  final Color color;
}

class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.nickname,
    required this.role,
    required this.banned,
    required this.online,
    required this.avatar,
    required this.bio,
    required this.joinedAt,
    this.avatarUrl = '',
    this.avatarStatus = 'none',
    this.realName = '',
    this.className = '',
    this.showProfile = false,
    this.points = 0,
    this.avatarFrame = '',
    this.nameColor = '',
    this.title = '',
    this.grantedTitle = '',
    this.equippedFrameId = '',
    this.equippedColorId = '',
  });

  final String id;
  String username;
  String password;
  String nickname;
  String role;
  bool banned;
  bool online;
  int avatar;
  String bio;
  int joinedAt;
  String avatarUrl;
  String avatarStatus;
  String realName;
  String className;
  bool showProfile;
  int points;
  String avatarFrame;
  String nameColor;
  String title;
  String grantedTitle;
  String equippedFrameId;
  String equippedColorId;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        banned: json['banned'] as bool? ?? false,
        online: json['online'] as bool? ?? false,
        avatar: json['avatar'] as int? ?? 0,
        bio: json['bio'] as String? ?? '',
        joinedAt: json['joinedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        avatarStatus: json['avatarStatus'] as String? ?? 'none',
        realName: json['realName'] as String? ?? '',
        className: json['className'] as String? ?? '',
        showProfile: json['showProfile'] as bool? ?? false,
        points: json['points'] as int? ?? 0,
        avatarFrame: json['avatarFrame'] as String? ?? '',
        nameColor: json['nameColor'] as String? ?? '',
        title: json['title'] as String? ?? '',
        grantedTitle: json['grantedTitle'] as String? ?? '',
        equippedFrameId: json['equippedFrameId'] as String? ?? '',
        equippedColorId: json['equippedColorId'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'nickname': nickname,
        'role': role,
        'banned': banned,
        'online': online,
        'avatar': avatar,
        'bio': bio,
        'joinedAt': joinedAt,
        'avatarUrl': avatarUrl,
        'avatarStatus': avatarStatus,
        'realName': realName,
        'className': className,
        'showProfile': showProfile,
        'points': points,
        'avatarFrame': avatarFrame,
        'nameColor': nameColor,
        'title': title,
        'grantedTitle': grantedTitle,
        'equippedFrameId': equippedFrameId,
        'equippedColorId': equippedColorId,
      };
}

class DailyTask {
  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.points,
    required this.completed,
    required this.claimed,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final int points;
  final bool completed;
  final bool claimed;

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? 'manual',
        points: json['points'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
      );
}

class ShopItem {
  ShopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.value,
    required this.price,
    required this.owned,
    required this.equipped,
  });

  final String id;
  final String type;
  final String name;
  final String description;
  final String value;
  final int price;
  final bool owned;
  final bool equipped;

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        value: json['value'] as String? ?? '',
        price: json['price'] as int? ?? 0,
        owned: json['owned'] as bool? ?? false,
        equipped: json['equipped'] as bool? ?? false,
      );
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.important,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final bool important;
  final bool read;
  final int createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        important: json['important'] as bool? ?? false,
        read: json['read'] as bool? ?? false,
        createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}

class AppSettings {
  const AppSettings({this.aboutText = '', this.version = 'V1.01'});

  final String aboutText;
  final String version;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        aboutText: json['aboutText'] as String? ?? '',
        version: json['version'] as String? ?? 'V1.01',
      );
}

class DiscussionBar {
  DiscussionBar({
    required this.id,
    required this.module,
    required this.name,
    required this.desc,
    required this.icon,
    required this.members,
    required this.createdAt,
  });

  final String id;
  String module;
  String name;
  String desc;
  String icon;
  int members;
  int createdAt;

  factory DiscussionBar.fromJson(Map<String, dynamic> json) => DiscussionBar(
        id: json['id'] as String,
        module: json['module'] as String? ?? 'lost',
        name: json['name'] as String? ?? '',
        desc: json['desc'] as String? ?? '',
        icon: json['icon'] as String? ?? 'search',
        members: json['members'] as int? ?? 0,
        createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'name': name,
        'desc': desc,
        'icon': icon,
        'members': members,
        'createdAt': createdAt,
      };
}

class PostComment {
  PostComment({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String content;
  final int createdAt;

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'content': content,
        'createdAt': createdAt,
      };
}

class Post {
  Post({
    required this.id,
    required this.barId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.anonymous,
    required this.likes,
    required this.likedBy,
    required this.comments,
    required this.createdAt,
    this.deleted = false,
    this.imageUrl = '',
    this.status = 'approved',
    this.rejectReason = '',
  });

  final String id;
  final String barId;
  final String authorId;
  final String title;
  final String content;
  final bool anonymous;
  int likes;
  final List<String> likedBy;
  final List<PostComment> comments;
  final int createdAt;
  bool deleted;
  String imageUrl;
  String status;
  String rejectReason;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        barId: json['barId'] as String? ?? '',
        authorId: json['authorId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        anonymous: json['anonymous'] as bool? ?? false,
        likes: json['likes'] as int? ?? 0,
        likedBy: (json['likedBy'] as List<dynamic>? ?? const []).cast<String>(),
        comments: (json['comments'] as List<dynamic>? ?? const [])
            .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        deleted: json['deleted'] as bool? ?? false,
        imageUrl: json['imageUrl'] as String? ?? '',
        status: json['status'] as String? ?? 'approved',
        rejectReason: json['rejectReason'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'barId': barId,
        'authorId': authorId,
        'title': title,
        'content': content,
        'anonymous': anonymous,
        'likes': likes,
        'likedBy': likedBy,
        'comments': comments.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'deleted': deleted,
        'imageUrl': imageUrl,
        'status': status,
        'rejectReason': rejectReason,
      };
}

class AppMessage {
  AppMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.unread,
  });

  final String id;
  final String type;
  final String title;
  final String text;
  final int createdAt;
  bool unread;

  factory AppMessage.fromJson(Map<String, dynamic> json) => AppMessage(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'system',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        unread: json['unread'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'text': text,
        'createdAt': createdAt,
        'unread': unread,
      };
}
