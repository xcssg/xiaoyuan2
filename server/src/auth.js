const jwt = require('jsonwebtoken');
const db = require('./db');

const SECRET = process.env.JWT_SECRET || 'wszz-wall-dev-secret-change-me';
if (!process.env.JWT_SECRET) {
  console.warn('[auth] JWT_SECRET not set, using development secret');
}

function signToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, SECRET, { expiresIn: '30d' });
}

function publicUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    username: row.username,
    nickname: row.nickname,
    role: row.role,
    banned: !!row.banned,
    online: !!row.online,
    avatar: row.avatar,
    bio: row.bio,
    joinedAt: row.joined_at,
  };
}

function readUser(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  try {
    const payload = jwt.verify(header.slice(7), SECRET);
    return db.prepare('SELECT * FROM users WHERE id = ?').get(payload.sub) || null;
  } catch (_) {
    return null;
  }
}

function optionalAuth(req, _res, next) {
  req.user = readUser(req);
  next();
}

function requireAuth(req, res, next) {
  req.user = readUser(req);
  if (!req.user) return res.status(401).json({ error: '请先登录' });
  if (req.user.banned) return res.status(403).json({ error: '该账号已被封禁，请联系管理员' });
  next();
}

function requireAdmin(req, res, next) {
  req.user = readUser(req);
  if (!req.user) return res.status(401).json({ error: '请先登录' });
  if (req.user.banned) return res.status(403).json({ error: '该账号已被封禁，请联系管理员' });
  if (req.user.role !== 'admin') return res.status(403).json({ error: '需要管理员权限' });
  next();
}

module.exports = { signToken, publicUser, optionalAuth, requireAuth, requireAdmin, SECRET };
