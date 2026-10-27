const path = require('node:path');
require('dotenv').config({ path: process.env.ENV_FILE || path.join(__dirname, '..', '.env') });

const crypto = require('node:crypto');
const fs = require('node:fs');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const db = require('./db');
const { signToken, publicUser, optionalAuth, requireAuth, requireAdmin, SECRET } = require('./auth');
const { barJson, messageJson, postJson } = require('./serialize');

const app = express();
const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '127.0.0.1';

app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({ origin: true }));
app.use(express.json({ limit: '6mb' }));

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '..', 'uploads');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });
app.use('/uploads', express.static(UPLOAD_DIR, { maxAge: '30d' }));
app.use(rateLimit({
  windowMs: 60 * 1000,
  limit: 180,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: '请求过于频繁，请稍后再试' },
}));

const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 30,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: '操作过于频繁，请稍后再试' },
});

const MODULES = {
  lost: { icon: 'search' },
  rant: { icon: 'bolt' },
  confess: { icon: 'heart' },
  find: { icon: 'users' },
  general: { icon: 'grid' },
};
const TASK_TYPES = ['login', 'post', 'comment', 'like', 'manual'];

const now = () => Date.now();
const newId = (prefix) => prefix + crypto.randomBytes(6).toString('hex');
const text = (value) => (typeof value === 'string' ? value.trim() : '');

function todayKey() {
  const d = new Date(Date.now() + 8 * 3600 * 1000);
  return d.toISOString().slice(0, 10);
}

function fail(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  error.expose = true;
  throw error;
}

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function getFreshUser(id) {
  return db.prepare('SELECT * FROM users WHERE id = ?').get(id);
}

function stats() {
  const cutoff = Date.now() - 5 * 60 * 1000;
  const total = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
  const online = db.prepare('SELECT COUNT(*) AS n FROM users WHERE online = 1 AND banned = 0 AND last_active > ?').get(cutoff).n;
  const banned = db.prepare('SELECT COUNT(*) AS n FROM users WHERE banned = 1').get().n;
  const pendingPosts = db.prepare("SELECT COUNT(*) AS n FROM posts WHERE deleted = 0 AND status = 'pending'").get().n;
  const pendingAvatars = db.prepare("SELECT COUNT(*) AS n FROM users WHERE avatar_pending <> ''").get().n;
  return { total, online, banned, pendingPosts, pendingAvatars };
}

function addMessage(userId, type, title, content) {
  db.prepare('INSERT INTO messages (id, user_id, type, title, content, created_at, unread) VALUES (?, ?, ?, ?, ?, ?, 1)')
    .run(newId('m'), userId, type, title, content, now());
}

function settingsMap() {
  const map = {};
  for (const row of db.prepare('SELECT key, value FROM settings').all()) {
    map[row.key] = row.value;
  }
  return {
    aboutText: map.about_text || '',
    version: map.version || 'V1.01',
  };
}

function taskList(userId) {
  const date = todayKey();
  const tasks = db.prepare('SELECT * FROM daily_tasks WHERE active = 1 ORDER BY created_at ASC').all();
  return tasks.map((task) => {
    const done = !!db.prepare('SELECT 1 AS ok FROM task_progress WHERE user_id = ? AND task_id = ? AND date = ?')
      .get(userId, task.id, date);
    return {
      id: task.id,
      title: task.title,
      description: task.description,
      type: task.type,
      points: task.points,
      completed: done,
      claimed: done,
    };
  });
}

function shopList(userId) {
  const user = getFreshUser(userId);
  const owned = new Set(db.prepare('SELECT item_id FROM user_items WHERE user_id = ?').all(userId).map((row) => row.item_id));
  return db.prepare('SELECT * FROM shop_items WHERE active = 1 ORDER BY type ASC, sort ASC, price ASC').all().map((item) => {
    let equipped = false;
    if (item.type === 'frame') equipped = user.equipped_frame === item.id;
    if (item.type === 'color') equipped = user.equipped_color === item.id;
    if (item.type === 'title') equipped = user.title === item.value;
    return {
      id: item.id,
      type: item.type,
      name: item.name,
      description: item.description,
      value: item.value,
      price: item.price,
      owned: owned.has(item.id),
      equipped,
    };
  });
}

function announcementList(userId) {
  return db.prepare('SELECT * FROM announcements WHERE active = 1 ORDER BY created_at DESC').all().map((row) => ({
    id: row.id,
    title: row.title,
    content: row.content,
    important: !!row.important,
    createdAt: row.created_at,
    read: !!db.prepare('SELECT 1 AS ok FROM announcement_reads WHERE user_id = ? AND announcement_id = ?').get(userId, row.id),
  }));
}

function awardTaskType(userId, type) {
  const date = todayKey();
  const tasks = db.prepare('SELECT * FROM daily_tasks WHERE active = 1 AND type = ?').all(type);
  let awarded = 0;
  db.exec('BEGIN');
  try {
    for (const task of tasks) {
      const exists = db.prepare('SELECT 1 AS ok FROM task_progress WHERE user_id = ? AND task_id = ? AND date = ?')
        .get(userId, task.id, date);
      if (exists) continue;
      db.prepare('INSERT INTO task_progress (user_id, task_id, date, created_at) VALUES (?, ?, ?, ?)')
        .run(userId, task.id, date, now());
      db.prepare('UPDATE users SET points = points + ? WHERE id = ?').run(task.points, userId);
      awarded += task.points;
    }
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
  return awarded;
}

function getPostRow(id) {
  return db.prepare('SELECT * FROM posts WHERE id = ? AND deleted = 0').get(id);
}

const IMAGE_EXT = { 'image/jpeg': 'jpg', 'image/jpg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };

function saveImage(data, prefix) {
  const raw = text(data);
  if (!raw) return '';
  const match = /^data:(image\/[a-z+]+);base64,([A-Za-z0-9+/=\s]+)$/i.exec(raw);
  if (!match || !IMAGE_EXT[match[1].toLowerCase()]) {
    fail('图片格式不支持，请选择 JPG、PNG 或 WEBP 图片');
  }
  const buffer = Buffer.from(match[2], 'base64');
  if (!buffer.length) fail('图片内容为空');
  if (buffer.length > 3 * 1024 * 1024) fail('图片不能超过 3MB');
  const name = `${prefix}_${Date.now()}_${crypto.randomBytes(4).toString('hex')}.${IMAGE_EXT[match[1].toLowerCase()]}`;
  fs.writeFileSync(path.join(UPLOAD_DIR, name), buffer);
  return `/uploads/${name}`;
}

function canSeePost(row, viewer) {
  if (!row) return false;
  if (row.status === 'approved' || !row.status) return true;
  if (!viewer) return false;
  return viewer.role === 'admin' || row.author_id === viewer.id;
}

function createCaptcha() {
  const ops = ['+', '-', '×', '÷'];
  const op = ops[Math.floor(Math.random() * ops.length)];
  let a;
  let b;
  let answer;
  if (op === '+') {
    a = 2 + Math.floor(Math.random() * 18);
    b = 2 + Math.floor(Math.random() * 18);
    answer = a + b;
  } else if (op === '-') {
    a = 5 + Math.floor(Math.random() * 16);
    b = 1 + Math.floor(Math.random() * (a - 1));
    answer = a - b;
  } else if (op === '×') {
    a = 2 + Math.floor(Math.random() * 8);
    b = 2 + Math.floor(Math.random() * 8);
    answer = a * b;
  } else {
    b = 2 + Math.floor(Math.random() * 8);
    answer = 2 + Math.floor(Math.random() * 8);
    a = b * answer;
  }
  const token = jwt.sign({ kind: 'captcha', ans: answer }, SECRET, { expiresIn: '5m' });
  return { token, question: `${a} ${op} ${b} = ?` };
}

function verifyCaptcha(token, answer) {
  try {
    const payload = jwt.verify(token, SECRET);
    if (payload.kind !== 'captcha' || typeof payload.ans !== 'number') return false;
    return Number(answer) === payload.ans;
  } catch (_) {
    return false;
  }
}

/* ---------------- 基础 ---------------- */

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'wszz-wall', time: now() });
});

app.get('/api/auth/captcha', authLimiter, (_req, res) => {
  res.json(createCaptcha());
});

/* ---------------- 认证 ---------------- */

app.post('/api/auth/register', authLimiter, wrap(async (req, res) => {
  const username = text(req.body.username);
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  const realName = text(req.body.realName);
  const className = text(req.body.className);
  const showProfile = !!req.body.showProfile;
  const nickname = text(req.body.nickname) || realName;

  if (!verifyCaptcha(text(req.body.captchaToken), req.body.captchaAnswer)) fail('验证码不正确或已过期');
  if (!/^[a-zA-Z0-9_]{3,16}$/.test(username)) fail('账号需为 3 - 16 位字母、数字或下划线');
  if (password.length < 6) fail('密码至少需要 6 位');
  if (realName.length < 1 || realName.length > 20) fail('姓名需为 1 - 20 个字');
  if (className.length < 1 || className.length > 20) fail('班级需为 1 - 20 个字');
  if (nickname.length < 1 || nickname.length > 12) fail('昵称需为 1 - 12 个字');
  if (db.prepare('SELECT 1 AS ok FROM users WHERE username = ?').get(username)) fail('该账号已被注册', 409);

  const id = newId('u');
  db.prepare(`INSERT INTO users
    (id, username, password_hash, nickname, role, banned, online, avatar, bio, joined_at, last_active,
     real_name, class_name, show_profile, points)
    VALUES (?, ?, ?, ?, 'user', 0, 1, ?, ?, ?, ?, ?, ?, ?, 0)`)
    .run(id, username, await bcrypt.hash(password, 10), nickname,
      Math.floor(Math.random() * 6), '这位同学还没有写简介', now(), now(),
      realName, className, showProfile ? 1 : 0);
  addMessage(id, 'system', '欢迎来到乌市职专墙', '请友善发言，共同维护校园社区环境。');

  const user = getFreshUser(id);
  res.status(201).json({ token: signToken(user), user: publicUser(user, user) });
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
  const fresh = getFreshUser(user.id);
  res.json({ token: signToken(fresh), user: publicUser(fresh, fresh) });
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
  awardTaskType(me.id, 'login');
  const fresh = getFreshUser(me.id);

  const users = db.prepare('SELECT * FROM users').all().map((row) => publicUser(row, fresh));
  const bars = db.prepare('SELECT * FROM bars ORDER BY created_at ASC').all().map(barJson);
  const posts = db.prepare('SELECT * FROM posts WHERE deleted = 0 ORDER BY created_at DESC').all()
    .filter((row) => fresh.role === 'admin' || canSeePost(row, fresh))
    .map((row) => postJson(row, fresh.id));
  const messages = db.prepare('SELECT * FROM messages WHERE user_id = ? ORDER BY created_at DESC').all(fresh.id)
    .map(messageJson);

  res.json({
    user: publicUser(fresh, fresh),
    users,
    bars,
    posts,
    messages,
    tasks: taskList(fresh.id),
    shopItems: shopList(fresh.id),
    announcements: announcementList(fresh.id),
    settings: settingsMap(),
    stats: fresh.role === 'admin' ? stats() : null,
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
  rows = rows.filter((row) => canSeePost(row, me));
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
  if (!row || !canSeePost(row, req.user)) return res.status(404).json({ error: '帖子不存在或已被删除' });
  res.json(postJson(row, req.user && req.user.id));
});

app.post('/api/posts', requireAuth, (req, res) => {
  const barId = text(req.body.barId);
  const title = text(req.body.title);
  const content = text(req.body.content);
  const anonymous = !!req.body.anonymous;
  const imageUrl = saveImage(req.body.image, `post_${req.user.id}`);

  if (!db.prepare('SELECT 1 AS ok FROM bars WHERE id = ?').get(barId)) fail('请选择要发布到的贴吧');
  if (title.length < 4) fail('标题至少需要 4 个字');
  if (title.length > 40) fail('标题不能超过 40 个字');
  if (content.length < 6) fail('正文至少需要 6 个字');
  if (content.length > 1000) fail('正文不能超过 1000 个字');

  const status = req.user.role === 'admin' ? 'approved' : 'pending';
  const id = newId('p');
  db.prepare(`INSERT INTO posts
    (id, bar_id, author_id, title, content, anonymous, likes, created_at, image_url, status)
    VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?)`)
    .run(id, barId, req.user.id, title, content, anonymous ? 1 : 0, now(), imageUrl, status);
  if (status === 'approved') awardTaskType(req.user.id, 'post');
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
  if (!row || !canSeePost(row, req.user)) return res.status(404).json({ error: '帖子不存在' });

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
  if (!liked) awardTaskType(req.user.id, 'like');
  res.json(postJson(getPostRow(row.id), req.user.id));
});

app.post('/api/posts/:id/comments', requireAuth, (req, res) => {
  const row = getPostRow(req.params.id);
  if (!row || !canSeePost(row, req.user)) return res.status(404).json({ error: '帖子不存在' });
  const content = text(req.body.content);
  if (!content) fail('评论内容不能为空');
  if (content.length > 200) fail('评论不能超过 200 字');

  db.prepare('INSERT INTO comments (id, post_id, author_id, content, created_at) VALUES (?, ?, ?, ?, ?)')
    .run(newId('c'), row.id, req.user.id, content, now());
  if (row.author_id !== req.user.id) {
    addMessage(row.author_id, 'comment', `${req.user.nickname} 回复了你`, `「${content.slice(0, 60)}」`);
  }
  awardTaskType(req.user.id, 'comment');
  res.status(201).json(postJson(getPostRow(row.id), req.user.id));
});

/* ---------------- 个人资料 / 积分 / 商店 / 任务 ---------------- */

app.patch('/api/me/profile', requireAuth, (req, res) => {
  const user = getFreshUser(req.user.id);
  const nickname = req.body.nickname === undefined ? user.nickname : text(req.body.nickname);
  const realName = req.body.realName === undefined ? user.real_name : text(req.body.realName);
  const className = req.body.className === undefined ? user.class_name : text(req.body.className);
  const bio = req.body.bio === undefined ? user.bio : text(req.body.bio);
  const showProfile = req.body.showProfile === undefined ? !!user.show_profile : !!req.body.showProfile;
  const avatar = req.body.avatar === undefined ? user.avatar : Number(req.body.avatar);

  if (nickname.length < 1 || nickname.length > 12) fail('昵称需为 1 - 12 个字');
  if (realName.length > 20) fail('姓名不能超过 20 个字');
  if (className.length > 20) fail('班级不能超过 20 个字');
  if (bio.length > 100) fail('简介不能超过 100 个字');
  if (!Number.isInteger(avatar) || avatar < 0 || avatar > 5) fail('请选择有效头像');

  let frameId = user.equipped_frame;
  if (req.body.equippedFrameId !== undefined) {
    frameId = text(req.body.equippedFrameId);
    if (frameId) {
      const item = db.prepare("SELECT * FROM shop_items WHERE id = ? AND type = 'frame' AND active = 1").get(frameId);
      const owned = db.prepare('SELECT 1 AS ok FROM user_items WHERE user_id = ? AND item_id = ?').get(user.id, frameId);
      if (!item || !owned) fail('尚未拥有该头像框');
    }
  }

  let colorId = user.equipped_color;
  if (req.body.equippedColorId !== undefined) {
    colorId = text(req.body.equippedColorId);
    if (colorId) {
      const item = db.prepare("SELECT * FROM shop_items WHERE id = ? AND type = 'color' AND active = 1").get(colorId);
      const owned = db.prepare('SELECT 1 AS ok FROM user_items WHERE user_id = ? AND item_id = ?').get(user.id, colorId);
      if (!item || !owned) fail('尚未拥有该昵称颜色');
    }
  }

  let title = user.title;
  if (req.body.title !== undefined) {
    title = text(req.body.title);
    if (title) {
      const ownedTitle = db.prepare(`SELECT 1 AS ok FROM user_items ui
        JOIN shop_items si ON si.id = ui.item_id
        WHERE ui.user_id = ? AND si.type = 'title' AND si.value = ?`).get(user.id, title);
      if (title !== (user.granted_title || '') && !ownedTitle) fail('尚未拥有该称号');
    }
  }

  db.prepare(`UPDATE users SET nickname = ?, real_name = ?, class_name = ?, bio = ?, show_profile = ?,
    avatar = ?, equipped_frame = ?, equipped_color = ?, title = ? WHERE id = ?`)
    .run(nickname, realName, className, bio, showProfile ? 1 : 0, avatar, frameId, colorId, title, user.id);

  const fresh = getFreshUser(user.id);
  res.json({
    user: publicUser(fresh, fresh),
    shopItems: shopList(fresh.id),
    tasks: taskList(fresh.id),
  });
});

app.post('/api/me/avatar', requireAuth, (req, res) => {
  const user = getFreshUser(req.user.id);
  const url = saveImage(req.body.image, `avatar_${user.id}`);
  if (!url) fail('请选择要上传的图片');
  db.prepare("UPDATE users SET avatar_pending = ?, avatar_status = 'pending' WHERE id = ?")
    .run(url, user.id);
  const fresh = getFreshUser(user.id);
  res.json({
    user: publicUser(fresh, fresh),
    shopItems: shopList(fresh.id),
    tasks: taskList(fresh.id),
  });
});

app.post('/api/shop/buy', requireAuth, (req, res) => {
  const itemId = text(req.body.itemId);
  const item = db.prepare('SELECT * FROM shop_items WHERE id = ? AND active = 1').get(itemId);
  if (!item) fail('商品不存在或已下架');
  const user = getFreshUser(req.user.id);
  if (db.prepare('SELECT 1 AS ok FROM user_items WHERE user_id = ? AND item_id = ?').get(user.id, item.id)) {
    fail('你已经拥有这个装扮');
  }
  if (user.points < item.price) fail('积分不足，完成任务可以获取积分');

  db.exec('BEGIN');
  try {
    db.prepare('UPDATE users SET points = points - ? WHERE id = ?').run(item.price, user.id);
    db.prepare('INSERT INTO user_items (user_id, item_id, acquired_at) VALUES (?, ?, ?)').run(user.id, item.id, now());
    if (item.type === 'frame') db.prepare('UPDATE users SET equipped_frame = ? WHERE id = ?').run(item.id, user.id);
    if (item.type === 'color') db.prepare('UPDATE users SET equipped_color = ? WHERE id = ?').run(item.id, user.id);
    if (item.type === 'title') db.prepare('UPDATE users SET title = ? WHERE id = ?').run(item.value, user.id);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }

  const fresh = getFreshUser(user.id);
  res.json({
    user: publicUser(fresh, fresh),
    shopItems: shopList(fresh.id),
    tasks: taskList(fresh.id),
  });
});

app.post('/api/tasks/:id/claim', requireAuth, (req, res) => {
  const task = db.prepare('SELECT * FROM daily_tasks WHERE id = ? AND active = 1').get(req.params.id);
  if (!task) fail('任务不存在或已下架', 404);
  if (task.type !== 'manual') fail('该任务会在完成对应操作后自动发放积分');
  const date = todayKey();
  if (db.prepare('SELECT 1 AS ok FROM task_progress WHERE user_id = ? AND task_id = ? AND date = ?').get(req.user.id, task.id, date)) {
    fail('今天已经领取过这个任务了');
  }

  db.exec('BEGIN');
  try {
    db.prepare('INSERT INTO task_progress (user_id, task_id, date, created_at) VALUES (?, ?, ?, ?)')
      .run(req.user.id, task.id, date, now());
    db.prepare('UPDATE users SET points = points + ? WHERE id = ?').run(task.points, req.user.id);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }

  const fresh = getFreshUser(req.user.id);
  res.json({
    user: publicUser(fresh, fresh),
    tasks: taskList(fresh.id),
    shopItems: shopList(fresh.id),
  });
});

/* ---------------- 公告 ---------------- */

app.post('/api/announcements/:id/read', requireAuth, (req, res) => {
  const row = db.prepare('SELECT * FROM announcements WHERE id = ? AND active = 1').get(req.params.id);
  if (!row) return res.status(404).json({ error: '公告不存在' });
  db.prepare('INSERT OR IGNORE INTO announcement_reads (user_id, announcement_id, read_at) VALUES (?, ?, ?)')
    .run(req.user.id, row.id, now());
  res.json({ ok: true });
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
  res.json(rows.map((row) => publicUser(row, req.user)));
});

app.post('/api/admin/users/:id/ban', requireAdmin, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  if (user.role === 'admin') fail('管理员账号不可封禁');
  if (user.id === req.user.id) fail('不能封禁当前登录账号');
  const banned = user.banned ? 0 : 1;
  db.prepare('UPDATE users SET banned = ?, online = CASE WHEN ? = 1 THEN 0 ELSE online END WHERE id = ?')
    .run(banned, banned, user.id);
  res.json(publicUser(getFreshUser(user.id), req.user));
});

app.post('/api/admin/users/:id/password', requireAdmin, wrap(async (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  if (password.length < 6) fail('新密码至少需要 6 位');
  db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(await bcrypt.hash(password, 10), user.id);
  res.json({ ok: true });
}));

app.post('/api/admin/users/:id/title', requireAdmin, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  const title = text(req.body.title);
  if (title.length > 12) fail('称号不能超过 12 个字');
  const oldGranted = user.granted_title || '';
  if (title) {
    db.prepare('UPDATE users SET granted_title = ?, title = ? WHERE id = ?').run(title, title, user.id);
  } else {
    db.prepare("UPDATE users SET granted_title = '' WHERE id = ?").run(user.id);
    if (user.title === oldGranted) {
      db.prepare("UPDATE users SET title = '' WHERE id = ?").run(user.id);
    }
  }
  res.json(publicUser(getFreshUser(user.id), req.user));
});

app.post('/api/admin/users/:id/points', requireAdmin, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  const delta = Number(req.body.delta);
  if (!Number.isInteger(delta) || delta === 0) fail('请输入非零的整数积分');
  if (Math.abs(delta) > 10000) fail('单次调整不能超过 10000 积分');
  const next = Math.max(0, user.points + delta);
  db.prepare('UPDATE users SET points = ? WHERE id = ?').run(next, user.id);
  addMessage(
    user.id,
    'system',
    delta > 0 ? '积分增加' : '积分调整',
    delta > 0 ? `管理员为你增加了 ${delta} 积分` : `管理员为你扣减了 ${-delta} 积分`,
  );
  res.json(publicUser(getFreshUser(user.id), req.user));
});

app.get('/api/admin/posts/pending', requireAdmin, (req, res) => {
  const rows = db.prepare("SELECT * FROM posts WHERE deleted = 0 AND status = 'pending' ORDER BY created_at ASC").all();
  res.json(rows.map((row) => postJson(row, req.user.id)));
});

app.post('/api/admin/posts/:id/review', requireAdmin, (req, res) => {
  const row = getPostRow(req.params.id);
  if (!row) return res.status(404).json({ error: '帖子不存在或已被删除' });
  const approve = !!req.body.approve;
  const reason = text(req.body.reason);
  if (!approve && !reason) fail('请填写不通过的理由');
  if (reason.length > 100) fail('理由不能超过 100 个字');

  db.prepare('UPDATE posts SET status = ?, reject_reason = ? WHERE id = ?')
    .run(approve ? 'approved' : 'rejected', approve ? '' : reason, row.id);
  if (approve) {
    awardTaskType(row.author_id, 'post');
    addMessage(row.author_id, 'system', '帖子已通过审核', `「${row.title}」已通过审核，展示在贴吧中。`);
  } else {
    addMessage(row.author_id, 'system', '帖子未通过审核', `「${row.title}」未通过审核：${reason}`);
  }
  res.json(postJson(getPostRow(row.id), req.user.id));
});

app.get('/api/admin/avatars', requireAdmin, (req, res) => {
  const rows = db.prepare("SELECT * FROM users WHERE avatar_pending <> '' ORDER BY joined_at ASC").all();
  res.json(rows.map((row) => ({
    user: publicUser(row, req.user),
    pendingUrl: row.avatar_pending,
  })));
});

app.post('/api/admin/avatars/:id/review', requireAdmin, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  if (!user.avatar_pending) fail('该用户没有待审核的头像');
  if (req.body.approve) {
    db.prepare("UPDATE users SET avatar_url = avatar_pending, avatar_pending = '', avatar_status = 'approved' WHERE id = ?")
      .run(user.id);
    addMessage(user.id, 'system', '头像审核通过', '你上传的新头像已通过审核。');
  } else {
    db.prepare("UPDATE users SET avatar_pending = '', avatar_status = 'rejected' WHERE id = ?").run(user.id);
    addMessage(user.id, 'system', '头像未通过审核', '你上传的头像未通过审核，请更换后重新提交。');
  }
  res.json(publicUser(getFreshUser(user.id), req.user));
});

app.post('/api/admin/bars', requireAdmin, (req, res) => {
  const name = text(req.body.name);
  const description = text(req.body.desc);
  if (name.length < 2 || name.length > 12) fail('贴吧名称需为 2 - 12 个字');
  if (db.prepare('SELECT 1 AS ok FROM bars WHERE name = ?').get(name)) fail('该贴吧名称已存在', 409);

  const id = newId('b');
  db.prepare('INSERT INTO bars (id, module, name, description, icon, members, created_at) VALUES (?, ?, ?, ?, ?, 0, ?)')
    .run(id, 'general', name, description || '这个贴吧还没有介绍', MODULES.general.icon, now());
  res.status(201).json(barJson(db.prepare('SELECT * FROM bars WHERE id = ?').get(id)));
});

app.patch('/api/admin/bars/:id', requireAdmin, (req, res) => {
  const bar = db.prepare('SELECT * FROM bars WHERE id = ?').get(req.params.id);
  if (!bar) return res.status(404).json({ error: '贴吧不存在' });
  const moduleKey = req.body.module === undefined ? bar.module : text(req.body.module);
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

app.get('/api/admin/tasks', requireAdmin, (_req, res) => {
  res.json(db.prepare('SELECT * FROM daily_tasks WHERE active = 1 ORDER BY created_at ASC').all());
});

app.post('/api/admin/tasks', requireAdmin, (req, res) => {
  const title = text(req.body.title);
  const description = text(req.body.description);
  const type = text(req.body.type);
  const points = Number(req.body.points);
  if (title.length < 1 || title.length > 20) fail('任务名称需为 1 - 20 个字');
  if (description.length > 60) fail('任务说明不能超过 60 个字');
  if (!TASK_TYPES.includes(type)) fail('请选择有效的任务类型');
  if (!Number.isInteger(points) || points < 1 || points > 100) fail('积分需为 1 - 100 的整数');
  const id = newId('t');
  db.prepare('INSERT INTO daily_tasks (id, title, description, type, points, active, created_at) VALUES (?, ?, ?, ?, ?, 1, ?)')
    .run(id, title, description, type, points, now());
  const row = db.prepare('SELECT * FROM daily_tasks WHERE id = ?').get(id);
  res.status(201).json(row);
});

app.delete('/api/admin/tasks/:id', requireAdmin, (req, res) => {
  const task = db.prepare('SELECT * FROM daily_tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ error: '任务不存在' });
  db.prepare('DELETE FROM daily_tasks WHERE id = ?').run(task.id);
  res.json({ ok: true, id: task.id });
});

app.get('/api/admin/announcements', requireAdmin, (_req, res) => {
  res.json(db.prepare('SELECT * FROM announcements WHERE active = 1 ORDER BY created_at DESC').all().map((row) => ({
    id: row.id,
    title: row.title,
    content: row.content,
    important: !!row.important,
    createdAt: row.created_at,
  })));
});

app.post('/api/admin/announcements', requireAdmin, (req, res) => {
  const title = text(req.body.title);
  const content = text(req.body.content);
  const important = !!req.body.important;
  if (title.length < 1 || title.length > 30) fail('公告标题需为 1 - 30 个字');
  if (content.length < 1 || content.length > 2000) fail('公告内容需为 1 - 2000 个字');
  const id = newId('a');
  db.prepare('INSERT INTO announcements (id, title, content, important, active, created_at, created_by) VALUES (?, ?, ?, ?, 1, ?, ?)')
    .run(id, title, content, important ? 1 : 0, now(), req.user.id);
  db.prepare('INSERT OR IGNORE INTO announcement_reads (user_id, announcement_id, read_at) VALUES (?, ?, ?)')
    .run(req.user.id, id, now());
  const row = db.prepare('SELECT * FROM announcements WHERE id = ?').get(id);
  res.status(201).json({
    id: row.id,
    title: row.title,
    content: row.content,
    important: !!row.important,
    createdAt: row.created_at,
  });
});

app.delete('/api/admin/announcements/:id', requireAdmin, (req, res) => {
  const row = db.prepare('SELECT * FROM announcements WHERE id = ?').get(req.params.id);
  if (!row) return res.status(404).json({ error: '公告不存在' });
  db.prepare('DELETE FROM announcements WHERE id = ?').run(row.id);
  res.json({ ok: true, id: row.id });
});

app.get('/api/admin/settings', requireAdmin, (_req, res) => {
  res.json(settingsMap());
});

app.patch('/api/admin/settings', requireAdmin, (req, res) => {
  const aboutText = text(req.body.aboutText);
  if (aboutText.length < 10 || aboutText.length > 2000) fail('关于文案需为 10 - 2000 个字');
  db.prepare("INSERT INTO settings (key, value) VALUES ('about_text', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value")
    .run(aboutText);
  res.json(settingsMap());
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
