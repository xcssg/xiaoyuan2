const db = require('./db');

function barJson(row) {
  return {
    id: row.id,
    module: row.module,
    name: row.name,
    desc: row.description,
    icon: row.icon,
    members: row.members,
    createdAt: row.created_at,
  };
}

function commentJson(row) {
  return {
    id: row.id,
    authorId: row.author_id,
    content: row.content,
    createdAt: row.created_at,
  };
}

function messageJson(row) {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    text: row.content,
    createdAt: row.created_at,
    unread: !!row.unread,
  };
}

function postJson(row, currentUserId) {
  const comments = db.prepare('SELECT * FROM comments WHERE post_id = ? ORDER BY created_at ASC').all(row.id).map(commentJson);
  const liked = currentUserId
    ? !!db.prepare('SELECT 1 AS ok FROM post_likes WHERE post_id = ? AND user_id = ?').get(row.id, currentUserId)
    : false;
  return {
    id: row.id,
    barId: row.bar_id,
    authorId: row.author_id,
    title: row.title,
    content: row.content,
    anonymous: !!row.anonymous,
    likes: row.likes,
    likedBy: liked ? [currentUserId] : [],
    comments,
    createdAt: row.created_at,
    deleted: !!row.deleted,
  };
}

module.exports = { barJson, commentJson, messageJson, postJson };
