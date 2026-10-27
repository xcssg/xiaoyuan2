/* 乌市职专墙 · 本地数据层（UI 阶段用 localStorage 模拟服务端） */
(function () {
  var KEY = 'wszz_wall_state_v2';
  var THEME_KEY = 'wszz_wall_theme';

  var MODULES = [
    { key: 'lost', name: '寻物', label: '校园寻物', desc: '丢东西、捡东西，都来这里碰个运气', icon: 'search', color: '#3b82f6' },
    { key: 'rant', name: '吐槽', label: '校园吐槽', desc: '校内大小事，不吐不快', icon: 'bolt', color: '#f59e0b' },
    { key: 'confess', name: '表白', label: '校园表白', desc: '把心动说出口，匿名也可以', icon: 'heart', color: '#ec4899' },
    { key: 'find', name: '找人', label: '校园找人', desc: '找同学、找队友、找一面之缘', icon: 'users', color: '#14b8a6' }
  ];

  var state = null;

  function clone(o) { return JSON.parse(JSON.stringify(o)); }
  function now() { return Date.now(); }
  function uid(prefix) { return prefix + Math.random().toString(36).slice(2, 9); }

  function persist() {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
  }

  function freshState() {
    var s = clone(window.SEED);
    s.session = null;
    return s;
  }

  function load() {
    var raw = null;
    try { raw = localStorage.getItem(KEY); } catch (e) {}
    if (raw) {
      try {
        var parsed = JSON.parse(raw);
        if (parsed && parsed.version === 2 && parsed.users && parsed.bars && parsed.posts) state = parsed;
      } catch (e) {}
    }
    if (!state) {
      state = freshState();
      persist();
    }
    if (!state.messages) state.messages = clone(window.SEED.messages);
  }

  function save() { persist(); }

  /* ---------------- 模块 / 贴吧 ---------------- */
  function modules() { return MODULES.slice(); }

  function moduleOf(key) {
    for (var i = 0; i < MODULES.length; i++) {
      if (MODULES[i].key === key) return MODULES[i];
    }
    return MODULES[0];
  }

  function bars(moduleKey) {
    var list = state.bars.slice();
    if (moduleKey && moduleKey !== 'all') list = list.filter(function (b) { return b.module === moduleKey; });
    return list.sort(function (a, b) { return a.createdAt - b.createdAt; });
  }

  function bar(id) {
    for (var i = 0; i < state.bars.length; i++) if (state.bars[i].id === id) return state.bars[i];
    return null;
  }

  function countPosts(barId) {
    return state.posts.filter(function (p) { return !p.deleted && p.barId === barId; }).length;
  }

  function countModule(moduleKey) {
    return state.posts.filter(function (p) {
      if (p.deleted) return false;
      var b = bar(p.barId);
      return b && b.module === moduleKey;
    }).length;
  }

  function addBar(data) {
    requireAdmin();
    var name = (data.name || '').trim();
    if (name.length < 2 || name.length > 12) throw new Error('贴吧名称需为 2 - 12 个字');
    if (!moduleOf(data.module)) throw new Error('请选择所属模块');
    var dup = state.bars.some(function (b) { return b.name === name; });
    if (dup) throw new Error('该贴吧名称已存在');
    var item = {
      id: uid('b'),
      module: data.module,
      name: name,
      desc: (data.desc || '').trim() || '这个贴吧还没有介绍',
      icon: moduleOf(data.module).icon,
      members: 0,
      createdAt: now()
    };
    state.bars.push(item);
    save();
    return item;
  }

  function updateBar(id, data) {
    requireAdmin();
    var item = bar(id);
    if (!item) throw new Error('贴吧不存在');
    var name = (data.name || '').trim();
    if (name.length < 2 || name.length > 12) throw new Error('贴吧名称需为 2 - 12 个字');
    var dup = state.bars.some(function (b) { return b.id !== id && b.name === name; });
    if (dup) throw new Error('该贴吧名称已存在');
    item.name = name;
    item.desc = (data.desc || '').trim() || item.desc;
    if (data.module && moduleOf(data.module)) {
      item.module = data.module;
      item.icon = moduleOf(data.module).icon;
    }
    save();
    return item;
  }

  function deleteBar(id) {
    requireAdmin();
    var item = bar(id);
    if (!item) throw new Error('贴吧不存在');
    state.posts.forEach(function (p) {
      if (p.barId === id && !p.deleted) {
        p.deleted = true;
        p.deletedAt = now();
        p.deletedBy = state.session;
      }
    });
    state.bars = state.bars.filter(function (b) { return b.id !== id; });
    save();
  }

  /* ---------------- 用户 ---------------- */
  function getUser(id) {
    for (var i = 0; i < state.users.length; i++) if (state.users[i].id === id) return state.users[i];
    return null;
  }

  function current() { return state.session ? getUser(state.session) : null; }
  function isAdmin() { var u = current(); return !!u && u.role === 'admin' && !u.banned; }

  function login(username, password) {
    var u = null;
    var uname = (username || '').trim();
    for (var i = 0; i < state.users.length; i++) if (state.users[i].username === uname) u = state.users[i];
    if (!u) throw new Error('账号不存在，请先注册');
    if (u.password !== password) throw new Error('密码不正确，请重试');
    if (u.banned) throw new Error('该账号已被封禁，请联系管理员');
    u.online = true;
    u.lastActive = now();
    state.session = u.id;
    save();
    return u;
  }

  function register(data) {
    var username = (data.username || '').trim();
    var password = data.password || '';
    var nickname = (data.nickname || '').trim() || username;
    if (!/^[a-zA-Z0-9_]{3,16}$/.test(username)) throw new Error('账号需为 3 - 16 位字母、数字或下划线');
    if (password.length < 6) throw new Error('密码至少需要 6 位');
    if (nickname.length < 1 || nickname.length > 12) throw new Error('昵称需为 1 - 12 个字');
    if (state.users.some(function (u) { return u.username === username; })) throw new Error('该账号已被注册');
    var u = {
      id: uid('u'),
      username: username,
      password: password,
      nickname: nickname,
      role: 'user',
      banned: false,
      online: true,
      avatar: Math.floor(Math.random() * 6),
      bio: '这位同学还没有写简介',
      joinedAt: now()
    };
    state.users.push(u);
    state.session = u.id;
    save();
    return u;
  }

  function logout() {
    var u = current();
    if (u) u.online = false;
    state.session = null;
    save();
  }

  function users() {
    return state.users.slice().sort(function (a, b) {
      if (a.role !== b.role) return a.role === 'admin' ? -1 : 1;
      return b.joinedAt - a.joinedAt;
    });
  }

  function searchUsers(q) {
    var kw = (q || '').trim().toLowerCase();
    var list = users();
    if (!kw) return list;
    return list.filter(function (u) {
      return u.username.toLowerCase().indexOf(kw) >= 0 || u.nickname.toLowerCase().indexOf(kw) >= 0;
    });
  }

  function stats() {
    var total = state.users.length;
    var banned = state.users.filter(function (u) { return u.banned; }).length;
    var online = state.users.filter(function (u) { return u.online && !u.banned; }).length;
    return { total: total, online: online, banned: banned };
  }

  function toggleBan(id) {
    requireAdmin();
    var u = getUser(id);
    if (!u) throw new Error('用户不存在');
    if (u.role === 'admin') throw new Error('管理员账号不可封禁');
    if (u.id === state.session) throw new Error('不能封禁当前登录账号');
    u.banned = !u.banned;
    if (u.banned) u.online = false;
    save();
    return u;
  }

  function setPassword(id, password) {
    requireAdmin();
    var u = getUser(id);
    if (!u) throw new Error('用户不存在');
    if (!password || password.length < 6) throw new Error('新密码至少需要 6 位');
    u.password = password;
    save();
    return u;
  }

  function myPosts(userId) {
    return state.posts.filter(function (p) { return !p.deleted && p.authorId === userId; })
      .sort(function (a, b) { return b.createdAt - a.createdAt; });
  }

  function myLikes(userId) {
    return myPosts(userId).reduce(function (sum, p) { return sum + p.likes; }, 0);
  }

  /* ---------------- 帖子 ---------------- */
  function post(id) { return getPost(id, true); }

  function getPost(id, includeDeleted) {
    for (var i = 0; i < state.posts.length; i++) {
      var p = state.posts[i];
      if (p.id === id && (includeDeleted || !p.deleted)) return p;
    }
    return null;
  }

  function posts(opts) {
    opts = opts || {};
    var list = state.posts.filter(function (p) { return !p.deleted; });
    if (opts.barId) list = list.filter(function (p) { return p.barId === opts.barId; });
    if (opts.q) {
      var kw = opts.q.trim().toLowerCase();
      list = list.filter(function (p) {
        var b = bar(p.barId);
        var author = getUser(p.authorId);
        return (p.title + p.content).toLowerCase().indexOf(kw) >= 0 ||
          (b && b.name.toLowerCase().indexOf(kw) >= 0) ||
          (author && author.nickname.toLowerCase().indexOf(kw) >= 0);
      });
    }
    list.sort(function (a, b) { return b.createdAt - a.createdAt; });
    if (opts.sort === 'hot') {
      list.sort(function (a, b) {
        return (b.likes + b.comments.length * 3) - (a.likes + a.comments.length * 3);
      });
    }
    if (opts.limit) list = list.slice(0, opts.limit);
    return list;
  }

  function createPost(data) {
    var u = current();
    if (!u) throw new Error('请先登录');
    if (u.banned) throw new Error('账号已被封禁');
    var title = (data.title || '').trim();
    var content = (data.content || '').trim();
    if (!data.barId || !bar(data.barId)) throw new Error('请选择要发布到的贴吧');
    if (title.length < 4) throw new Error('标题至少需要 4 个字');
    if (content.length < 6) throw new Error('正文至少需要 6 个字');
    var p = {
      id: uid('p'),
      barId: data.barId,
      authorId: u.id,
      title: title,
      content: content,
      anonymous: !!data.anonymous,
      likes: 0,
      likedBy: [],
      comments: [],
      createdAt: now()
    };
    state.posts.push(p);
    save();
    return p;
  }

  function addComment(postId, content) {
    var u = current();
    if (!u) throw new Error('请先登录');
    if (u.banned) throw new Error('账号已被封禁');
    var p = getPost(postId);
    if (!p) throw new Error('帖子不存在');
    var text = (content || '').trim();
    if (!text) throw new Error('评论内容不能为空');
    if (text.length > 200) throw new Error('评论不能超过 200 字');
    var c = { id: uid('c'), authorId: u.id, content: text, createdAt: now() };
    p.comments.push(c);
    save();
    return c;
  }

  function toggleLike(postId) {
    var u = current();
    if (!u) throw new Error('请先登录');
    var p = getPost(postId);
    if (!p) throw new Error('帖子不存在');
    var idx = p.likedBy.indexOf(u.id);
    if (idx >= 0) {
      p.likedBy.splice(idx, 1);
      p.likes = Math.max(0, p.likes - 1);
    } else {
      p.likedBy.push(u.id);
      p.likes += 1;
    }
    save();
    return p;
  }

  function isLiked(postId) {
    var u = current();
    if (!u) return false;
    var p = getPost(postId);
    return !!p && p.likedBy.indexOf(u.id) >= 0;
  }

  function deletePost(id) {
    var u = current();
    if (!u) throw new Error('请先登录');
    var p = getPost(id);
    if (!p) throw new Error('帖子不存在');
    if (u.role !== 'admin' && p.authorId !== u.id) throw new Error('没有权限删除该帖子');
    p.deleted = true;
    p.deletedAt = now();
    p.deletedBy = u.id;
    save();
    return p;
  }

  /* ---------------- 消息 ---------------- */
  function messages() {
    return state.messages.slice().sort(function (a, b) { return b.createdAt - a.createdAt; });
  }

  function unreadCount() {
    return state.messages.filter(function (m) { return m.unread; }).length;
  }

  function markAllRead() {
    state.messages.forEach(function (m) { m.unread = false; });
    save();
  }

  function markRead(id) {
    state.messages.forEach(function (m) { if (m.id === id) m.unread = false; });
    save();
  }

  /* ---------------- 主题 ---------------- */
  function getTheme() {
    try {
      var t = localStorage.getItem(THEME_KEY);
      if (t === 'dark' || t === 'light') return t;
    } catch (e) {}
    return null;
  }

  function setTheme(theme) {
    try { localStorage.setItem(THEME_KEY, theme); } catch (e) {}
  }

  function requireAdmin() {
    if (!isAdmin()) throw new Error('需要管理员权限');
  }

  load();

  window.Store = {
    modules: modules,
    moduleOf: moduleOf,
    bars: bars,
    bar: bar,
    countPosts: countPosts,
    countModule: countModule,
    addBar: addBar,
    updateBar: updateBar,
    deleteBar: deleteBar,

    getUser: getUser,
    current: current,
    isAdmin: isAdmin,
    login: login,
    register: register,
    logout: logout,
    users: users,
    searchUsers: searchUsers,
    stats: stats,
    toggleBan: toggleBan,
    setPassword: setPassword,
    myPosts: myPosts,
    myLikes: myLikes,

    posts: posts,
    post: post,
    createPost: createPost,
    addComment: addComment,
    toggleLike: toggleLike,
    isLiked: isLiked,
    deletePost: deletePost,

    messages: messages,
    unreadCount: unreadCount,
    markAllRead: markAllRead,
    markRead: markRead,

    getTheme: getTheme,
    setTheme: setTheme
  };
})();
