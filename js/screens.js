/* 乌市职专墙 · 页面视图 */
(function () {
  var esc = UI.esc;
  var icon = Icons.get;

  /* ---------------- 工具 ---------------- */
  function hexToRgba(hex, alpha) {
    var h = hex.replace('#', '');
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    var n = parseInt(h, 16);
    return 'rgba(' + ((n >> 16) & 255) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + alpha + ')';
  }

  function tint(color, alpha) {
    return '--m:' + color + ';--m-soft:' + hexToRgba(color, alpha || .13);
  }

  function moduleOf(key) { return Store.moduleOf(key); }

  function greeting() {
    var h = new Date().getHours();
    if (h < 6) return '夜深了';
    if (h < 11) return '早上好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  function themeIcon() {
    return App.theme() === 'dark' ? icon('sun', 19, 1.8) : icon('moon', 19, 1.8);
  }

  function statusbar() {
    var d = new Date();
    var time = d.getHours() + ':' + String(d.getMinutes()).padStart(2, '0');
    return '<div class="statusbar">' +
      '<div class="sb-left">' + time + '</div>' +
      '<div class="sb-right">' + icon('wifi', 16, 1.7) +
        '<svg width="22" height="12" viewBox="0 0 22 12" fill="none" aria-hidden="true">' +
          '<rect x="1" y="1" width="17" height="10" rx="3" stroke="currentColor" stroke-width="1.2" opacity=".55"/>' +
          '<rect x="3" y="3" width="12" height="6" rx="1.6" fill="currentColor"/>' +
          '<path d="M20 4.2v3.6" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" opacity=".55"/>' +
        '</svg>' +
      '</div></div>';
  }

  function dock(route) {
    var r = route.name;
    var active = {
      home: r === 'home',
      bars: r === 'bars' || r === 'bar' || r === 'search',
      compose: r === 'compose',
      messages: r === 'messages',
      me: r === 'me'
    };
    var unread = Store.unreadCount();
    return '<nav class="dock" aria-label="底部导航">' +
      '<button class="dock-item ' + (active.home ? 'active' : '') + '" data-nav="#/home">' + icon('home', 21, 1.8) + '<span>首页</span></button>' +
      '<button class="dock-item ' + (active.bars ? 'active' : '') + '" data-nav="#/bars">' + icon('compass', 21, 1.8) + '<span>贴吧</span></button>' +
      '<button class="dock-fab ' + (active.compose ? 'active' : '') + '" data-nav="#/compose" aria-label="发布帖子">' + icon('plus', 24, 2.2) + '</button>' +
      '<button class="dock-item ' + (active.messages ? 'active' : '') + '" data-nav="#/messages">' + icon('chat', 21, 1.8) +
        (unread ? '<i class="dock-dot"></i>' : '') + '<span>消息</span></button>' +
      '<button class="dock-item ' + (active.me ? 'active' : '') + '" data-nav="#/me">' + icon('user', 21, 1.8) + '<span>我的</span></button>' +
    '</nav>';
  }

  function subHeader(title, right, backNav) {
    return '<header class="topbar">' +
      '<button class="back-btn" data-action="back" data-back="' + esc(backNav || '') + '" aria-label="返回">' + icon('arrowLeft', 18, 2) + '</button>' +
      '<div class="topbar-main"><h1 class="sub-title truncate">' + esc(title) + '</h1></div>' +
      (right || '') +
    '</header>';
  }

  function emptyState(iconName, title, desc, action) {
    return '<div class="empty">' +
      '<div class="empty-ic">' + icon(iconName, 26, 1.7) + '</div>' +
      '<h4>' + esc(title) + '</h4>' +
      '<p>' + esc(desc) + '</p>' +
      (action || '') +
    '</div>';
  }

  function postCard(p) {
    var b = Store.bar(p.barId);
    var mod = moduleOf(b ? b.module : 'lost');
    var author = Store.getUser(p.authorId);
    var displayName = p.anonymous ? '匿名同学' : (author ? author.nickname : '已注销用户');
    var av = p.anonymous ? UI.anonymousAvatar(38) : UI.avatar(author, 38);
    var liked = Store.isLiked(p.id);
    return '<button class="post-card" data-nav="#/post/' + p.id + '" style="' + tint(mod.color) + '">' +
      '<div class="post-head">' +
        av +
        '<div class="post-who">' +
          '<div class="post-name">' + esc(displayName) + (p.anonymous ? '<span class="pill soft">匿名</span>' : '') + '</div>' +
          '<div class="post-meta">' + esc(b ? b.name : '未知贴吧') + '<i></i>' + UI.timeAgo(p.createdAt) + '</div>' +
        '</div>' +
        '<span class="post-rank">' + esc(mod.name) + '</span>' +
      '</div>' +
      '<h3 class="post-title">' + esc(p.title) + '</h3>' +
      '<p class="post-excerpt">' + esc(p.content) + '</p>' +
      '<div class="post-foot">' +
        '<span class="post-stat' + (liked ? ' liked' : '') + '">' + icon('heart', 13, 1.9) + p.likes + '</span>' +
        '<span class="post-stat">' + icon('message', 13, 1.9) + p.comments.length + '</span>' +
        '<span class="post-stat" style="margin-left:auto;opacity:.55">' + icon('chevron', 13, 2) + '</span>' +
      '</div>' +
    '</button>';
  }

  function barRow(b) {
    var mod = moduleOf(b.module);
    return '<button class="bar-row" data-nav="#/bar/' + b.id + '">' +
      '<span class="bar-icon" style="' + tint(mod.color) + '">' + icon(b.icon || mod.icon, 23, 1.8) + '</span>' +
      '<span class="bar-info">' +
        '<h4>' + esc(b.name) + '<span class="pill soft">' + esc(mod.name) + '</span></h4>' +
        '<p>' + esc(b.desc) + '</p>' +
        '<span class="bar-stats"><span><b>' + Store.countPosts(b.id) + '</b> 帖子</span><span><b>' + b.members + '</b> 成员</span></span>' +
      '</span>' +
      '<span class="chev" style="color:var(--text-3)">' + icon('chevron', 17, 2) + '</span>' +
    '</button>';
  }

  /* ---------------- 登录 / 注册 ---------------- */
  function brandGlyph() {
    return '<svg width="24" height="24" viewBox="0 0 32 32" fill="none" aria-hidden="true">' +
      '<path d="M6.4 20.6c2.5-1.7 4.4-1.7 6.7 0 2.3 1.7 4.2 1.7 6.7 0 2-1.4 3.6-1.6 4.8-.9" stroke="#fff" stroke-width="2.1" stroke-linecap="round"/>' +
      '<path d="M11.4 15.5c0-3.4 2.2-6.1 5.1-6.1s5.1 2.7 5.1 6.1" stroke="#fff" stroke-width="2.1" stroke-linecap="round"/>' +
    '</svg>';
  }

  function authScreen() {
    var tab = App.ui.authTab || 'login';
    var isLogin = tab === 'login';
    var error = App.ui.authError;

    var fields = isLogin
      ? '<div class="field">' + icon('user', 18, 1.8) + '<input id="auth-username" name="username" placeholder="学号 / 账号" autocomplete="username" required></div>' +
        '<div class="field">' + icon('lock', 18, 1.8) + '<input id="auth-password" name="password" type="password" placeholder="密码" autocomplete="current-password" required></div>'
      : '<div class="field">' + icon('user', 18, 1.8) + '<input id="auth-nickname" name="nickname" placeholder="昵称（展示给其他同学）" required maxlength="12"></div>' +
        '<div class="field">' + icon('at', 18, 1.8) + '<input id="auth-username" name="username" placeholder="账号（3-16 位字母 / 数字）" required maxlength="16"></div>' +
        '<div class="field">' + icon('lock', 18, 1.8) + '<input id="auth-password" name="password" type="password" placeholder="密码（至少 6 位）" required minlength="6">' +
        '</div>';

    return '<div class="auth">' +
      '<div class="auth-top">' +
        '<div class="brand"><span class="brand-mark">' + brandGlyph() + '</span>' +
          '<div><div class="brand-name">乌市职专墙</div><div class="brand-sub">CAMPUS WALL</div></div>' +
        '</div>' +
        '<button class="icon-btn" data-action="theme" data-theme-value="' + (App.theme() === 'dark' ? 'light' : 'dark') + '" aria-label="切换主题">' + themeIcon() + '</button>' +
      '</div>' +

      '<div class="auth-hero">' +
        '<h1>找回丢失的，<br><em>遇见心动的</em>。</h1>' +
        '<p>校园寻物 · 吐槽 · 表白 · 找人，一个就够</p>' +
      '</div>' +

      '<div class="auth-card glass">' +
        '<div class="seg">' +
          '<button type="button" class="' + (isLogin ? 'active' : '') + '" data-action="auth-tab" data-tab="login">登录</button>' +
          '<button type="button" class="' + (!isLogin ? 'active' : '') + '" data-action="auth-tab" data-tab="register">注册</button>' +
        '</div>' +

        '<form class="auth-form" data-form="' + (isLogin ? 'login' : 'register') + '">' +
          fields +
          (error ? '<p class="auth-error">' + esc(error) + '</p>' : '') +
          '<div class="auth-row">' +
            '<span>' + (isLogin ? '还没有账号？' : '注册后自动登录') + '</span>' +
            '<a href="javascript:void(0)" data-action="auth-tab" data-tab="' + (isLogin ? 'register' : 'login') + '">' +
              (isLogin ? '立即注册' : '返回登录') + '</a>' +
          '</div>' +
          '<button class="btn btn-primary" type="submit">' + (isLogin ? '进入乌市职专墙' : '注册并登录') + '</button>' +
        '</form>' +

        '<div class="demo-box">' +
          '<h5>演示账号 · 点击填充</h5>' +
          '<div class="demo-btns">' +
            '<button type="button" class="demo-btn" data-action="fill-demo" data-role="admin"><b>管理员</b><small>admin / admin123</small></button>' +
            '<button type="button" class="demo-btn" data-action="fill-demo" data-role="user"><b>学生</b><small>xiaoyu / 123456</small></button>' +
          '</div>' +
        '</div>' +
      '</div>' +

      '<p class="auth-foot">登录即代表同意《社区公约》与《隐私说明》<br>乌市职专墙 · 校园社区 UI 预览版</p>' +
    '</div>';
  }

  /* ---------------- 首页 ---------------- */
  function homeScreen() {
    var u = Store.current();
    var mods = Store.modules();
    var hot = Store.posts({ sort: 'hot', limit: 4 });
    var unread = Store.unreadCount();

    var moduleCards = mods.map(function (mod) {
      var list = Store.bars(mod.key);
      var target = list.length ? '#/bar/' + list[0].id : '#/bars';
      return '<button class="module-card" data-nav="' + target + '" style="' + tint(mod.color) + '">' +
        '<span class="module-icon">' + icon(mod.icon, 21, 1.9) + '</span>' +
        '<h4>' + esc(mod.label) + '</h4>' +
        '<p>' + Store.countModule(mod.key) + ' 条帖子 · ' + (list[0] ? list[0].members : 0) + ' 成员</p>' +
      '</button>';
    }).join('');

    return '<header class="topbar">' +
      '<div class="topbar-main">' +
        '<p class="greet">' + greeting() + '，' + esc(u.nickname) + '</p>' +
        '<h1 class="page-title">乌市职专墙</h1>' +
      '</div>' +
      '<button class="icon-btn" data-action="theme" data-theme-value="' + (App.theme() === 'dark' ? 'light' : 'dark') + '" aria-label="切换主题">' + themeIcon() + '</button>' +
      '<button class="avatar-btn" data-nav="#/me" aria-label="个人中心">' + UI.avatar(u, 38) +
        (unread ? '<i class="avatar-dot"></i>' : '') +
      '</button>' +
    '</header>' +

    '<button class="searchbar" data-nav="#/search">' + icon('search', 18, 1.8) +
      '<span>搜索帖子、失物、同学</span><span class="kbd">SEARCH</span>' +
    '</button>' +

    '<section class="hero">' +
      '<span class="hero-tag">' + icon('sparkles', 12, 1.9) + ' CAMPUS WALL</span>' +
      '<h2>丢失的会回来，<br>心动的会被看见。</h2>' +
      '<p>已有 1,286 位同学在乌市职专墙互相帮忙</p>' +
      '<button class="hero-cta" data-nav="#/compose">' + icon('plus', 15, 2.2) + '发布一条</button>' +
    '</section>' +

    '<div class="notice" data-nav="#/post/p10">' +
      '<b>公告</b><span>失物招领处已搬迁至学生活动中心 105 室</span>' +
      '<span style="flex:none;color:var(--text-3)">' + icon('chevron', 14, 2) + '</span>' +
    '</div>' +

    '<div class="section-head"><h3>校园四大板块</h3><span class="more">' + mods.length + ' 个模块</span></div>' +
    '<div class="module-grid">' + moduleCards + '</div>' +

    '<div class="section-head"><h3>正在热聊</h3><button class="more" data-nav="#/bars">全部贴吧 ' + icon('chevron', 12, 2) + '</button></div>' +
    '<div class="feed">' + hot.map(postCard).join('') + '</div>' +
    '<p style="text-align:center;font-size:10px;color:var(--text-3);margin:22px 0 6px;letter-spacing:.08em">— 乌市职专墙 · 让校园更近一点 —</p>';
  }

  /* ---------------- 贴吧广场 ---------------- */
  function barsScreen() {
    var filter = App.ui.barsFilter || 'all';
    var mods = Store.modules();
    var list = Store.bars(filter);

    var chips = '<button class="chip ' + (filter === 'all' ? 'active' : '') + '" data-action="bars-filter" data-value="all">全部</button>' +
      mods.map(function (mod) {
        return '<button class="chip ' + (filter === mod.key ? 'active' : '') + '" data-action="bars-filter" data-value="' + mod.key + '">' +
          icon(mod.icon, 14, 2) + esc(mod.name) + '</button>';
      }).join('');

    return '<header class="topbar">' +
      '<div class="topbar-main"><h1 class="page-title">贴吧广场</h1></div>' +
      '<button class="icon-btn" data-nav="#/search" aria-label="搜索">' + icon('search', 19, 1.8) + '</button>' +
    '</header>' +
    '<div class="chip-row">' + chips + '</div>' +
    '<div class="bar-list">' + list.map(barRow).join('') + '</div>' +
    (list.length === 0 ? emptyState('compass', '这个分类还没有贴吧', '管理员可以在后台创建新的贴吧') : '') +
    '<p style="text-align:center;font-size:10.5px;color:var(--text-3);margin-top:20px">共 ' + Store.bars().length + ' 个贴吧 · 由管理员统一维护</p>';
  }

  /* ---------------- 单个贴吧 ---------------- */
  function barScreen(id) {
    var b = Store.bar(id);
    if (!b) return null;
    var mod = moduleOf(b.module);
    var sort = App.ui.barSort || 'new';
    var list = Store.posts({ barId: id, sort: sort });

    return '<header class="topbar">' +
      '<button class="back-btn" data-action="back" data-back="#/bars" aria-label="返回">' + icon('arrowLeft', 18, 2) + '</button>' +
      '<div class="topbar-main"><h1 class="sub-title truncate">' + esc(b.name) + '</h1></div>' +
      '<button class="icon-btn" data-nav="#/search" aria-label="搜索">' + icon('search', 19, 1.8) + '</button>' +
    '</header>' +

    '<section class="bar-hero" style="' + tint(mod.color) + '">' +
      '<span class="bar-icon">' + icon(b.icon || mod.icon, 25, 1.8) + '</span>' +
      '<div style="flex:1;min-width:0">' +
        '<h2>' + esc(b.name) + '</h2>' +
        '<p>' + esc(b.desc) + '</p>' +
        '<span class="pill">' + Store.countPosts(b.id) + ' 条帖子 · ' + b.members + ' 位成员</span>' +
      '</div>' +
    '</section>' +

    '<div class="list-tools">' +
      '<div class="seg" style="flex:1">' +
        '<button class="' + (sort === 'new' ? 'active' : '') + '" data-action="sort" data-value="new">最新</button>' +
        '<button class="' + (sort === 'hot' ? 'active' : '') + '" data-action="sort" data-value="hot">最热</button>' +
      '</div>' +
      '<span class="pill soft">' + list.length + ' 条</span>' +
    '</div>' +

    (list.length
      ? '<div class="feed">' + list.map(postCard).join('') + '</div>'
      : emptyState('edit', '这里还很安静', '成为第一个发帖的同学吧', '<button class="btn btn-primary btn-sm" style="margin-top:14px" data-nav="#/compose/' + b.id + '">发第一帖</button>'));
  }

  /* ---------------- 帖子详情 ---------------- */
  function commentBarHTML(id) {
    return '<form class="comment-bar" data-form="comment" data-id="' + id + '">' +
      '<input name="content" placeholder="友善评论，让校园更温暖" maxlength="200" autocomplete="off">' +
      '<button class="send-btn" type="submit" aria-label="发送评论">' + icon('send', 18, 1.9) + '</button>' +
    '</form>';
  }

  function postScreen(id) {
    var p = Store.post(id);
    if (!p) return null;
    var b = Store.bar(p.barId);
    var mod = moduleOf(b ? b.module : 'lost');
    var author = Store.getUser(p.authorId);
    var me = Store.current();
    var isAdmin = Store.isAdmin();
    var displayName = p.anonymous ? '匿名同学' : (author ? author.nickname : '已注销用户');
    var av = p.anonymous ? UI.anonymousAvatar(44) : UI.avatar(author, 44);
    var liked = Store.isLiked(p.id);
    var canDelete = me && (me.role === 'admin' || p.authorId === me.id);

    var commentList = p.comments.slice().sort(function (a, b2) { return a.createdAt - b2.createdAt; }).map(function (c) {
      var cu = Store.getUser(c.authorId);
      return '<div class="comment">' + UI.avatar(cu, 34) +
        '<div class="comment-body">' +
          '<div class="comment-top"><b>' + esc(cu ? cu.nickname : '已注销用户') + '</b>' + UI.timeAgo(c.createdAt) + '</div>' +
          '<p>' + esc(c.content) + '</p>' +
        '</div>' +
      '</div>';
    }).join('');

    return subHeader('帖子详情',
      canDelete ? '<button class="icon-btn" data-action="delete-post" data-id="' + p.id + '" aria-label="删除帖子" style="color:var(--danger)">' + icon('trash', 18, 1.8) + '</button>' : '',
      b ? '#/bar/' + b.id : '#/bars') +

    '<article class="post-full" style="' + tint(mod.color) + '">' +
      '<div class="post-head">' + av +
        '<div class="post-who">' +
          '<div class="post-name">' + esc(displayName) +
            (p.anonymous ? '<span class="pill soft">匿名</span>' : '') +
            (author && author.banned ? '<span class="pill danger">已封禁</span>' : '') +
          '</div>' +
          '<div class="post-meta">' + UI.timeAgo(p.createdAt) + '<i></i>' + (b ? esc(b.name) : '未知贴吧') + '</div>' +
        '</div>' +
        '<span class="post-rank">' + esc(mod.name) + '</span>' +
      '</div>' +
      '<h1 class="post-full-title">' + esc(p.title) + '</h1>' +
      (isAdmin && p.anonymous && author ? '<p class="post-anon-hint">匿名帖 · 发帖人：' + esc(author.nickname) + ' (@' + esc(author.username) + ')</p>' : '') +
      '<div class="post-body">' + esc(p.content) + '</div>' +
      '<div class="post-tags">' +
        '<span class="pill">' + icon('tag', 11, 2) + esc(mod.label) + '</span>' +
        (b ? '<span class="pill soft">' + esc(b.name) + '</span>' : '') +
      '</div>' +
      '<div class="post-actions">' +
        '<button class="action-btn ' + (liked ? 'liked' : '') + '" data-action="like" data-id="' + p.id + '">' +
          icon('heart', 15, 1.9) + (liked ? '已赞' : '点赞') + ' ' + p.likes +
        '</button>' +
        '<span class="action-btn">' + icon('message', 15, 1.9) + p.comments.length + ' 条评论</span>' +
        '<button class="action-btn" data-action="share" style="margin-left:auto">' + icon('send', 15, 1.9) + '分享</button>' +
      '</div>' +
    '</article>' +

    '<section class="comments-wrap">' +
      '<h3>全部评论 <span>' + p.comments.length + '</span></h3>' +
      (commentList || '<div class="panel" style="text-align:center;font-size:12px;color:var(--text-3)">还没有评论，来说点什么吧</div>') +
    '</section>';
  }

  /* ---------------- 发帖 ---------------- */
  function composeScreen(presetBarId) {
    var bars = Store.bars();
    if (!bars.length) {
      return subHeader('发布帖子', '', '#/home') +
        emptyState('compass', '还没有可用的贴吧', '请先联系管理员创建贴吧');
    }
    var selectedId = presetBarId || App.ui.composeBar;
    var selected = bars.filter(function (b) { return b.id === selectedId; })[0] || bars[0];
    App.ui.composeBar = selected.id;
    var anon = !!App.ui.anon;

    var chips = bars.map(function (b) {
      var mod = moduleOf(b.module);
      return '<button type="button" class="bar-select ' + (b.id === selected.id ? 'active' : '') + '" style="' + tint(mod.color) + '" data-action="pick-bar" data-id="' + b.id + '">' +
        icon(b.icon || mod.icon, 14, 1.9) + esc(b.name) +
      '</button>';
    }).join('');

    return subHeader('发布帖子', '', '#/home') +
      '<form class="compose-form" data-form="compose">' +
        '<div>' +
          '<p class="field-label">发布到</p>' +
          '<div class="compose-bar-chips">' + chips + '</div>' +
        '</div>' +
        '<div>' +
          '<p class="field-label">标题</p>' +
          '<div class="field">' + icon('edit', 17, 1.8) +
            '<input name="title" placeholder="用一句话说清楚（至少 4 个字）" maxlength="40" required minlength="4" autocomplete="off">' +
          '</div>' +
        '</div>' +
        '<div>' +
          '<p class="field-label">正文</p>' +
          '<textarea class="field-area" name="content" placeholder="补充细节，让同学更容易帮到你…" maxlength="1000" required minlength="6"></textarea>' +
        '</div>' +
        '<div class="anon-row">' +
          '<span class="menu-ic" style="width:34px;height:34px;border-radius:11px;display:grid;place-items:center;color:var(--brand);background:rgba(47,107,255,.1)">' + icon('eye', 18, 1.8) + '</span>' +
          '<span class="anon-text"><h4>匿名发布</h4><p>表白、吐槽时隐藏身份，管理员仍可追溯</p></span>' +
          '<button type="button" class="switch ' + (anon ? 'on' : '') + '" data-action="toggle-anon" aria-label="匿名发布"><i></i></button>' +
        '</div>' +
        '<div class="form-tip">' + icon('info', 14, 1.9) +
          '<span>请勿发布个人敏感信息；线下见面请选择公共场所。违规内容会被管理员删除。</span>' +
        '</div>' +
        '<button class="btn btn-primary" type="submit" style="margin-top:4px">' + icon('send', 17, 1.9) + '发布帖子</button>' +
      '</form>';
  }

  /* ---------------- 搜索 ---------------- */
  function searchScreen() {
    var q = (App.ui.searchQ || '').trim();
    var posts = q ? Store.posts({ q: q }) : [];
    var users = q ? Store.searchUsers(q) : [];

    var suggestions = ['AirPods', '图书馆', '组队', '校园卡', '番茄炒蛋'];

    var body;
    if (!q) {
      body = '<p class="search-result-label">大家都在搜</p>' +
        '<div class="chip-row" style="margin:0;padding:0;flex-wrap:wrap;overflow:visible">' +
          suggestions.map(function (s) {
            return '<button class="chip" data-action="quick-search" data-q="' + esc(s) + '">' + icon('search', 13, 2) + esc(s) + '</button>';
          }).join('') +
        '</div>' +
        '<div class="section-head"><h3>热门帖子</h3></div>' +
        '<div class="feed">' + Store.posts({ sort: 'hot', limit: 3 }).map(postCard).join('') + '</div>';
    } else {
      var userRows = users.map(function (u) {
        return '<div class="bar-manage-row">' + UI.avatar(u, 40) +
          '<div class="bar-info">' +
            '<h4>' + esc(u.nickname) + (u.role === 'admin' ? '<span class="pill">管理员</span>' : '') +
              (u.banned ? '<span class="pill danger">已封禁</span>' : '') + '</h4>' +
            '<p>@' + esc(u.username) + ' · ' + esc(u.bio) + '</p>' +
          '</div>' +
          (u.online ? '<span class="online-dot"></span>' : '') +
        '</div>';
      }).join('');

      body = '<p class="search-result-label">找到 <b>' + posts.length + '</b> 条帖子 · <b>' + users.length + '</b> 位同学</p>' +
        (posts.length ? '<div class="feed">' + posts.map(postCard).join('') + '</div>' : '') +
        (users.length ? '<p class="search-result-label">相关同学</p><div>' + userRows + '</div>' : '') +
        (!posts.length && !users.length ? emptyState('search', '没有找到相关内容', '换个关键词试试，比如「图书馆」') : '');
    }

    return '<header class="topbar">' +
      '<button class="back-btn" data-action="back" data-back="#/home" aria-label="返回">' + icon('arrowLeft', 18, 2) + '</button>' +
      '<div class="topbar-main"><h1 class="sub-title">搜索</h1></div>' +
    '</header>' +
    '<form class="search-head" data-form="search">' +
      '<div class="search-field">' + icon('search', 17, 1.8) +
        '<input name="q" value="' + esc(q) + '" placeholder="搜索帖子、失物、同学" autocomplete="off">' +
      '</div>' +
      '<button class="icon-btn accent" type="submit" aria-label="搜索">' + icon('arrowRight', 19, 2) + '</button>' +
    '</form>' +
    body;
  }

  /* ---------------- 消息 ---------------- */
  function messagesScreen() {
    var list = Store.messages();
    var unread = Store.unreadCount();

    var rows = list.map(function (msg) {
      var cls = msg.type === 'like' ? 'pink' : (msg.type === 'system' ? 'amber' : '');
      var ic = msg.type === 'like' ? 'heart' : (msg.type === 'system' ? 'bell' : 'chat');
      return '<button class="msg-row" data-action="read-msg" data-id="' + msg.id + '">' +
        '<span class="msg-icon ' + cls + '">' + icon(ic, 19, 1.8) + '</span>' +
        '<span class="msg-body">' +
          '<h4>' + esc(msg.title) + (msg.type === 'system' ? '<span class="pill soft">系统</span>' : '') + '</h4>' +
          '<p>' + esc(msg.text) + '</p>' +
          '<time>' + UI.timeAgo(msg.createdAt) + '</time>' +
        '</span>' +
        (msg.unread ? '<i class="dot-unread"></i>' : '') +
      '</button>';
    }).join('');

    return '<header class="topbar">' +
      '<div class="topbar-main"><h1 class="page-title">消息</h1></div>' +
      (unread ? '<button class="text-btn" data-action="mark-all-read">全部已读</button>' : '<span class="pill ok">已读</span>') +
    '</header>' +
    '<div class="msg-list">' + rows + '</div>' +
    '<p style="text-align:center;font-size:10.5px;color:var(--text-3);margin-top:18px">消息中心 · 接入服务端后支持实时通知</p>';
  }

  /* ---------------- 个人中心 ---------------- */
  function meScreen() {
    var u = Store.current();
    var myPosts = Store.myPosts(u.id);
    var likes = Store.myLikes(u.id);
    var days = Math.max(1, Math.floor((Date.now() - u.joinedAt) / 86400000));
    var theme = App.theme();

    var recent = myPosts.slice(0, 3).map(postCard).join('');

    return '<header class="topbar">' +
      '<div class="topbar-main"><h1 class="page-title">我的</h1></div>' +
      '<button class="icon-btn" data-action="theme" data-theme-value="' + (theme === 'dark' ? 'light' : 'dark') + '" aria-label="切换主题">' + themeIcon() + '</button>' +
    '</header>' +

    '<section class="profile-card">' +
      '<div class="profile-top">' + UI.avatar(u, 58) +
        '<div style="flex:1;min-width:0">' +
          '<div class="profile-name">' + esc(u.nickname) +
            (u.role === 'admin' ? '<span class="pill">' + icon('shield', 10, 2.2) + '管理员</span>' : '') +
          '</div>' +
          '<div class="profile-handle">@' + esc(u.username) + ' · 加入 ' + days + ' 天</div>' +
        '</div>' +
        '<span class="pill ' + (u.online ? 'ok' : 'soft') + '">' + (u.online ? '在线' : '离线') + '</span>' +
      '</div>' +
      '<p class="profile-bio">' + esc(u.bio || '这位同学还没有写简介') + '</p>' +
      '<div class="profile-stats">' +
        '<div><b>' + myPosts.length + '</b><span>发帖</span></div>' +
        '<div><b>' + likes + '</b><span>获赞</span></div>' +
        '<div><b>' + days + '</b><span>加入天数</span></div>' +
      '</div>' +
    '</section>' +

    (u.role === 'admin'
      ? '<button class="admin-entry" data-nav="#/admin">' +
          '<span class="menu-ic">' + icon('shield', 20, 1.9) + '</span>' +
          '<span style="flex:1"><h4>管理员后台</h4><p>内容审核 · 用户管理 · 贴吧维护</p></span>' +
          '<span style="opacity:.8">' + icon('chevron', 18, 2) + '</span>' +
        '</button>'
      : '') +

    '<div class="panel">' +
      '<div class="panel-head"><h3>外观主题</h3><span>白天 / 夜晚</span></div>' +
      '<div class="theme-cards">' +
        '<button class="theme-card ' + (theme === 'light' ? 'active' : '') + '" data-action="theme" data-theme-value="light">' +
          '<span class="theme-preview day"><i></i><i></i><i></i></span>' +
          '<b>白天模式</b><span>蓝白 · 清爽明亮</span>' +
        '</button>' +
        '<button class="theme-card ' + (theme === 'dark' ? 'active' : '') + '" data-action="theme" data-theme-value="dark">' +
          '<span class="theme-preview night"><i></i><i></i><i></i></span>' +
          '<b>夜晚模式</b><span>黑灰 · 低光护眼</span>' +
        '</button>' +
      '</div>' +
    '</div>' +

    '<div class="section-head"><h3>我的帖子</h3><span class="more">' + myPosts.length + ' 条</span></div>' +
    (myPosts.length ? '<div class="feed">' + recent + '</div>' : '<div class="panel" style="text-align:center;font-size:12px;color:var(--text-3)">还没有发布过帖子</div>') +

    '<div class="menu-card" style="margin-top:18px">' +
      '<button class="menu-row" data-action="account-info">' +
        '<span class="menu-ic">' + icon('user', 18, 1.8) + '</span>' +
        '<span class="menu-text"><h4>账号信息</h4><p>查看账号与权限详情</p></span>' +
        '<span class="chev">' + icon('chevron', 16, 2) + '</span>' +
      '</button>' +
      '<button class="menu-row" data-action="about">' +
        '<span class="menu-ic amber">' + icon('info', 18, 1.8) + '</span>' +
        '<span class="menu-text"><h4>关于乌市职专墙</h4><p>版本 0.1 · UI 预览版</p></span>' +
        '<span class="chev">' + icon('chevron', 16, 2) + '</span>' +
      '</button>' +
      '<button class="menu-row" data-action="logout">' +
        '<span class="menu-ic red">' + icon('logout', 18, 1.8) + '</span>' +
        '<span class="menu-text"><h4 style="color:var(--danger)">退出登录</h4><p>退出当前账号</p></span>' +
        '<span class="chev">' + icon('chevron', 16, 2) + '</span>' +
      '</button>' +
    '</div>' +

    '<p style="text-align:center;font-size:10px;color:var(--text-3);margin-top:20px;letter-spacing:.1em">乌市职专墙 CAMPUS WALL · V0.1</p>';
  }

  /* ---------------- 管理后台 ---------------- */
  function adminTabs(active) {
    var items = [
      { key: 'overview', label: '概览', href: '#/admin' },
      { key: 'content', label: '内容', href: '#/admin/content' },
      { key: 'users', label: '用户', href: '#/admin/users' },
      { key: 'bars', label: '贴吧', href: '#/admin/bars' }
    ];
    return '<div class="admin-tabs">' + items.map(function (it) {
      return '<button class="' + (active === it.key ? 'active' : '') + '" data-nav="' + it.href + '">' + it.label + '</button>';
    }).join('') + '</div>';
  }

  function adminHeader(title, right, backNav) {
    return '<header class="topbar">' +
      '<button class="back-btn" data-action="back" data-back="' + esc(backNav || '#/me') + '" aria-label="返回">' + icon('arrowLeft', 18, 2) + '</button>' +
      '<div class="topbar-main"><h1 class="sub-title">' + esc(title) + '</h1></div>' +
      (right || '<span class="pill">' + icon('shield', 10, 2.2) + '管理员</span>') +
    '</header>';
  }

  function adminOverview() {
    var s = Store.stats();
    var newToday = Store.posts().filter(function (p) { return Date.now() - p.createdAt < 86400000; }).length;
    var recent = Store.posts({ limit: 4 });
    var chart = [42, 58, 48, 72, 60, 86, 68];
    var labels = ['一', '二', '三', '四', '五', '六', '日'];

    var recentRows = recent.map(function (p) {
      var author = Store.getUser(p.authorId);
      var b = Store.bar(p.barId);
      return '<button class="bar-manage-row" data-nav="#/post/' + p.id + '" style="width:100%;text-align:left">' +
        '<span class="bar-icon" style="width:38px;height:38px;border-radius:12px;' + tint(b ? moduleOf(b.module).color : '#3b82f6') + '">' +
          icon('edit', 17, 1.8) + '</span>' +
        '<span class="bar-info"><h4>' + esc(p.title) + '</h4>' +
          '<p>' + esc(author ? author.nickname : '已注销') + ' · ' + esc(b ? b.name : '-') + ' · ' + UI.timeAgo(p.createdAt) + '</p>' +
        '</span>' +
        '<span class="chev" style="color:var(--text-3)">' + icon('chevron', 16, 2) + '</span>' +
      '</button>';
    }).join('');

    return adminHeader('管理后台', '', '#/me') +
      adminTabs('overview') +
      '<section class="admin-hero">' +
        '<span class="pill">' + icon('sparkles', 11, 2) + ' ADMIN CONSOLE</span>' +
        '<h2>校园社区管理</h2>' +
        '<p>今天新增 ' + newToday + ' 条帖子 · 共 ' + Store.bars().length + ' 个贴吧</p>' +
      '</section>' +

      '<div class="admin-stats">' +
        '<div class="stat-card" style="--s:#3b82f6;--s-soft:rgba(59,130,246,.12)">' +
          '<span class="stat-ic">' + icon('users', 15, 1.9) + '</span><b>' + s.total + '</b><span>用户总数</span>' +
        '</div>' +
        '<div class="stat-card" style="--s:#10b981;--s-soft:rgba(16,185,129,.12)">' +
          '<span class="stat-ic">' + icon('eye', 15, 1.9) + '</span><b>' + s.online + '</b><span>当前在线</span>' +
        '</div>' +
        '<div class="stat-card" style="--s:#ef4444;--s-soft:rgba(239,68,68,.12)">' +
          '<span class="stat-ic">' + icon('ban', 15, 1.9) + '</span><b>' + s.banned + '</b><span>已封禁</span>' +
        '</div>' +
      '</div>' +

      '<div class="panel">' +
        '<div class="panel-head"><h3>近 7 日活跃</h3><span>示意数据</span></div>' +
        '<div class="mini-chart">' + chart.map(function (v, i) {
          return '<div class="bar-col"><i style="height:' + Math.round(v * 0.62) + 'px"></i><span>' + labels[i] + '</span></div>';
        }).join('') + '</div>' +
      '</div>' +

      '<div class="quick-grid">' +
        '<button class="quick-card" data-nav="#/admin/content" style="--q:#ef4444;--q-soft:rgba(239,68,68,.12)">' +
          '<span class="q-ic">' + icon('trash', 17, 1.8) + '</span><b>内容管理</b><span>删除违规帖子</span>' +
        '</button>' +
        '<button class="quick-card" data-nav="#/admin/users" style="--q:#3b82f6;--q-soft:rgba(59,130,246,.12)">' +
          '<span class="q-ic">' + icon('users', 17, 1.8) + '</span><b>用户管理</b><span>封禁 / 修改密码</span>' +
        '</button>' +
        '<button class="quick-card" data-nav="#/admin/bars" style="--q:#14b8a6;--q-soft:rgba(20,184,166,.12)">' +
          '<span class="q-ic">' + icon('compass', 17, 1.8) + '</span><b>贴吧管理</b><span>新增 / 改名 / 删除</span>' +
        '</button>' +
        '<button class="quick-card" data-nav="#/home" style="--q:#8b5cf6;--q-soft:rgba(139,92,246,.12)">' +
          '<span class="q-ic">' + icon('home', 17, 1.8) + '</span><b>返回社区</b><span>查看前台效果</span>' +
        '</button>' +
      '</div>' +

      '<div class="section-head"><h3>最近发布</h3><span class="more">共 ' + Store.posts().length + ' 条</span></div>' +
      (recentRows || emptyState('edit', '还没有帖子', '社区刚刚创建，等待第一条内容'));
  }

  function adminContent() {
    var filter = App.ui.adminBar || 'all';
    var q = App.ui.adminQ || '';
    var list = Store.posts({ q: q });
    if (filter !== 'all') list = list.filter(function (p) { return p.barId === filter; });
    var barsAll = Store.bars();

    var chips = '<button class="chip ' + (filter === 'all' ? 'active' : '') + '" data-action="admin-filter" data-value="all">全部</button>' +
      barsAll.map(function (b) {
        return '<button class="chip ' + (filter === b.id ? 'active' : '') + '" data-action="admin-filter" data-value="' + b.id + '">' + esc(b.name) + '</button>';
      }).join('');

    var rows = list.map(function (p) {
      var author = Store.getUser(p.authorId);
      var b = Store.bar(p.barId);
      return '<div class="admin-row">' +
        '<div class="admin-row-top">' +
          '<div class="admin-row-main">' +
            '<h4>' + esc(p.title) + (p.anonymous ? '<span class="pill soft">匿名</span>' : '') + '</h4>' +
            '<p>' + esc(author ? author.nickname : '已注销') + ' · ' + esc(b ? b.name : '未知贴吧') + ' · ' + UI.timeAgo(p.createdAt) + '</p>' +
            '<p class="truncate" style="color:var(--text-3);margin-top:5px;max-width:100%">' + esc(p.content.replace(/\n/g, ' ')) + '</p>' +
            '<div style="display:flex;gap:12px;margin-top:7px;font-size:10px;color:var(--text-3)">' +
              '<span class="mini-stat">' + icon('heart', 11, 2) + p.likes + '</span>' +
              '<span class="mini-stat">' + icon('message', 11, 2) + p.comments.length + '</span>' +
            '</div>' +
          '</div>' +
        '</div>' +
        '<div class="admin-actions">' +
          '<button class="tiny-btn" data-nav="#/post/' + p.id + '">' + icon('eye', 13, 2) + '查看</button>' +
          '<button class="tiny-btn danger" data-action="delete-post" data-id="' + p.id + '">' + icon('trash', 13, 2) + '删除</button>' +
        '</div>' +
      '</div>';
    }).join('');

    return adminHeader('内容管理', '<span class="pill soft">' + list.length + ' 条</span>', '#/admin') +
      adminTabs('content') +
      '<form class="toolbar" data-form="admin-content-search">' +
        '<div class="search-field">' + icon('search', 16, 1.8) +
          '<input name="q" value="' + esc(q) + '" placeholder="搜索标题、正文或作者" autocomplete="off">' +
        '</div>' +
        '<button class="icon-btn accent" type="submit" aria-label="搜索">' + icon('arrowRight', 18, 2) + '</button>' +
      '</form>' +
      '<div class="chip-row" style="margin-bottom:12px">' + chips + '</div>' +
      (rows ? '<div class="admin-list">' + rows + '</div>' : emptyState('trash', '没有匹配的帖子', '试试调整筛选条件或关键词'));
  }

  function adminUsers() {
    var q = App.ui.userQ || '';
    var filter = App.ui.userFilter || 'all';
    var list = Store.searchUsers(q);
    if (filter === 'active') list = list.filter(function (u) { return !u.banned; });
    if (filter === 'banned') list = list.filter(function (u) { return u.banned; });
    var s = Store.stats();

    var rows = list.map(function (u) {
      var days = Math.max(1, Math.floor((Date.now() - u.joinedAt) / 86400000));
      var isAdmin = u.role === 'admin';
      return '<div class="admin-row">' +
        '<div class="admin-row-top">' + UI.avatar(u, 40) +
          '<div class="admin-row-main">' +
            '<h4>' + esc(u.nickname) +
              (isAdmin ? '<span class="pill">' + icon('shield', 10, 2.2) + '管理员</span>' : '') +
              (u.banned ? '<span class="pill danger">已封禁</span>' : '') +
              (u.online && !u.banned ? '<span class="online-dot"></span>' : '') +
            '</h4>' +
            '<p>@' + esc(u.username) + ' · 加入 ' + days + ' 天</p>' +
          '</div>' +
        '</div>' +
        '<div class="admin-actions">' +
          (isAdmin
            ? '<span class="pill soft">' + icon('shield', 10, 2.2) + '受保护账号</span>'
            : '<button class="tiny-btn ' + (u.banned ? '' : 'danger') + '" data-action="toggle-ban" data-id="' + u.id + '">' +
                icon(u.banned ? 'check' : 'ban', 13, 2) + (u.banned ? '解封' : '封禁') + '</button>') +
          '<button class="tiny-btn" data-action="reset-pwd" data-id="' + u.id + '">' + icon('key', 13, 2) + '修改密码</button>' +
        '</div>' +
      '</div>';
    }).join('');

    return adminHeader('用户管理', '<span class="pill soft">' + s.total + ' 人</span>', '#/admin') +
      adminTabs('users') +
      '<div class="admin-stats" style="margin-bottom:14px">' +
        '<div class="stat-card" style="--s:#3b82f6;--s-soft:rgba(59,130,246,.12)"><b>' + s.total + '</b><span>总用户</span></div>' +
        '<div class="stat-card" style="--s:#10b981;--s-soft:rgba(16,185,129,.12)"><b>' + s.online + '</b><span>在线</span></div>' +
        '<div class="stat-card" style="--s:#ef4444;--s-soft:rgba(239,68,68,.12)"><b>' + s.banned + '</b><span>封禁</span></div>' +
      '</div>' +
      '<form class="toolbar" data-form="admin-user-search">' +
        '<div class="search-field">' + icon('search', 16, 1.8) +
          '<input name="q" value="' + esc(q) + '" placeholder="搜索昵称或账号" autocomplete="off">' +
        '</div>' +
        '<button class="icon-btn accent" type="submit" aria-label="搜索">' + icon('arrowRight', 18, 2) + '</button>' +
      '</form>' +
      '<div class="chip-row" style="margin-bottom:12px">' +
        '<button class="chip ' + (filter === 'all' ? 'active' : '') + '" data-action="user-filter" data-value="all">全部</button>' +
        '<button class="chip ' + (filter === 'active' ? 'active' : '') + '" data-action="user-filter" data-value="active">正常</button>' +
        '<button class="chip ' + (filter === 'banned' ? 'active' : '') + '" data-action="user-filter" data-value="banned">已封禁</button>' +
      '</div>' +
      (rows ? '<div class="admin-list">' + rows + '</div>' : emptyState('users', '没有匹配的用户', '换个关键词或筛选条件试试'));
  }

  function adminBars() {
    var mods = Store.modules();
    var groups = mods.map(function (mod) {
      var list = Store.bars(mod.key);
      var rows = list.map(function (b) {
        return '<div class="bar-manage-row">' +
          '<span class="bar-icon" style="' + tint(mod.color) + '">' + icon(b.icon || mod.icon, 19, 1.8) + '</span>' +
          '<span class="bar-info"><h4>' + esc(b.name) + '</h4><p>' + esc(b.desc) + '</p>' +
            '<span class="bar-stats"><span><b>' + Store.countPosts(b.id) + '</b> 帖子</span><span><b>' + b.members + '</b> 成员</span></span>' +
          '</span>' +
          '<span class="row-actions">' +
            '<button class="row-icon-btn" data-action="edit-bar" data-id="' + b.id + '" aria-label="改名">' + icon('edit', 15, 1.9) + '</button>' +
            '<button class="row-icon-btn danger" data-action="delete-bar" data-id="' + b.id + '" aria-label="删除">' + icon('trash', 15, 1.9) + '</button>' +
          '</span>' +
        '</div>';
      }).join('');
      return '<div class="bar-group-title"><i></i>' + esc(mod.label) + ' · ' + list.length + '</div>' +
        (rows || '<p style="font-size:11.5px;color:var(--text-3);padding:6px 4px 10px">该模块下还没有贴吧</p>');
    }).join('');

    return adminHeader('贴吧管理',
      '<button class="icon-btn accent" data-action="new-bar" aria-label="新建贴吧">' + icon('plus', 19, 2.2) + '</button>',
      '#/admin') +
      adminTabs('bars') +
      '<p style="font-size:11px;color:var(--text-3);line-height:1.6;margin:2px 0 6px">新增、改名或删除贴吧。删除贴吧会同时下架该吧内的所有帖子。</p>' +
      groups;
  }

  /* ---------------- 路由装配 ---------------- */
  function route(r) {
    if (r.name === 'auth') return { html: authScreen(), auth: true, noDock: true };

    if (r.name === 'home') return { html: homeScreen(), dock: true };
    if (r.name === 'bars') return { html: barsScreen(), dock: true };

    if (r.name === 'bar') {
      var barHtml = barScreen(r.id);
      return barHtml ? { html: barHtml, dock: true } : null;
    }

    if (r.name === 'post') {
      var postHtml = postScreen(r.id);
      return postHtml ? { html: postHtml, dock: false, hasCommentBar: true, extra: commentBarHTML(r.id) } : null;
    }

    if (r.name === 'compose') return { html: composeScreen(r.barId), dock: false, noDock: true };
    if (r.name === 'search') return { html: searchScreen(), dock: true };
    if (r.name === 'messages') return { html: messagesScreen(), dock: true };
    if (r.name === 'me') return { html: meScreen(), dock: true };

    if (r.name === 'admin') {
      var tab = r.tab || 'overview';
      if (tab === 'content') return { html: adminContent(), dock: false, noDock: true };
      if (tab === 'users') return { html: adminUsers(), dock: false, noDock: true };
      if (tab === 'bars') return { html: adminBars(), dock: false, noDock: true };
      return { html: adminOverview(), dock: false, noDock: true };
    }

    return null;
  }

  window.Screens = {
    route: route,
    statusbar: statusbar,
    dock: dock
  };
})();
