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
      };
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
