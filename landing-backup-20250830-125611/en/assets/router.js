(() => {
  // Мапимо “красиві” URL → якір на /en/index.html
  const map = {
    '/product':  '#product',
    '/pricing':  '#pricing',
    '/faq':      '#faq',
    '/security': '#security',
    '/blog':     '#blog'
  };

  const p = (location.pathname || '').replace(/\/+$/, '');
  if (map[p]) {
    const hash = map[p];
    history.replaceState({}, '', '/en/' + hash);
    // мʼякий скрол
    const el = document.querySelector(hash);
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
})();
