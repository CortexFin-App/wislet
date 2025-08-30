// assets/script.admin.js
(() => {
  // === Константи ===
  const ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMzE0MTcsImV4cCI6MjA2NDkwNzQxN30.2i9ru8fXLZEYD_jNHoHd0ZJmN4k9gKcPOChdiuL_AMY";
  const DEFAULT_ENDPOINT = "https://xdofjorgomwdyawmwbcj.functions.supabase.co/admin-export";
  const GOAL = 3500000; // $35k у центах
  const LSKEY = 'cortexfin_admin_export';

  // UI helpers
  function money(u) { return '$' + (Number(u||0)/100).toLocaleString('en-US', {maximumFractionDigits:2}); }
  function ping(msg, ok) {
    const s = document.getElementById('status');
    s.className = ok ? 'ok' : 'err';
    s.textContent = msg;
  }

  // defaults for dates (last 7d)
  (function setDefaultDates(){
    const u = document.getElementById('paid_until');
    const s = document.getElementById('paid_since');
    const today = new Date();
    const until = today.toISOString().slice(0,10);
    const since = new Date(today.getTime() - 6*864e5).toISOString().slice(0,10);
    u.value = until; s.value = since;
  })();

  // restore saved settings
  (function restore(){
    try {
      const saved = JSON.parse(localStorage.getItem(LSKEY) || '{}');
      document.getElementById('endpoint').value = saved.endpoint || DEFAULT_ENDPOINT;
      if (saved.admkey)   document.getElementById('admkey').value = saved.admkey;
      for (const k of ['format','tier','email','paid_since','paid_until','offset','limit','mode']) {
        if (saved[k] != null) document.getElementById(k).value = saved[k];
      }
    } catch {}
  })();

  // remember
  document.getElementById('rememberBtn').onclick = () => {
    const payload = {};
    for (const id of ['endpoint','admkey','format','tier','email','paid_since','paid_until','offset','limit','mode']) {
      payload[id] = document.getElementById(id).value;
    }
    localStorage.setItem(LSKEY, JSON.stringify(payload));
    ping('Збережено', true);
    setTimeout(loadMetrics, 200);
  };

  // build headers for functions (verify_jwt=true)
  function authHeaders() {
    return {
      'x-admin-key': document.getElementById('admkey').value.trim(),
      'Authorization': `Bearer ${ANON}`,
      'apikey': ANON
    };
  }

  async function loadMetrics() {
    const base = document.getElementById('endpoint').value.trim() || DEFAULT_ENDPOINT;
    const mode = (document.getElementById('mode')?.value || '').trim();
    const url  = mode ? `${base}?metrics=1&mode=${encodeURIComponent(mode)}` : `${base}?metrics=1`;
    try {
      const r = await fetch(url, { headers: authHeaders() });
      const data = await r.json();
      if (!r.ok) throw new Error(data?.error || r.status);

      const gross = Number(data.gross_cents||0);
      const net   = Number(data.net_cents||0);
      const fees  = Number(data.est_fees_cents||0);
      const pct   = Math.max(0, Math.min(100, (net / GOAL) * 100));

      document.getElementById('m_gross').textContent = money(gross);
      document.getElementById('m_net').textContent   = money(net);
      document.getElementById('m_fees').textContent  = money(fees);
      document.getElementById('m_pf').textContent    = data.sold_pf || 0;
      document.getElementById('m_gf').textContent    = data.sold_gf || 0;
      document.getElementById('m_se').textContent    = data.sold_se || 0;
      document.getElementById('q_pf').textContent    = data.quota_pf || 0;
      document.getElementById('q_gf').textContent    = data.quota_gf || 0;
      document.getElementById('q_se').textContent    = data.quota_se || 0;

      document.getElementById('m_fill').style.width = pct.toFixed(2) + '%';
      document.getElementById('m_note').textContent = `Net ${money(net)} / $35,000 (${pct.toFixed(1)}%)`;
    } catch (e) {
      document.getElementById('m_note').textContent = 'Помилка метрик: ' + (e.message || e);
    }
  }
  document.getElementById('reloadMetricsBtn').onclick = loadMetrics;
  loadMetrics();

  function buildURL() {
    const base = document.getElementById('endpoint').value.trim() || DEFAULT_ENDPOINT;
    const p = new URLSearchParams();
    const q = (id) => document.getElementById(id).value.trim();
    const add = (k,v) => { if (v) p.set(k, v); };
    add('format', q('format'));
    add('tier', q('tier'));
    // приймаємо і email_like, і email — функція у нас дружня до обох
    add('email', q('email'));
    add('paid_since', q('paid_since'));
    add('paid_until', q('paid_until'));
    add('offset', q('offset'));
    add('limit', q('limit'));
    return `${base}?${p.toString()}`;
  }

  async function run() {
    const url = buildURL();
    const fmt = document.getElementById('format').value;
    const out = document.getElementById('out');
    out.innerHTML = '';
    ping('Виконую запит…', true);

    try {
      const res = await fetch(url, { headers: authHeaders() });
      if (!res.ok) {
        const text = await res.text();
        ping(`Помилка ${res.status}: ${text}`, false);
        return;
      }

      if (fmt === 'csv') {
        const blob = await res.blob();
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'cards_export.csv';
        a.click();
        URL.revokeObjectURL(a.href);
        ping('CSV завантажено ✔', true);
      } else {
        const data = await res.json();
        ping(`Отримано ${data.length} рядків`, true);
        if (data.length) {
          const cols = Object.keys(data[0]);
          const tbl = document.createElement('table');
          const thead = document.createElement('thead');
          thead.innerHTML = '<tr>' + cols.map(c=>`<th>${c}</th>`).join('') + '</tr>';
          tbl.appendChild(thead);
          const tb = document.createElement('tbody');
          for (const row of data) {
            const tr = document.createElement('tr');
            tr.innerHTML = cols.map(c=>`<td>${row[c] ?? ''}</td>`).join('');
            tb.appendChild(tr);
          }
          tbl.appendChild(tb);
          out.appendChild(tbl);
        } else {
          out.textContent = 'Порожньо';
        }
      }
    } catch (e) {
      ping(String(e), false);
    }
  }
  document.getElementById('runBtn').onclick = run;

  // Manual convert
  document.getElementById('m_run').onclick = async () => {
    const base = document.getElementById('endpoint').value.replace(/\/admin-export.*/, '');
    const url  = base + '/admin-manual-convert';
    const payload = {
      hold_id: Number(document.getElementById('m_hold').value),
      tier   : document.getElementById('m_tier').value,
      provider: document.getElementById('m_provider').value || 'manual',
      tx_id  : document.getElementById('m_txid').value || null,
      amount_cents: Number(document.getElementById('m_amount').value) || null,
      currency: document.getElementById('m_curr').value || 'usd'
    };
    const out = document.getElementById('m_out');
    out.textContent = 'Виконую...';

    try{
      const res = await fetch(url, {
        method:'POST',
        headers: { 'content-type':'application/json', ...authHeaders() },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      out.innerHTML = res.ok
        ? `✔ ok. order_id=${data.order_id ?? '(?)'}; card=${JSON.stringify(data.card)}`
        : `✖ ${data.error || JSON.stringify(data)}`;
      loadMetrics();
    }catch(e){
      out.textContent = String(e);
    }
  };
})();
