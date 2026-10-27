const jwt = require('jsonwebtoken');
const db = require('./db');

const SECRET = process.env.JWT_SECRET || 'wszz-wall-dev-secret-change-me';
if (!process.env.JWT_SECRET) {
  console.warn('[auth] JWT_SECRET not set, using development secret');
}

const SHOP_VALUES = new Map();
for (const item of db.prepare('SELECT id, type, value, name FROM shop_items').all()) {
  SHOP_VALUES.set(item.id, item);
}

function signToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, SECRET, { expiresIn: '30d' });
}

function isOnline(row) {
  const last = row.last_active || 0;
  return !!row.online && Date.now() - last < 5 * 60 * 1000;
}

function publicUser(row, viewer) {
  if (!row) return null;
  const isSelf = !!viewer && viewer.id === row.id;
  const isAdmin = !!viewer && viewer.role === 'admin';
  const showReal = !!row.show_profile || isSelf || isAdmin;
  const frameValue = row.equipped_frame ? (SHOP_VALUES.get(row.equipped_frame) || {}).value || '' : '';
  const colorValue = row.equipped_color ? (SHOP_VALUES.get(row.equipped_color) || {}).value || '' : '';

  return {
    id: row.id,
    username: row.username,
    nickname: row.nickname,
    role: row.role,
    banned: !!row.banned,
    online: isOnline(row),
    avatar: row.avatar,
    bio: row.bio,
    joinedAt: row.joined_at,
    realName: showReal ? row.real_name : '',
    className: showReal ? row.class_name : '',
    showProfile: !!row.show_profile,
    points: isSelf || isAdmin ? row.points : 0,
    avatarFrame: frameValue,
    nameColor: colorValue,
    title: row.title || '',
    grantedTitle: isSelf || isAdmin ? row.granted_title || '' : '',
    equippedFrameId: isSelf || isAdmin ? row.equipped_frame || '' : '',
    equippedColorId: isSelf || isAdmin ? row.equipped_color || '' : '',
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

module.exports = { signToken, publicUser, optionalAuth, requireAuth, requireAdmin, SECRET, SHOP_VALUES };
