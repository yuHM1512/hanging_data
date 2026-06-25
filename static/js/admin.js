// Shared admin helpers
window.Admin = (() => {
  async function fetchJSON(url, opts = {}) {
    const headers = { 'Content-Type': 'application/json', ...(opts.headers || {}) };
    const resp = await fetch(url, { ...opts, headers });
    let data;
    try {
      data = await resp.json();
    } catch (_) {
      throw new Error(`HTTP ${resp.status} (không phải JSON)`);
    }
    if (!resp.ok) {
      const msg = data && data.detail ? data.detail : `HTTP ${resp.status}`;
      throw new Error(msg);
    }
    return data;
  }

  function toast(msg, type = '') {
    const el = document.getElementById('toast');
    if (!el) return;
    el.textContent = msg;
    el.className = `toast show ${type}`;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => el.classList.remove('show'), 3000);
  }

  function escape(s) {
    if (s == null) return '';
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  async function logout(nextUrl = '/login') {
    await fetchJSON('/auth/api/logout', { method: 'POST' });
    window.location.href = nextUrl;
  }

  return { fetchJSON, toast, escape, logout };
})();
