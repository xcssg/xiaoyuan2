/* 线性图标库（内联 SVG，离线可用） */
(function () {
  var P = {
    home: '<path d="M4 10.6 12 3.6l8 7V20a1 1 0 0 1-1 1h-4.6v-6H9.6v6H5a1 1 0 0 1-1-1z"/>',
    compass: '<circle cx="12" cy="12" r="8.8"/><path d="m15.4 8.6-2 4.8-4.8 2 2-4.8z"/>',
    chat: '<path d="M20.6 11.6a8.3 8.3 0 0 1-8.8 8.3 9.6 9.6 0 0 1-3.4-.7L3.4 21l1.8-4.6a8.2 8.2 0 0 1-1.3-4.4A8.3 8.3 0 0 1 12 3.3a8.3 8.3 0 0 1 8.6 8.3z"/>',
    user: '<circle cx="12" cy="8.2" r="3.6"/><path d="M4.9 20c.7-3.6 3.5-5.6 7.1-5.6s6.4 2 7.1 5.6"/>',
    users: '<circle cx="9" cy="8.4" r="3.2"/><path d="M3 19.6c.6-3.2 2.9-5 6-5s5.4 1.8 6 5"/><path d="M15.9 5.6a3 3 0 0 1 0 5.8M17.9 14.9c2.1.5 3.5 2 4 4.6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    search: '<circle cx="11" cy="11" r="6.5"/><path d="m16 16 4 4"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    moon: '<path d="M20.6 14.6A8.6 8.6 0 0 1 9.4 3.4a8.6 8.6 0 1 0 11.2 11.2z"/>',
    arrowLeft: '<path d="M15 19l-7-7 7-7"/>',
    arrowRight: '<path d="m9 6 6 6-6 6"/>',
    heart: '<path d="M12 20.2s-7.4-4.6-7.4-9.4a4.1 4.1 0 0 1 7.4-2.9 4.1 4.1 0 0 1 7.4 2.9c0 4.8-7.4 9.4-7.4 9.4z"/>',
    message: '<path d="M21 12a8.5 8.5 0 0 1-12.5 7.5L3 21l1.6-5.2A8.5 8.5 0 1 1 21 12z"/>',
    trash: '<path d="M4 7h16M9 7V5h6v2M6.5 7l.8 13h9.4l.8-13M10 11v5M14 11v5"/>',
    grid: '<rect x="3.5" y="3.5" width="7" height="7" rx="2"/><rect x="13.5" y="3.5" width="7" height="7" rx="2"/><rect x="3.5" y="13.5" width="7" height="7" rx="2"/><rect x="13.5" y="13.5" width="7" height="7" rx="2"/>',
    shield: '<path d="M12 3 5 6v5.5c0 4.3 3 7.7 7 9.5 4-1.8 7-5.2 7-9.5V6z"/><path d="m9.2 12 2.1 2.1 3.9-4"/>',
    eye: '<path d="M2.6 12S6.1 6.6 12 6.6 21.4 12 21.4 12 17.9 17.4 12 17.4 2.6 12 2.6 12z"/><circle cx="12" cy="12" r="2.8"/>',
    ban: '<circle cx="12" cy="12" r="8.8"/><path d="m6.1 6.1 11.8 11.8"/>',
    key: '<circle cx="8" cy="15.2" r="3.4"/><path d="m10.5 12.7 7.8-7.8M16.4 6.8l2 2M13.9 9.3l2 2"/>',
    edit: '<path d="M4 20h4.2L19 9.2 14.8 5 4 15.8z"/><path d="m13.4 6.4 4.2 4.2"/>',
    chevron: '<path d="m9 6 6 6-6 6"/>',
    logout: '<path d="M14 8V5.5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V16"/><path d="M9 12h11M17 9l3 3-3 3"/>',
    sparkles: '<path d="M12 3.2 13.8 8l4.8 1.8-4.8 1.8L12 16.4l-1.8-4.8L5.4 9.8 10.2 8z"/><path d="m18.6 15.4.9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z"/>',
    bell: '<path d="M18 15.2V10a6 6 0 1 0-12 0v5.2L4.4 18h15.2z"/><path d="M10 20.6a2 2 0 0 0 4 0"/>',
    check: '<path d="m5 12.6 4.5 4.5L19 7.4"/>',
    close: '<path d="m6 6 12 12M18 6 6 18"/>',
    send: '<path d="M21 3 10.4 13.6M21 3l-6.4 18-4.2-7.4L3 9.4z"/>',
    lock: '<rect x="4.6" y="10" width="14.8" height="10.4" rx="2.6"/><path d="M8 10V7.6a4 4 0 0 1 8 0V10"/>',
    bolt: '<path d="M13.2 2 4.4 13.6h6.4l-1 8.4 8.8-11.6h-6.4z"/>',
    chart: '<path d="M3.4 20.4h17.2"/><path d="M6 20v-6M10.4 20V5.6M14.8 20v-9.2M19.2 20V8.6"/>',
    more: '<circle cx="5.2" cy="12" r="1.5" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none"/><circle cx="18.8" cy="12" r="1.5" fill="currentColor" stroke="none"/>',
    info: '<circle cx="12" cy="12" r="8.8"/><path d="M12 11v5.2"/><circle cx="12" cy="7.8" r=".9" fill="currentColor" stroke="none"/>',
    clock: '<circle cx="12" cy="12" r="8.8"/><path d="M12 7v5.2l3.2 1.9"/>',
    tag: '<path d="M11.2 3.6H4.4a.8.8 0 0 0-.8.8v6.8L12.6 20l8-8z"/><circle cx="7.6" cy="7.6" r="1.4"/>',
    wifi: '<path d="M4 9.4a12 12 0 0 1 16 0M6.8 12.4a8 8 0 0 1 10.4 0M9.6 15.4a4 4 0 0 1 4.8 0"/><circle cx="12" cy="18.4" r="1.1" fill="currentColor" stroke="none"/>',
    at: '<circle cx="12" cy="12" r="4"/><path d="M16 12v1.6a2.4 2.4 0 0 0 4.8 0V12a8.8 8.8 0 1 0-3.4 7"/>'
  };

  window.Icons = {
    get: function (name, size, stroke) {
      var d = P[name];
      if (!d) d = P.info;
      size = size || 22;
      stroke = stroke || 1.7;
      return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="' + stroke + '" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + d + '</svg>';
    }
  };
})();
