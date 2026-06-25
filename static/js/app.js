/* Hanging Conveyor Dashboard - front-end */

const PALETTE = ['#001848', '#0056d2', '#435b9f', '#7996e3', '#b2c5ff', '#e17d5a'];
const fmtInt = new Intl.NumberFormat('vi-VN');
const fmtPct = (v) => (v == null ? '—' : `${(v * 100).toFixed(2)}%`);

const charts = {};

const els = {
  from: document.getElementById('filter-from'),
  to: document.getElementById('filter-to'),
  line: document.getElementById('filter-line'),
  plan: document.getElementById('filter-plan'),
  apply: document.getElementById('btn-apply'),
  kpiOutput: document.getElementById('kpi-output'),
  kpiDefect: document.getElementById('kpi-defect'),
  kpiDefectRate: document.getElementById('kpi-defect-rate'),
  kpiLines: document.getElementById('kpi-lines'),
  kpiPlans: document.getElementById('kpi-plans'),
  kpiWorkers: document.getElementById('kpi-workers'),
  rangeMeta: document.getElementById('range-meta'),
  planTbody: document.querySelector('#table-plan tbody'),
  workerTbody: document.querySelector('#table-workers tbody'),
  planSearch: document.getElementById('plan-search'),
  workerSearch: document.getElementById('worker-search'),
  healthDot: document.getElementById('health-dot'),
  healthText: document.getElementById('health-text'),
};

let cache = { plan: [], workers: [] };

function extractPlanKey(value) {
  if (!value) return '';
  const match = String(value).match(/#\S+/);
  return match ? match[0] : String(value);
}

function buildParams() {
  const p = new URLSearchParams({
    from: els.from.value,
    to: els.to.value,
  });
  if (els.line.value) p.set('line', els.line.value);
  if (els.plan.value) p.set('plan', els.plan.value);
  return p;
}

async function api(path, params) {
  const q = params ? `?${params}` : '';
  const res = await fetch(`/api${path}${q}`);
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`${path}: ${res.status} ${txt}`);
  }
  return res.json();
}

async function loadLines() {
  const lines = await api('/filters/lines');
  els.line.innerHTML = '<option value="">Tất cả</option>' +
    lines.map((l) => `<option value="${l.line_no}">Tổ ${l.line_no}</option>`).join('');
}

async function loadPlans() {
  const params = new URLSearchParams({
    from: els.from.value,
    to: els.to.value,
  });
  if (els.line.value) params.set('line', els.line.value);

  const plans = await api('/filters/plans', params);
  const prev = els.plan.value;

  els.plan.innerHTML = '<option value="">Tất cả</option>' +
    plans.map((p) => {
      const planKey = p.plan_key || extractPlanKey(p.mo_no) || extractPlanKey(p.style_no);
      const lineNo = p.line_no ?? '';
      return `<option value="${planKey}">${planKey}${lineNo ? ` · Tổ ${lineNo}` : ''}</option>`;
    }).join('');

  els.plan.value = plans.some((p) => (p.plan_key || extractPlanKey(p.mo_no) || extractPlanKey(p.style_no)) === prev) ? prev : '';
}

async function loadSummary(params) {
  const s = await api('/summary', params);
  els.kpiOutput.textContent = fmtInt.format(s.output_qty ?? 0);
  els.kpiDefect.textContent = fmtInt.format(s.defect_qty ?? 0);
  const rate = s.output_qty ? s.defect_qty / s.output_qty : 0;
  els.kpiDefectRate.textContent = s.output_qty ? `tỷ lệ ${fmtPct(rate)}` : '';
  els.kpiLines.textContent = fmtInt.format(s.lines_active ?? 0);
  els.kpiPlans.textContent = fmtInt.format(s.plans_active ?? 0);
  els.kpiWorkers.textContent = fmtInt.format(s.workers_active ?? 0);

  const bits = [`Khoảng dữ liệu: ${els.from.value} → ${els.to.value}`];
  if (els.line.value) bits.push(`Tổ ${els.line.value}`);
  if (els.plan.value) bits.push(els.plan.value);
  bits.push(`${fmtInt.format(s.days_active ?? 0)} ngày có dữ liệu`);
  els.rangeMeta.textContent = bits.join(' · ');
}

function destroyChart(key) {
  if (charts[key]) {
    charts[key].destroy();
    delete charts[key];
  }
}

function commonChartOpts() {
  return {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        labels: {
          color: '#424654',
          font: { family: 'Inter', size: 12 },
          boxWidth: 12,
          boxHeight: 12,
          usePointStyle: true,
        },
      },
      tooltip: {
        backgroundColor: '#2e3132',
        titleFont: { family: 'Manrope', weight: '600' },
        bodyFont: { family: 'Inter' },
        padding: 10,
        cornerRadius: 6,
      },
    },
    scales: {
      x: { grid: { display: false }, ticks: { color: '#424654' } },
      y: { grid: { color: 'rgba(25,28,29,0.06)' }, ticks: { color: '#424654' } },
    },
  };
}

async function loadDaily(params) {
  const rows = await api('/output/by-day', params);
  const days = [...new Set(rows.map((r) => r.day))].sort();
  const lines = [...new Set(rows.map((r) => r.line_no))].sort((a, b) => a - b);

  const datasets = lines.map((ln, i) => ({
    label: `Tổ ${ln}`,
    data: days.map((d) => {
      const row = rows.find((r) => r.day === d && r.line_no === ln);
      return row ? row.output_qty : 0;
    }),
    borderColor: PALETTE[i % PALETTE.length],
    backgroundColor: `${PALETTE[i % PALETTE.length]}33`,
    tension: 0.35,
    fill: false,
    pointRadius: 3,
    pointHoverRadius: 5,
    borderWidth: 2,
  }));

  destroyChart('daily');
  charts.daily = new Chart(document.getElementById('chart-daily'), {
    type: 'line',
    data: { labels: days, datasets },
    options: commonChartOpts(),
  });
}

async function loadByLine() {
  const p = new URLSearchParams({ from: els.from.value, to: els.to.value });
  if (els.plan.value) p.set('plan', els.plan.value);

  const rows = await api('/output/by-line', p);
  destroyChart('byLine');
  charts.byLine = new Chart(document.getElementById('chart-by-line'), {
    type: 'bar',
    data: {
      labels: rows.map((r) => `Tổ ${r.line_no}`),
      datasets: [{
        label: 'OutputQty',
        data: rows.map((r) => r.output_qty),
        backgroundColor: rows.map((_, i) => PALETTE[i % PALETTE.length]),
        borderRadius: 8,
        borderSkipped: false,
      }],
    },
    options: {
      ...commonChartOpts(),
      plugins: { ...commonChartOpts().plugins, legend: { display: false } },
    },
  });
}

async function loadHourly(params) {
  const { slots, rows } = await api('/output/by-slot', params);
  const slotNos = slots.map((s) => s.slot);
  const labels = slots.map((s) => s.label);
  const lines = [...new Set(rows.map((r) => r.line_no))].sort((a, b) => a - b);

  const datasets = lines.map((ln, i) => ({
    label: `Tổ ${ln}`,
    data: slotNos.map((s) => {
      const row = rows.find((r) => r.slot === s && r.line_no === ln);
      return row ? row.output_qty : 0;
    }),
    backgroundColor: PALETTE[i % PALETTE.length],
    borderRadius: 6,
    borderSkipped: false,
  }));

  destroyChart('hourly');
  charts.hourly = new Chart(document.getElementById('chart-hourly'), {
    type: 'bar',
    data: { labels, datasets },
    options: {
      ...commonChartOpts(),
      scales: {
        x: { stacked: true, grid: { display: false }, ticks: { color: '#424654' } },
        y: { stacked: true, grid: { color: 'rgba(25,28,29,0.06)' }, ticks: { color: '#424654' } },
      },
    },
  });
}

function renderPlanRows(rows) {
  if (!rows.length) {
    els.planTbody.innerHTML = '<tr><td colspan="11" class="empty">Không có dữ liệu trong khoảng đã chọn.</td></tr>';
    return;
  }

  els.planTbody.innerHTML = rows.map((r) => {
    const rate = r.output_qty ? r.defect_qty / r.output_qty : 0;
    return `
    <tr>
      <td>${r.day ?? ''}</td>
      <td>${r.mo_no ?? ''}</td>
      <td>${r.plan_key ?? ''}</td>
      <td>${r.style_no ?? ''}</td>
      <td>${r.po_no ?? ''}</td>
      <td>${r.color_no ?? ''}</td>
      <td>${r.size_no ?? ''}</td>
      <td><span class="pill">Tổ ${r.line_no}</span></td>
      <td class="num">${fmtInt.format(r.output_qty ?? 0)}</td>
      <td class="num">${fmtInt.format(r.defect_qty ?? 0)}</td>
      <td class="num">${r.output_qty ? fmtPct(rate) : '—'}</td>
    </tr>`;
  }).join('');
}

function renderWorkerRows(rows) {
  if (!rows.length) {
    els.workerTbody.innerHTML = '<tr><td colspan="12" class="empty">Không có dữ liệu công nhân.</td></tr>';
    return;
  }

  els.workerTbody.innerHTML = rows.map((r) => `
    <tr>
      <td>${r.day ?? ''}</td>
      <td><span class="pill">Tổ ${r.line_no}</span></td>
      <td>${r.station_no ?? ''}</td>
      <td>${r.emp_id ?? ''}</td>
      <td>${r.emp_name ?? ''}</td>
      <td>${r.mo_no ?? ''}</td>
      <td>${(r.color_no ?? '')} / ${(r.size_no ?? '')}</td>
      <td class="num">${fmtInt.format(r.seq_count ?? 0)}</td>
      <td class="num">${fmtInt.format(r.output_qty ?? 0)}</td>
      <td class="num">${fmtInt.format(r.defect_qty ?? 0)}</td>
      <td class="num">${(r.real_minute ?? 0).toLocaleString('vi-VN')}</td>
      <td class="num">${r.efficiency != null ? fmtPct(r.efficiency) : '—'}</td>
    </tr>`).join('');
}

function filterRows(rows, q, fields) {
  if (!q) return rows;
  const needle = q.toLowerCase();
  return rows.filter((r) => fields.some((f) => String(r[f] ?? '').toLowerCase().includes(needle)));
}

async function loadPlanTable(params) {
  cache.plan = await api('/output/by-plan', params);
  renderPlanRows(filterRows(
    cache.plan,
    els.planSearch.value,
    ['plan_key', 'mo_no', 'style_no', 'po_no', 'color_no', 'size_no'],
  ));
}

async function loadWorkers(params) {
  cache.workers = await api('/workers', params);
  renderWorkerRows(filterRows(
    cache.workers,
    els.workerSearch.value,
    ['plan_key', 'mo_no', 'emp_id', 'emp_name', 'station_no', 'color_no'],
  ));
}

async function loadHealth() {
  try {
    const h = await api('/health');
    if (h.ok) {
      els.healthDot.className = 'ok';
      els.healthText.textContent = `Đã kết nối ${h.server} · ${h.db}`;
    } else {
      els.healthDot.className = 'err';
      els.healthText.textContent = `Lỗi kết nối: ${h.error}`;
    }
  } catch (e) {
    els.healthDot.className = 'err';
    els.healthText.textContent = `Lỗi: ${e.message}`;
  }
}

async function refreshAll() {
  try {
    await loadPlans();
    const p = buildParams();
    await Promise.all([
      loadSummary(p),
      loadDaily(p),
      loadByLine(),
      loadHourly(p),
      loadPlanTable(p),
      loadWorkers(p),
    ]);
  } catch (e) {
    console.error(e);
    alert(`Có lỗi khi tải dữ liệu:\n${e.message}`);
  }
}

els.apply.addEventListener('click', refreshAll);
els.from.addEventListener('change', loadPlans);
els.to.addEventListener('change', loadPlans);
els.line.addEventListener('change', loadPlans);
els.planSearch.addEventListener('input', () => {
  renderPlanRows(filterRows(
    cache.plan,
    els.planSearch.value,
    ['plan_key', 'mo_no', 'style_no', 'po_no', 'color_no', 'size_no'],
  ));
});
els.workerSearch.addEventListener('input', () => {
  renderWorkerRows(filterRows(
    cache.workers,
    els.workerSearch.value,
    ['plan_key', 'mo_no', 'emp_id', 'emp_name', 'station_no', 'color_no'],
  ));
});

(async function init() {
  await loadHealth();
  await loadLines();
  await refreshAll();
})();
