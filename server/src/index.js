const path = require('node:path');
require('dotenv').config({ path: process.env.ENV_FILE || path.join(__dirname, '..', '.env') });

const crypto = require('node:crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');

const db = require('./db');
const { signToken, publicUser, optionalAuth, requireAuth, requireAdmin } = require('./auth');
const { barJson, messageJson, postJson } = require('./serialize');

const app = express();
const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '127.0.0.1';

app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));
app.use(rateLimit({
  windowMs: 60 * 1000,
  limit: 180,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: '请求过于频繁，请稍后再试' },
}));

const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: '登录或注册过于频繁，请稍后再试' },
});

const MODULES = {
  lost: { icon: 'search' },
  rant: { icon: 'bolt' },
  confess: { icon: 'heart' },
  find: { icon: 'users' },
};

const now = () => Date.now();
const newId = (prefix) => prefix + crypto.randomBytes(6).toString('hex');
const text = (value) => (typeof value === 'string' ? value.trim() : '');

function fail(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  error.expose = true;
  throw error;
}

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function stats() {
  const total = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
  const online = db.prepare('SELECT COUNT(*) AS n FROM users WHERE online = 1 AND banned = 0').get().n;
  const banned = db.prepare('SELECT COUNT(*) AS n FROM users WHERE banned = 1').get().n;
  return { total, online, banned };
}

function addMessage(userId, type, title, content) {
  db.prepare('INSERT INTO messages (id, user_id, type, title, content, created_at, unread) VALUES (?, ?, ?, ?, ?, ?, 1)')
    .run(newId('m'), userId, type, title, content, now());
}

function getPostRow(id) {
  return db.prepare('SELECT * FROM posts WHERE id = ? AND deleted = 0').get(id);
}

/* ---------------- 基础 ---------------- */

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'wszz-wall', time: now() });
});

/* ---------------- 认证 ---------------- */

app.post('/api/auth/register', authLimiter, wrap(async (req, res) => {
  const username = text(req.body.username);
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  const nickname = text(req.body.nickname) || username;

  if (!/^[a-zA-Z0-9_]{3,16}$/.test(username)) fail('账号需为 3 - 16 位字母、数字或下划线');
  if (password.length < 6) fail('密码至少需要 6 位');
  if (nickname.length < 1 || nickname.length > 12) fail('昵称需为 1 - 12 个字');
  if (db.prepare('SELECT 1 AS ok FROM users WHERE username = ?').get(username)) fail('该账号已被注册', 409);

  const id = newId('u');
  db.prepare('INSERT INTO users (id, username, password_hash, nickname, role, banned, online, avatar, bio, joined_at, last_active) VALUES (?, ?, ?, ?, ?, 0, 1, ?, ?, ?, ?)')
    .run(id, username, await bcrypt.hash(password, 10), nickname, 'user', Math.floor(Math.random() * 6), '这位同学还没有写简介', now(), now());
  addMessage(id, 'system', '欢迎来到乌市职专墙', '请友善发言，共同维护校园社区环境。');

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
  res.status(201).json({ token: signToken(user), user: publicUser(user) });
}));

app.post('/api/auth/login', authLimiter, wrap(async (req, res) => {
  const username = text(req.body.username);
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  if (!username || !password) fail('请输入账号和密码');

  const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username);
  if (!user) fail('账号不存在，请先注册');
  if (!(await bcrypt.compare(password, user.password_hash))) fail('密码不正确，请重试');
  if (user.banned) fail('该账号已被封禁，请联系管理员', 403);

  db.prepare('UPDATE users SET online = 1, last_active = ? WHERE id = ?').run(now(), user.id);
  const fresh = db.prepare('SELECT * FROM users WHERE id = ?').get(user.id);
  res.json({ token: signToken(fresh), user: publicUser(fresh) });
}));

app.post('/api/auth/logout', requireAuth, (req, res) => {
  db.prepare('UPDATE users SET online = 0 WHERE id = ?').run(req.user.id);
  res.json({ ok: true });
});

/* ---------------- 初始化数据 ---------------- */

app.get('/api/bootstrap', optionalAuth, (req, res) => {
  const me = req.user;
  if (!me) {
    return res.json({ user: null, users: [], bars: [], posts: [], messages: [] });
  }

  db.prepare('UPDATE users SET online = 1, last_active = ? WHERE id = ?').run(now(), me.id);

  const users = db.prepare('SELECT * FROM users').all().map(publicUser);
  const bars = db.prepare('SELECT * FROM bars ORDER BY created_at ASC').all().map(barJson);
  const posts = db.prepare('SELECT * FROM posts WHERE deleted = 0 ORDER BY created_at DESC').all()
    .map((row) => postJson(row, me.id));
  const messages = db.prepare('SELECT * FROM messages WHERE user_id = ? ORDER BY created_at DESC').all(me.id)
    .map(messageJson);

  res.json({
    user: publicUser(me),
    users,
    bars,
    posts,
    messages,
    stats: me.role === 'admin' ? stats() : null,
  });
});

/* ---------------- 帖子 / 评论 / 点赞 ---------------- */

app.get('/api/posts', optionalAuth, (req, res) => {
  const me = req.user;
  const barId = text(req.query.barId);
  const q = text(req.query.q).toLowerCase();
  const sort = req.query.sort === 'hot' ? 'hot' : 'new';
  const limit = Math.min(200, Math.max(0, Number(req.query.limit) || 0));

  let rows = db.prepare('SELECT * FROM posts WHERE deleted = 0').all();
  if (barId) rows = rows.filter((row) => row.bar_id === barId);
  if (q) {
    rows = rows.filter((row) => {
      const bar = db.prepare('SELECT name FROM bars WHERE id = ?').get(row.bar_id);
      const author = db.prepare('SELECT nickname FROM users WHERE id = ?').get(row.author_id);
      return row.title.toLowerCase().includes(q)
        || row.content.toLowerCase().includes(q)
        || (bar && bar.name.toLowerCase().includes(q))
        || (author && author.nickname.toLowerCase().includes(q));
    });
  }
  rows.sort((a, b) => b.created_at - a.created_at);
  if (sort === 'hot') {
    const score = (row) => row.likes + db.prepare('SELECT COUNT(*) AS n FROM comments WHERE post_id = ?').get(row.id).n * 3;
    rows.sort((a, b) => score(b) - score(a));
  }
  if (limit) rows = rows.slice(0, limit);
  res.json(rows.map((row) => postJson(row, me && me.id)));
});

app.get('/api/posts/:id', optionalAuth, (req, res) => {
  const row = getPostRow(req.params.id);
  if (!row) return res.status(404).json({ error: '帖子不存在或已被删除' });
  res.json(postJson(row, req.user && req.user.id));
});

app.post('/api/posts', requireAuth, (req, res) => {
  const barId = text(req.body.barId);
  const title = text(req.body.title);
  const content = text(req.body.content);
  const anonymous = !!req.body.anonymous;

  if (!db.prepare('SELECT 1 AS ok FROM bars WHERE id = ?').get(barId)) fail('请选择要发布到的贴吧');
  if (title.length < 4) fail('标题至少需要 4 个字');
  if (title.length > 40) fail('标题不能超过 40 个字');
  if (content.length < 6) fail('正文至少需要 6 个字');
  if (content.length > 1000) fail('正文不能超过 1000 个字');

  const id = newId('p');
  db.prepare('INSERT INTO posts (id, bar_id, author_id, title, content, anonymous, likes, created_at) VALUES (?, ?, ?, ?, ?, ?, 0, ?)')
    .run(id, barId, req.user.id, title, content, anonymous ? 1 : 0, now());
  res.status(201).json(postJson(getPostRow(id), req.user.id));
});

app.delete('/api/posts/:id', requireAuth, (req, res) => {
  const row = getPostRow(req.params.id);
  if (!row) return res.status(404).json({ error: '帖子不存在或已被删除' });
  if (req.user.role !== 'admin' && row.author_id !== req.user.id) {
    return res.status(403).json({ error: '没有权限删除该帖子' });
  }
  db.prepare('UPDATE posts SET deleted = 1, deleted_at = ?, deleted_by = ? WHERE id = ?')
    .run(now(), req.user.id, row.id);
  res.json({ ok: true, id: row.id });
});

app.post('/api/posts/:id/like', requireAuth, (req, res) => {
  const row = getPostRow(req.params.id);
  if (!row) return res.status(404).json({ error: '帖子不存在' });

  const liked = !!db.prepare('SELECT 1 AS ok FROM post_likes WHERE post_id = ? AND user_id = ?').get(row.id, req.user.id);
  db.exec('BEGIN');
  try {
    if (liked) {
      db.prepare('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?').run(row.id, req.user.id);
      db.prepare('UPDATE posts SET likes = MAX(0, likes - 1) WHERE id = ?').run(row.id);
    } else {
      db.prepare('INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)').run(row.id, req.user.id);
      db.prepare('UPDATE posts SET likes = likes + 1 WHERE id = ?').run(row.id);
      if (row.author_id !== req.user.id) {
        addMessage(row.author_id, 'like', '你的帖子收到了新的赞', `「${row.title}」新增 1 个赞`);
      }
    }
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
  res.json(postJson(getPostRow(row.id), req.user.id));
});

app.post('/api/posts/:id/comments', requireAuth, (req, res) => {
  const row = getPostRow(req.params.id);
  if (!row) return res.status(404).json({ error: '帖子不存在' });
  const content = text(req.body.content);
  if (!content) fail('评论内容不能为空');
  if (content.length > 200) fail('评论不能超过 200 字');

  db.prepare('INSERT INTO comments (id, post_id, author_id, content, created_at) VALUES (?, ?, ?, ?, ?)')
    .run(newId('c'), row.id, req.user.id, content, now());
  if (row.author_id !== req.user.id) {
    addMessage(row.author_id, 'comment', `${req.user.nickname} 回复了你`, `「${content.slice(0, 60)}」`);
  }
  res.status(201).json(postJson(getPostRow(row.id), req.user.id));
});

/* ---------------- 消息 ---------------- */

app.get('/api/messages', requireAuth, (req, res) => {
  const rows = db.prepare('SELECT * FROM messages WHERE user_id = ? ORDER BY created_at DESC').all(req.user.id);
  res.json(rows.map(messageJson));
});

app.post('/api/messages/read-all', requireAuth, (req, res) => {
  db.prepare('UPDATE messages SET unread = 0 WHERE user_id = ?').run(req.user.id);
  res.json({ ok: true });
});

app.post('/api/messages/:id/read', requireAuth, (req, res) => {
  db.prepare('UPDATE messages SET unread = 0 WHERE id = ? AND user_id = ?').run(req.params.id, req.user.id);
  res.json({ ok: true });
});

/* ---------------- 管理后台 ---------------- */

app.get('/api/admin/stats', requireAdmin, (_req, res) => {
  res.json(stats());
});

app.get('/api/admin/users', requireAdmin, (req, res) => {
  const q = text(req.query.q).toLowerCase();
  let rows = db.prepare('SELECT * FROM users').all();
  if (q) rows = rows.filter((row) => row.username.toLowerCase().includes(q) || row.nickname.toLowerCase().includes(q));
  rows.sort((a, b) => {
    if (a.role !== b.role) return a.role === 'admin' ? -1 : 1;
    return b.joined_at - a.joined_at;
  });
  res.json(rows.map(publicUser));
});

app.post('/api/admin/users/:id/ban', requireAdmin, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  if (user.role === 'admin') fail('管理员账号不可封禁');
  if (user.id === req.user.id) fail('不能封禁当前登录账号');
  const banned = user.banned ? 0 : 1;
  db.prepare('UPDATE users SET banned = ?, online = CASE WHEN ? = 1 THEN 0 ELSE online END WHERE id = ?')
    .run(banned, banned, user.id);
  res.json(publicUser(db.prepare('SELECT * FROM users WHERE id = ?').get(user.id)));
});

app.post('/api/admin/users/:id/password', requireAdmin, wrap(async (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  if (password.length < 6) fail('新密码至少需要 6 位');
  db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(await bcrypt.hash(password, 10), user.id);
  res.json({ ok: true });
}));

app.post('/api/admin/bars', requireAdmin, (req, res) => {
  const moduleKey = text(req.body.module);
  const name = text(req.body.name);
  const description = text(req.body.desc);
  const module = MODULES[moduleKey];
  if (!module) fail('请选择所属模块');
  if (name.length < 2 || name.length > 12) fail('贴吧名称需为 2 - 12 个字');
  if (db.prepare('SELECT 1 AS ok FROM bars WHERE name = ?').get(name)) fail('该贴吧名称已存在', 409);

  const id = newId('b');
  db.prepare('INSERT INTO bars (id, module, name, description, icon, members, created_at) VALUES (?, ?, ?, ?, ?, 0, ?)')
    .run(id, moduleKey, name, description || '这个贴吧还没有介绍', module.icon, now());
  res.status(201).json(barJson(db.prepare('SELECT * FROM bars WHERE id = ?').get(id)));
});

app.patch('/api/admin/bars/:id', requireAdmin, (req, res) => {
  const bar = db.prepare('SELECT * FROM bars WHERE id = ?').get(req.params.id);
  if (!bar) return res.status(404).json({ error: '贴吧不存在' });
  const moduleKey = text(req.body.module) || bar.module;
  const name = text(req.body.name) || bar.name;
  const description = text(req.body.desc) || bar.description;
  const module = MODULES[moduleKey];
  if (!module) fail('请选择所属模块');
  if (name.length < 2 || name.length > 12) fail('贴吧名称需为 2 - 12 个字');
  if (db.prepare('SELECT 1 AS ok FROM bars WHERE name = ? AND id <> ?').get(name, bar.id)) fail('该贴吧名称已存在', 409);

  db.prepare('UPDATE bars SET module = ?, name = ?, description = ?, icon = ? WHERE id = ?')
    .run(moduleKey, name, description, module.icon, bar.id);
  res.json(barJson(db.prepare('SELECT * FROM bars WHERE id = ?').get(bar.id)));
});

app.delete('/api/admin/bars/:id', requireAdmin, (req, res) => {
  const bar = db.prepare('SELECT * FROM bars WHERE id = ?').get(req.params.id);
  if (!bar) return res.status(404).json({ error: '贴吧不存在' });
  db.exec('BEGIN');
  try {
    db.prepare('UPDATE posts SET deleted = 1, deleted_at = ?, deleted_by = ? WHERE bar_id = ? AND deleted = 0')
      .run(now(), req.user.id, bar.id);
    db.prepare('DELETE FROM bars WHERE id = ?').run(bar.id);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
  res.json({ ok: true, id: bar.id });
});

app.use((_req, res) => res.status(404).json({ error: '接口不存在' }));

app.use((error, _req, res, _next) => {
  const status = error.status || 500;
  if (status >= 500) console.error(error);
  res.status(status).json({ error: error.expose ? error.message : '服务器内部错误' });
});

const server = app.listen(PORT, HOST, () => {
  console.log(`[wszz-wall] listening on http://${HOST}:${PORT}`);
});

function shutdown() {
  server.close(() => {
    try { db.close(); } catch (_) {}
    process.exit(0);
  });
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
