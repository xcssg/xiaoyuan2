/* 乌市职专墙 · 通用 UI 能力 */
(function () {
  function esc(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (ch) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch];
    });
  }

  function avatar(user, size) {
    size = size || 40;
    var name = user ? (user.nickname || user.username || '?') : '?';
    var idx = user && typeof user.avatar === 'number' ? user.avatar % 6 : 0;
    return '<span class="avatar av-' + idx + '" style="width:' + size + 'px;height:' + size + 'px;font-size:' +
      Math.round(size * 0.4) + 'px">' + esc(String(name).slice(0, 1)) + '</span>';
  }

  function anonymousAvatar(size) {
    size = size || 40;
    return '<span class="avatar av-5" style="width:' + size + 'px;height:' + size + 'px;font-size:' +
      Math.round(size * 0.4) + 'px">匿</span>';
  }

  function timeAgo(ts) {
    var diff = Date.now() - ts;
    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return Math.floor(diff / 60000) + ' 分钟前';
    if (diff < 86400000) return Math.floor(diff / 3600000) + ' 小时前';
    if (diff < 172800000) return '昨天';
    if (diff < 604800000) return Math.floor(diff / 86400000) + ' 天前';
    var d = new Date(ts);
    return (d.getMonth() + 1) + ' 月 ' + d.getDate() + ' 日';
  }

  function dateStr(ts) {
    var d = new Date(ts);
    return d.getFullYear() + '.' + String(d.getMonth() + 1).padStart(2, '0') + '.' + String(d.getDate()).padStart(2, '0');
  }

  function toast(message, type) {
    var root = document.getElementById('toast-root');
    if (!root) return;
    var el = document.createElement('div');
    el.className = 'toast ' + (type || 'info');
    var icon = type === 'success' ? 'check' : 'info';
    el.innerHTML = Icons.get(icon, 16, 2) + '<span>' + esc(message) + '</span>';
    root.appendChild(el);
    setTimeout(function () {
      el.classList.add('out');
      setTimeout(function () { el.remove(); }, 260);
    }, 2100);
  }

  function openLayer(inner) {
    var app = document.querySelector('.app');
    if (!app) return null;
    var layer = document.createElement('div');
    layer.className = 'layer';
    layer.innerHTML = inner;
    app.appendChild(layer);
    return layer;
  }

  function closeLayer(layer) {
    if (layer) layer.remove();
  }

  function dialog(opts) {
    opts = opts || {};
    return new Promise(function (resolve) {
      var layer = openLayer(
        '<div class="layer-card" role="dialog" aria-modal="true">' +
          '<h3>' + esc(opts.title || '提示') + '</h3>' +
          '<div class="layer-desc">' + (opts.desc || '') + '</div>' +
          '<div class="layer-actions">' +
            '<button class="btn btn-primary" data-x="ok">' + esc(opts.confirmText || '知道了') + '</button>' +
          '</div>' +
        '</div>'
      );
      if (!layer) return resolve();
      function done() {
        closeLayer(layer);
        document.removeEventListener('keydown', onKey);
        resolve();
      }
      function onKey(e) { if (e.key === 'Escape') done(); }
      layer.addEventListener('click', function (e) {
        if (e.target === layer) return done();
        if (e.target.closest('[data-x="ok"]')) done();
      });
      document.addEventListener('keydown', onKey);
    });
  }

  function confirm(opts) {
    opts = opts || {};
    return new Promise(function (resolve) {
      var danger = !!opts.danger;
      var layer = openLayer(
        '<div class="layer-card" role="dialog" aria-modal="true">' +
          '<h3>' + esc(opts.title || '确认操作') + '</h3>' +
          '<div class="layer-desc">' + (opts.desc || '') + '</div>' +
          '<div class="layer-actions">' +
            '<button class="btn btn-ghost" data-x="cancel">' + esc(opts.cancelText || '取消') + '</button>' +
            '<button class="btn ' + (danger ? 'btn-danger' : 'btn-primary') + '" data-x="ok">' +
              esc(opts.confirmText || '确定') + '</button>' +
          '</div>' +
        '</div>'
      );
      if (!layer) return resolve(false);
      function done(val) {
        closeLayer(layer);
        document.removeEventListener('keydown', onKey);
        resolve(val);
      }
      function onKey(e) { if (e.key === 'Escape') done(false); }
      layer.addEventListener('click', function (e) {
        if (e.target === layer) return done(false);
        var btn = e.target.closest('[data-x]');
        if (!btn) return;
        done(btn.dataset.x === 'ok');
      });
      document.addEventListener('keydown', onKey);
    });
  }

  function fieldHTML(field) {
    var icon = field.type === 'password' ? 'lock' : (field.icon || 'edit');
    var label = '<p class="field-label">' + esc(field.label) + '</p>';
    var common = 'name="' + esc(field.name) + '" placeholder="' + esc(field.placeholder || '') + '"' +
      (field.required === false ? '' : ' required') +
      (field.minlength ? ' minlength="' + field.minlength + '"' : '') +
      (field.maxlength ? ' maxlength="' + field.maxlength + '"' : '') +
      ' value="' + esc(field.value || '') + '"';

    if (field.type === 'select') {
      var options = (field.options || []).map(function (opt) {
        var selected = opt.value === field.value ? ' selected' : '';
        return '<option value="' + esc(opt.value) + '"' + selected + '>' + esc(opt.label) + '</option>';
      }).join('');
      return '<div>' + label + '<div class="field">' +
        '<select ' + common + '>' + options + '</select>' +
        Icons.get('chevron', 16, 2) + '</div></div>';
    }

    if (field.type === 'textarea') {
      return '<div>' + label +
        '<textarea class="field-area" ' + common + ' style="min-height:96px">' + esc(field.value || '') + '</textarea>' +
        '</div>';
    }

    return '<div>' + label + '<div class="field">' + Icons.get(icon, 18, 1.8) +
      '<input type="' + (field.type || 'text') + '" ' + common + ' autocomplete="off">' +
      '</div></div>';
  }

  function formModal(opts) {
    opts = opts || {};
    var fields = opts.fields || [];
    return new Promise(function (resolve) {
      var fieldsHTML = fields.map(fieldHTML).join('');
      var danger = !!opts.danger;
      var layer = openLayer(
        '<div class="layer-card" role="dialog" aria-modal="true">' +
          '<h3>' + esc(opts.title || '填写信息') + '</h3>' +
          (opts.desc ? '<div class="layer-desc">' + opts.desc + '</div>' : '') +
          '<form class="layer-form">' + fieldsHTML +
            '<div class="layer-actions">' +
              '<button type="button" class="btn btn-ghost" data-x="cancel">取消</button>' +
              '<button type="submit" class="btn ' + (danger ? 'btn-danger' : 'btn-primary') + '">' +
                esc(opts.confirmText || '确定') + '</button>' +
            '</div>' +
          '</form>' +
        '</div>'
      );
      if (!layer) return resolve(null);
      var form = layer.querySelector('form');

      function done(val) {
        closeLayer(layer);
        document.removeEventListener('keydown', onKey);
        resolve(val);
      }
      function onKey(e) { if (e.key === 'Escape') done(null); }

      layer.addEventListener('click', function (e) {
        if (e.target === layer) return done(null);
        if (e.target.closest('[data-x="cancel"]')) done(null);
      });

      form.addEventListener('submit', function (e) {
        e.preventDefault();
        var data = {};
        fields.forEach(function (f) { data[f.name] = (form.elements[f.name] || {}).value || ''; });
        done(data);
      });

      document.addEventListener('keydown', onKey);
      setTimeout(function () {
        var first = form.querySelector('input, textarea, select');
        if (first) first.focus();
      }, 120);
    });
  }

  window.UI = {
    esc: esc,
    avatar: avatar,
    anonymousAvatar: anonymousAvatar,
    timeAgo: timeAgo,
    dateStr: dateStr,
    toast: toast,
    dialog: dialog,
    confirm: confirm,
    formModal: formModal
  };
})();
