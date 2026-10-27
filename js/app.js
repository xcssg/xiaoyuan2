/* 乌市职专墙 · 应用入口 / 路由 / 交互 */
(function () {
  var ui = {
    authTab: 'login',
    authError: '',
    barsFilter: 'all',
    barSort: 'new',
    composeBar: null,
    anon: false,
    searchQ: '',
    adminQ: '',
    adminBar: 'all',
    userQ: '',
    userFilter: 'all'
  };

  var lastRouteKey = '';
  var pendingFlash = null;

  function flash(message, type) {
    pendingFlash = { message: message, type: type };
  }

  /* ---------------- 路由 ---------------- */
  function parseRoute() {
    var raw = '';
    try { raw = decodeURIComponent(location.hash.replace(/^#/, '')); } catch (e) { raw = location.hash.replace(/^#/, ''); }
    var parts = raw.split('/').filter(Boolean);
    var logged = !!Store.current();

    if (!parts.length) return { name: logged ? 'home' : 'auth' };

    if (parts[0] === 'admin') return { name: 'admin', tab: parts[1] || 'overview' };
    if (parts[0] === 'bar') return { name: 'bar', id: parts[1] || '' };
    if (parts[0] === 'post') return { name: 'post', id: parts[1] || '' };
    if (parts[0] === 'compose') return { name: 'compose', barId: parts[1] || null };

    return { name: parts[0] };
  }

  function routeKey(route) {
    return [route.name, route.id || '', route.tab || '', route.barId || ''].join(':');
  }

  function navigate(hash) {
    if (location.hash === hash) render();
    else location.hash = hash;
  }

  /* ---------------- 主题 ---------------- */
  function applyTheme(theme, remember) {
    document.documentElement.setAttribute('data-theme', theme);
    if (remember !== false) Store.setTheme(theme);
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', theme === 'dark' ? '#08090d' : '#eef4ff');
  }

  function theme() {
    return document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
  }

  /* ---------------- 渲染 ---------------- */
  function render(opts) {
    opts = opts || {};
    var route = parseRoute();
    var user = Store.current();

    if (!user && route.name !== 'auth') { navigate('#/auth'); return; }
    if (user && route.name === 'auth') { navigate('#/home'); return; }
    if (route.name === 'admin' && !Store.isAdmin()) {
      UI.toast('仅管理员可访问', 'error');
      navigate('#/home');
      return;
    }

    var view = Screens.route(route);
    if (!view) {
      UI.toast('内容不存在或已被删除', 'error');
      navigate('#/home');
      return;
    }

    var oldScreen = document.getElementById('screen');
    var scrollTop = oldScreen ? oldScreen.scrollTop : 0;
    var sameRoute = lastRouteKey === routeKey(route);

    var classes = 'screen';
    if (view.auth) classes += ' screen-auth';
    if (view.noDock) classes += ' no-dock';
    if (view.hasCommentBar) classes += ' has-commentbar';
    if (!opts.keepScroll) classes += ' screen-enter';

    var oldLayer = document.querySelector('.app .layer');
    if (oldLayer) oldLayer.remove();

    var root = document.getElementById('root');
    root.innerHTML = '<div class="app">' +
      Screens.statusbar() +
      '<main class="' + classes + '" id="screen">' + view.html + '</main>' +
      (view.extra || '') +
      (view.dock ? Screens.dock(route) : '') +
      '<div class="toast-root" id="toast-root"></div>' +
    '</div>';

    var screen = document.getElementById('screen');
    screen.scrollTop = (opts.keepScroll && sameRoute) ? scrollTop : 0;
    lastRouteKey = routeKey(route);

    if (pendingFlash) {
      var f = pendingFlash;
      pendingFlash = null;
      UI.toast(f.message, f.type);
    }
  }

  /* ---------------- 交互 ---------------- */
  function handleAction(action, el) {
    switch (action) {
      case 'theme': {
        applyTheme(el.dataset.themeValue === 'dark' ? 'dark' : 'light');
        render({ keepScroll: true });
        break;
      }
      case 'auth-tab': {
        ui.authTab = el.dataset.tab === 'register' ? 'register' : 'login';
        ui.authError = '';
        render();
        break;
      }
      case 'fill-demo': {
        if (ui.authTab !== 'login') { ui.authTab = 'login'; ui.authError = ''; render(); }
        var isAdmin = el.dataset.role === 'admin';
        var account = document.getElementById('auth-username');
        var pass = document.getElementById('auth-password');
        if (account) account.value = isAdmin ? 'admin' : 'xiaoyu';
        if (pass) pass.value = isAdmin ? 'admin123' : '123456';
        UI.toast(isAdmin ? '已填充管理员账号，点击登录即可' : '已填充学生账号，点击登录即可', 'success');
        break;
      }
      case 'back': {
        navigate(el.dataset.back || '#/home');
        break;
      }
      case 'logout': {
        UI.confirm({
          title: '退出登录？',
          desc: '退出后需要重新输入账号密码才能发布内容。',
          confirmText: '退出登录',
          danger: true
        }).then(function (ok) {
          if (!ok) return;
          Store.logout();
          ui.authTab = 'login';
          ui.authError = '';
          flash('已退出登录');
          navigate('#/auth');
        });
        break;
      }
      case 'like': {
        try {
          Store.toggleLike(el.dataset.id);
          render({ keepScroll: true });
        } catch (err) {
          UI.toast(err.message, 'error');
        }
        break;
      }
      case 'share': {
        UI.toast('分享链接已复制', 'success');
        break;
      }
      case 'delete-post': {
        doDeletePost(el.dataset.id);
        break;
      }
      case 'sort': {
        ui.barSort = el.dataset.value === 'hot' ? 'hot' : 'new';
        render({ keepScroll: true });
        break;
      }
      case 'bars-filter': {
        ui.barsFilter = el.dataset.value || 'all';
        render();
        break;
      }
      case 'admin-filter': {
        ui.adminBar = el.dataset.value || 'all';
        render({ keepScroll: true });
        break;
      }
      case 'user-filter': {
        ui.userFilter = el.dataset.value || 'all';
        render({ keepScroll: true });
        break;
      }
      case 'pick-bar': {
        ui.composeBar = el.dataset.id;
        var wrap = el.parentNode;
        if (wrap) {
          Array.prototype.forEach.call(wrap.querySelectorAll('.bar-select'), function (node) {
            node.classList.toggle('active', node === el);
          });
        }
        break;
      }
      case 'toggle-anon': {
        ui.anon = !ui.anon;
        el.classList.toggle('on', ui.anon);
        break;
      }
      case 'mark-all-read': {
        Store.markAllRead();
        render({ keepScroll: true });
        UI.toast('已全部标记为已读', 'success');
        break;
      }
      case 'read-msg': {
        Store.markRead(el.dataset.id);
        render({ keepScroll: true });
        break;
      }
      case 'quick-search': {
        ui.searchQ = el.dataset.q || '';
        render();
        break;
      }
      case 'toggle-ban': {
        doToggleBan(el.dataset.id);
        break;
      }
      case 'reset-pwd': {
        doResetPassword(el.dataset.id);
        break;
      }
      case 'new-bar': {
        doNewBar();
        break;
      }
      case 'edit-bar': {
        doEditBar(el.dataset.id);
        break;
      }
      case 'delete-bar': {
        doDeleteBar(el.dataset.id);
        break;
      }
      case 'account-info': {
        var u = Store.current();
        if (!u) return;
        var days = Math.max(1, Math.floor((Date.now() - u.joinedAt) / 86400000));
        UI.dialog({
          title: '账号信息',
          desc: '<div style="font-size:12.5px;line-height:2">' +
            '昵称：<b>' + UI.esc(u.nickname) + '</b><br>' +
            '账号：' + UI.esc(u.username) + '<br>' +
            '身份：' + (u.role === 'admin' ? '管理员' : '学生用户') + '<br>' +
            '加入时间：' + UI.dateStr(u.joinedAt) + '（' + days + ' 天）<br>' +
            '账号状态：' + (u.banned ? '已封禁' : '正常') +
          '</div>'
        });
        break;
      }
      case 'about': {
        UI.dialog({
          title: '关于乌市职专墙',
          desc: '<div style="font-size:12.5px;line-height:1.8">' +
            '乌市职专墙是面向校园的互助社区，包含寻物、吐槽、表白、找人四个模块。<br><br>' +
            '当前为 <b>UI 预览版</b>，数据保存在本机浏览器中。<br>' +
            '确认界面后，将接入服务端并打包为 Android 应用。' +
          '</div>' +
          '<p style="margin-top:14px;font-size:10px;color:var(--text-3);letter-spacing:.1em">VERSION 0.1 · CAMPUS WALL</p>'
        });
        break;
      }
      default:
        break;
    }
  }

  function doDeletePost(id) {
    var p = Store.post(id);
    if (!p) return;
    UI.confirm({
      title: '删除这条帖子？',
      desc: '「' + UI.esc(p.title) + '」将从社区中移除，删除后不可恢复。',
      confirmText: '删除',
      danger: true
    }).then(function (ok) {
      if (!ok) return;
      try {
        Store.deletePost(id);
        flash('帖子已删除', 'success');
        if (parseRoute().name === 'post') navigate('#/bar/' + p.barId);
        else render({ keepScroll: true });
      } catch (err) {
        UI.toast(err.message, 'error');
      }
    });
  }

  function doToggleBan(id) {
    var u = Store.getUser(id);
    if (!u) return;
    var banning = !u.banned;
    UI.confirm({
      title: banning ? '封禁该用户？' : '解除封禁？',
      desc: banning
        ? '「' + UI.esc(u.nickname) + '」将无法登录、发帖和评论，已发布内容仍会保留。'
        : '解除后，该用户将恢复登录和发言权限。',
      confirmText: banning ? '封禁' : '解封',
      danger: banning
    }).then(function (ok) {
      if (!ok) return;
      try {
        Store.toggleBan(id);
        flash(banning ? '用户已封禁' : '用户已解封', 'success');
        render({ keepScroll: true });
      } catch (err) {
        UI.toast(err.message, 'error');
      }
    });
  }

  function doResetPassword(id) {
    var u = Store.getUser(id);
    if (!u) return;
    UI.formModal({
      title: '修改登录密码',
      desc: '为「' + UI.esc(u.nickname) + '」设置新的登录密码，建议告知本人后尽快修改。',
      fields: [
        { name: 'password', label: '新密码', type: 'password', placeholder: '至少 6 位', minlength: 6, maxlength: 20 }
      ],
      confirmText: '保存'
    }).then(function (data) {
      if (!data) return;
      try {
        Store.setPassword(id, data.password);
        UI.toast('登录密码已更新', 'success');
      } catch (err) {
        UI.toast(err.message, 'error');
      }
    });
  }

  function doNewBar() {
    var mods = Store.modules();
    UI.formModal({
      title: '新建贴吧',
      desc: '选择所属模块，并填写贴吧名称与介绍。',
      fields: [
        {
          name: 'module', label: '所属模块', type: 'select', value: mods[0].key,
          options: mods.map(function (m) { return { value: m.key, label: m.label }; })
        },
        { name: 'name', label: '贴吧名称', placeholder: '例如：二手交易吧', minlength: 2, maxlength: 12 },
        { name: 'desc', label: '一句介绍', placeholder: '这个贴吧是做什么的？', maxlength: 30, required: false }
      ],
      confirmText: '创建'
    }).then(function (data) {
      if (!data) return;
      try {
        Store.addBar(data);
        flash('贴吧已创建', 'success');
        render({ keepScroll: true });
      } catch (err) {
        UI.toast(err.message, 'error');
      }
    });
  }

  function doEditBar(id) {
    var b = Store.bar(id);
    if (!b) return;
    var mods = Store.modules();
    UI.formModal({
      title: '编辑贴吧',
      desc: '可以修改名称、介绍或所属模块。',
      fields: [
        {
          name: 'module', label: '所属模块', type: 'select', value: b.module,
          options: mods.map(function (m) { return { value: m.key, label: m.label }; })
        },
        { name: 'name', label: '贴吧名称', value: b.name, minlength: 2, maxlength: 12 },
        { name: 'desc', label: '一句介绍', value: b.desc, maxlength: 30, required: false }
      ],
      confirmText: '保存'
    }).then(function (data) {
      if (!data) return;
      try {
        Store.updateBar(id, data);
        flash('贴吧信息已更新', 'success');
        render({ keepScroll: true });
      } catch (err) {
        UI.toast(err.message, 'error');
      }
    });
  }

  function doDeleteBar(id) {
    var b = Store.bar(id);
    if (!b) return;
    var count = Store.countPosts(id);
    UI.confirm({
      title: '删除「' + UI.esc(b.name) + '」？',
      desc: '该贴吧下的 ' + count + ' 条帖子会一并下架，此操作不可恢复。',
      confirmText: '删除贴吧',
      danger: true
    }).then(function (ok) {
      if (!ok) return;
      try {
        Store.deleteBar(id);
        flash('贴吧已删除', 'success');
        render({ keepScroll: true });
      } catch (err) {
        UI.toast(err.message, 'error');
      }
    });
  }

  /* ---------------- 表单 ---------------- */
  function onSubmit(e) {
    var form = e.target.closest('form[data-form]');
    if (!form) return;
    e.preventDefault();

    var type = form.dataset.form;
    var data = new FormData(form);

    if (type === 'login') {
      try {
        var user = Store.login(data.get('username'), data.get('password'));
        ui.authError = '';
        ui.authTab = 'login';
        flash('欢迎回来，' + user.nickname, 'success');
        navigate('#/home');
      } catch (err) {
        ui.authError = err.message;
        render();
        UI.toast(err.message, 'error');
      }
      return;
    }

    if (type === 'register') {
      try {
        var newUser = Store.register({
          nickname: data.get('nickname'),
          username: data.get('username'),
          password: data.get('password')
        });
        ui.authError = '';
        flash('注册成功，欢迎加入乌市职专墙', 'success');
        navigate('#/home');
      } catch (err) {
        ui.authError = err.message;
        render();
        UI.toast(err.message, 'error');
      }
      return;
    }

    if (type === 'compose') {
      try {
        var post = Store.createPost({
          barId: ui.composeBar,
          title: data.get('title'),
          content: data.get('content'),
          anonymous: ui.anon
        });
        ui.anon = false;
        flash('发布成功', 'success');
        navigate('#/post/' + post.id);
      } catch (err) {
        UI.toast(err.message, 'error');
      }
      return;
    }

    if (type === 'comment') {
      try {
        Store.addComment(form.dataset.id, data.get('content'));
        form.reset();
        render({ keepScroll: true });
        UI.toast('评论成功', 'success');
      } catch (err) {
        UI.toast(err.message, 'error');
      }
      return;
    }

    if (type === 'search') {
      ui.searchQ = (data.get('q') || '').trim();
      render();
      return;
    }

    if (type === 'admin-content-search') {
      ui.adminQ = (data.get('q') || '').trim();
      render({ keepScroll: true });
      return;
    }

    if (type === 'admin-user-search') {
      ui.userQ = (data.get('q') || '').trim();
      render({ keepScroll: true });
    }
  }

  /* ---------------- 启动 ---------------- */
  function updateClock() {
    var el = document.querySelector('.statusbar .sb-left');
    if (!el) return;
    var d = new Date();
    el.textContent = d.getHours() + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  function init() {
    var saved = Store.getTheme();
    var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    applyTheme(saved || (prefersDark ? 'dark' : 'light'), false);

    document.addEventListener('click', function (e) {
      var nav = e.target.closest('[data-nav]');
      if (nav) {
        e.preventDefault();
        navigate(nav.dataset.nav);
        return;
      }
      var actionEl = e.target.closest('[data-action]');
      if (!actionEl) return;
      e.preventDefault();
      handleAction(actionEl.dataset.action, actionEl);
    });

    document.addEventListener('submit', onSubmit);
    window.addEventListener('hashchange', function () { render(); });

    if (!location.hash) location.hash = Store.current() ? '#/home' : '#/auth';
    render();
    setInterval(updateClock, 30000);
  }

  window.App = {
    ui: ui,
    render: render,
    navigate: navigate,
    theme: theme,
    init: init
  };

  init();
})();
