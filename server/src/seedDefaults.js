const now = () => Date.now();

const SHOP_ITEMS = [
  { id: 'frame_gold', type: 'frame', name: '鎏金头像框', description: '暖金色描边，低调但有存在感', value: 'gold', price: 100, sort: 1 },
  { id: 'frame_neon', type: 'frame', name: '霓虹头像框', description: '青紫渐变光效，适合夜猫子', value: 'neon', price: 160, sort: 2 },
  { id: 'frame_sakura', type: 'frame', name: '樱花头像框', description: '粉色柔光，春天限定氛围', value: 'sakura', price: 200, sort: 3 },
  { id: 'frame_tech', type: 'frame', name: '科技头像框', description: '青绿电路感，极客专属', value: 'tech', price: 260, sort: 4 },

  { id: 'color_gold', type: 'color', name: '金色昵称', description: '把昵称变成暖金色', value: '#F5B301', price: 80, sort: 1 },
  { id: 'color_pink', type: 'color', name: '樱花粉昵称', description: '柔和粉色昵称', value: '#FF6B9D', price: 80, sort: 2 },
  { id: 'color_cyan', type: 'color', name: '科技青昵称', description: '清爽的青蓝色昵称', value: '#22D3EE', price: 100, sort: 3 },
  { id: 'color_purple', type: 'color', name: '星空紫昵称', description: '深空紫色昵称', value: '#A78BFA', price: 120, sort: 4 },

  { id: 'title_star', type: 'title', name: '校园之星', description: '在墙上闪闪发光的称号', value: '校园之星', price: 300, sort: 1 },
  { id: 'title_helper', type: 'title', name: '热心同学', description: '乐于帮助别人的称号', value: '热心同学', price: 200, sort: 2 },
  { id: 'title_night', type: 'title', name: '夜猫子', description: '深夜也在线的称号', value: '夜猫子', price: 150, sort: 3 },
];

const DAILY_TASKS = [
  { id: 'task_login', title: '每日登录', description: '每天第一次进入乌市职专墙', type: 'login', points: 5 },
  { id: 'task_checkin', title: '今日打卡', description: '在任务中心手动领取', type: 'manual', points: 5 },
  { id: 'task_post', title: '发布一条帖子', description: '在任意贴吧发布一条内容', type: 'post', points: 10 },
  { id: 'task_comment', title: '发表一条评论', description: '给同学的帖子留下友善评论', type: 'comment', points: 5 },
  { id: 'task_like', title: '点赞一次', description: '给喜欢的帖子点个赞', type: 'like', points: 2 },
];

const ABOUT_TEXT = '乌市职专墙是面向校园的互助社区，包含寻物、吐槽、表白、找人四个板块。\n\n在这里，丢失的东西有机会找回来，想说的话可以被看见。请友善发言，共同维护校园社区环境。\n\n当前为联网版本，账号与内容保存在学校社区服务器。';

module.exports = function seedDefaults(db) {
  const insertItem = db.prepare('INSERT OR IGNORE INTO shop_items (id, type, name, description, value, price, sort, active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)');
  for (const item of SHOP_ITEMS) {
    insertItem.run(item.id, item.type, item.name, item.description, item.value, item.price, item.sort);
  }

  const taskCount = db.prepare('SELECT COUNT(*) AS n FROM daily_tasks').get().n;
  if (taskCount === 0) {
    const insertTask = db.prepare('INSERT INTO daily_tasks (id, title, description, type, points, active, created_at) VALUES (?, ?, ?, ?, ?, 1, ?)');
    for (const task of DAILY_TASKS) {
      insertTask.run(task.id, task.title, task.description, task.type, task.points, now());
    }
  }

  const insertSetting = db.prepare('INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)');
  insertSetting.run('about_text', ABOUT_TEXT);
  insertSetting.run('version', 'V1.01');
};
