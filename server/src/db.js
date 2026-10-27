const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');
const seed = require('./seed');
const seedDefaults = require('./seedDefaults');

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data.sqlite');
const db = new DatabaseSync(dbPath);

db.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA foreign_keys = ON;

  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    nickname TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    banned INTEGER NOT NULL DEFAULT 0,
    online INTEGER NOT NULL DEFAULT 0,
    avatar INTEGER NOT NULL DEFAULT 0,
    bio TEXT NOT NULL DEFAULT '',
    joined_at INTEGER NOT NULL,
    last_active INTEGER,
    real_name TEXT NOT NULL DEFAULT '',
    class_name TEXT NOT NULL DEFAULT '',
    show_profile INTEGER NOT NULL DEFAULT 0,
    points INTEGER NOT NULL DEFAULT 0,
    equipped_frame TEXT NOT NULL DEFAULT '',
    equipped_color TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL DEFAULT '',
    granted_title TEXT NOT NULL DEFAULT ''
  );

  CREATE TABLE IF NOT EXISTS bars (
    id TEXT PRIMARY KEY,
    module TEXT NOT NULL,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    icon TEXT NOT NULL DEFAULT 'search',
    members INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS posts (
    id TEXT PRIMARY KEY,
    bar_id TEXT NOT NULL,
    author_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    anonymous INTEGER NOT NULL DEFAULT 0,
    likes INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER,
    deleted_by TEXT
  );

  CREATE TABLE IF NOT EXISTS post_likes (
    post_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    PRIMARY KEY (post_id, user_id)
  );

  CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY,
    post_id TEXT NOT NULL,
    author_id TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    unread INTEGER NOT NULL DEFAULT 1
  );

  CREATE TABLE IF NOT EXISTS shop_items (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    value TEXT NOT NULL DEFAULT '',
    price INTEGER NOT NULL DEFAULT 0,
    sort INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
  );

  CREATE TABLE IF NOT EXISTS user_items (
    user_id TEXT NOT NULL,
    item_id TEXT NOT NULL,
    acquired_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, item_id)
  );

  CREATE TABLE IF NOT EXISTS daily_tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL,
    points INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS task_progress (
    user_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    date TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, task_id, date)
  );

  CREATE TABLE IF NOT EXISTS announcements (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    important INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    created_by TEXT
  );

  CREATE TABLE IF NOT EXISTS announcement_reads (
    user_id TEXT NOT NULL,
    announcement_id TEXT NOT NULL,
    read_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, announcement_id)
  );

  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_posts_bar ON posts(bar_id, created_at);
  CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id, created_at);
  CREATE INDEX IF NOT EXISTS idx_messages_user ON messages(user_id, created_at);
  CREATE INDEX IF NOT EXISTS idx_likes_post ON post_likes(post_id);
  CREATE INDEX IF NOT EXISTS idx_task_user ON task_progress(user_id, date);
  CREATE INDEX IF NOT EXISTS idx_announcement_reads ON announcement_reads(user_id, announcement_id);
`);

function ensureColumn(table, column, definition) {
  const columns = db.prepare(`PRAGMA table_info(${table})`).all();
  if (!columns.some((item) => item.name === column)) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
  }
}

ensureColumn('users', 'real_name', "TEXT NOT NULL DEFAULT ''");
ensureColumn('users', 'class_name', "TEXT NOT NULL DEFAULT ''");
ensureColumn('users', 'show_profile', 'INTEGER NOT NULL DEFAULT 0');
ensureColumn('users', 'points', 'INTEGER NOT NULL DEFAULT 0');
ensureColumn('users', 'equipped_frame', "TEXT NOT NULL DEFAULT ''");
ensureColumn('users', 'equipped_color', "TEXT NOT NULL DEFAULT ''");
ensureColumn('users', 'title', "TEXT NOT NULL DEFAULT ''");
ensureColumn('users', 'granted_title', "TEXT NOT NULL DEFAULT ''");

seed(db);
seedDefaults(db);

module.exports = db;
