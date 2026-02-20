const RESOURCE = (window.GetParentResourceName ? GetParentResourceName() : 'BenBlipCreator');
const $ = (id) => document.getElementById(id);

let state = { rows: [], selectedId: null };
let REF = { blips: [], colors: [], ready: false };
let I18N = {};
let spritePage = 1;
const SPRITES_PER_PAGE = 400;

let didBind = false;

function postNui(name, data = {}) {
  return fetch(`https://${RESOURCE}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).then(async r => {
    try { return await r.json(); } catch { return {}; }
  });
}

function setStatus(msg) {
  $('status').textContent = msg || '';
}

function t(key, vars){
  let s = I18N[key] || key;
  if (vars){
    for (const k in vars){
      s = s.replaceAll(`{${k}}`, String(vars[k]));
    }
  }
  return s;
}

async function loadLocale(){
  const res = await postNui('getLocale', {});
  if (res && res.ok){
    I18N = res.dict || {};
  }
  applyLocale();
}

function applyLocale(){
  $('t_title').textContent = t('ui_title');
  $('search').placeholder = t('ui_search');
  $('btnClose').textContent = t('ui_close');

  $('t_list_title').textContent = t('list_title');
  $('t_editor_title').textContent = t('editor_title');

  $('l_name').textContent = t('field_name');
  $('l_label').textContent = t('field_label');
  $('l_sprite').textContent = t('field_sprite');
  $('l_color').textContent = t('field_color');
  $('l_scale').textContent = t('field_scale');
  $('l_display').textContent = t('field_display');
  $('l_shortrange').textContent = t('field_shortrange');
  $('l_enabled').textContent = t('field_enabled');
  $('l_visibility').textContent = t('field_visibility');
  $('opt_vis_all').textContent = t('vis_all');
  $('opt_vis_job').textContent = t('vis_job');
  $('opt_vis_job_grade').textContent = t('vis_job_grade');
  $('l_job').textContent = t('field_job');
  $('l_job_grade').textContent = t('field_job_grade');
  $('l_x').textContent = t('field_x');
  $('l_y').textContent = t('field_y');
  $('l_z').textContent = t('field_z');

  $('btnPickSprite').textContent = t('btn_pick');
  $('btnPickColor').textContent = t('btn_pick');
  $('btnUsePos').textContent = t('btn_usepos');
  $('btnPreview').textContent = t('btn_preview');
  $('btnCreate').textContent = t('btn_create');
  $('btnUpdate').textContent = t('btn_save');
  $('btnToggle').textContent = t('btn_toggle');
  $('btnDelete').textContent = t('btn_delete');

  $('t_sprite_picker').textContent = t('picker_sprite_title');
  $('t_color_picker').textContent = t('picker_color_title');
  $('spriteSearch').placeholder = t('picker_search_sprite');
  $('colorSearch').placeholder = t('picker_search_color');
  $('btnCloseSpritePicker').textContent = t('picker_close');
  $('btnCloseColorPicker').textContent = t('picker_close');
}

async function loadRefs() {
  const res = await postNui('getReferenceData', {});
  if (!res || !res.ok) return;

  REF.blips = res.blips || [];
  REF.colors = res.colors || [];
  REF.ready = !!res.ready;

  $('spriteHints').innerHTML = REF.blips
    .map(x => `<option value="${x.id}">${x.id} - ${escapeHtml(x.name || '')}</option>`)
    .join('');

  $('colorHints').innerHTML = REF.colors
    .map(x => `<option value="${x.id}">${x.id} - ${escapeHtml(x.name || '')}</option>`)
    .join('');

  setStatus(t('refs_loaded', { b: REF.blips.length, c: REF.colors.length }));
}

function escapeHtml(str) {
  return String(str ?? '')
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;')
    .replaceAll('"','&quot;')
    .replaceAll("'","&#039;");
}

function readForm() {
  return {
    id: state.selectedId,
    name: $('name').value.trim(),
    label: $('label').value.trim(),
    sprite: Number($('sprite').value || 1),
    color: Number($('color').value || 0),
    scale: Number($('scale').value || 0.9),
    display: Number($('display').value || 4),
    short_range: $('short_range').checked,
    enabled: $('enabled').checked,
    visibility: $('visibility').value,
    job: $('job').value.trim() || null,
    job_grade: $('job_grade').value === '' ? null : Number($('job_grade').value),
    x: Number($('x').value || 0),
    y: Number($('y').value || 0),
    z: Number($('z').value || 0),
  };
}

function writeForm(row) {
  state.selectedId = row ? row.id : null;

  $('name').value = row?.name ?? '';
  $('label').value = row?.label ?? '';
  $('sprite').value = row?.sprite ?? 1;
  $('color').value = row?.color ?? 0;
  $('scale').value = row?.scale ?? 0.9;
  $('display').value = row?.display ?? 4;
  $('short_range').checked = (row?.short_range == 1 || row?.short_range === true);
  $('enabled').checked = (row?.enabled == 1 || row?.enabled === true);
  $('visibility').value = row?.visibility ?? 'all';
  $('job').value = row?.job ?? '';
  $('job_grade').value = (row?.job_grade ?? '') === null ? '' : (row?.job_grade ?? '');

  $('x').value = row?.x ?? '';
  $('y').value = row?.y ?? '';
  $('z').value = row?.z ?? '';

  if (row) setStatus(t('status_selected', { id: row.id, name: row.name }));
  else setStatus(t('status_new_entry'));
}

function renderList() {
  const list = $('list');
  const q = $('search').value.trim().toLowerCase();

  const rows = state.rows
    .filter(r => {
      if (!q) return true;
      return String(r.id).includes(q) ||
        (r.name || '').toLowerCase().includes(q) ||
        (r.label || '').toLowerCase().includes(q);
    })
    .sort((a,b) => (a.id||0) - (b.id||0));

  list.innerHTML = rows.map(r => {
    const enabled = (r.enabled == 1);
    const vis = r.visibility || 'all';
    return `
      <div class="item" data-id="${r.id}">
        <div class="itemRow">
          <div class="itemLeft">
            <div><b>#${r.id}</b> ${escapeHtml(r.name)} <span class="badge">${enabled ? 'ENABLED' : 'DISABLED'}</span></div>
            <div>${escapeHtml(r.label)}</div>
            <div class="small">
              <span class="badge">sprite ${r.sprite}</span>
              <span class="badge">color ${r.color}</span>
              <span class="badge">scale ${r.scale}</span>
              <span class="badge">${vis}${vis !== 'all' ? `:${escapeHtml(r.job || '-')}${vis==='job_grade' ? `:${r.job_grade ?? '-'}` : ''}` : ''}</span>
            </div>
          </div>

          <div class="itemRight">
            <label class="switch" title="Toggle">
              <input type="checkbox" class="toggle" data-id="${r.id}" ${enabled ? 'checked' : ''}>
              <span class="slider"></span>
            </label>
          </div>
        </div>
      </div>
    `;
  }).join('');

  list.querySelectorAll('.item').forEach(el => {
    el.addEventListener('click', () => {
      const id = Number(el.getAttribute('data-id'));
      const row = state.rows.find(x => x.id === id);
      writeForm(row);
    });
  });

  list.querySelectorAll('.toggle').forEach(tg => {
    tg.addEventListener('click', (e) => e.stopPropagation());
    tg.addEventListener('change', async (e) => {
      const id = Number(e.target.getAttribute('data-id'));
      const enabled = e.target.checked;
      await postNui('toggle', { id, enabled });
      await refreshAdminList();
    });
  });
}

async function refreshAdminList() {
  const res = await postNui('adminGetAll', {});
  if (!res || !res.ok) {
    state.rows = [];
    renderList();
    setStatus(t('err_no_permission'));
    return;
  }
  state.rows = res.data || [];
  renderList();

  if (state.selectedId) {
    const row = state.rows.find(x => x.id === state.selectedId);
    if (row) writeForm(row);
  }
}

async function useMyPos() {
  const pos = await postNui('useMyPos', {});
  $('x').value = Number(pos.x).toFixed(3);
  $('y').value = Number(pos.y).toFixed(3);
  $('z').value = Number(pos.z).toFixed(3);
  setStatus(t('status_pos_taken'));
}

async function preview() {
  const data = readForm();
  await postNui('preview', data);
  setStatus(t('status_preview_set'));
}

async function createRow() {
  const data = readForm();
  const res = await postNui('create', data);
  if (!res || !res.ok) {
    setStatus(t('err_create_failed', { error: res?.error || 'unknown' }));
    return;
  }
  setStatus(t('status_created', { id: res.data.id }));
  await refreshAdminList();
  writeForm(res.data);
}

async function updateRow() {
  if (!state.selectedId) {
    setStatus(t('status_select_first'));
    return;
  }
  const data = readForm();
  const res = await postNui('update', data);
  if (!res || !res.ok) {
    setStatus(t('err_save_failed', { error: res?.error || 'unknown' }));
    return;
  }
  setStatus(t('status_saved', { id: res.data.id }));
  await refreshAdminList();
  writeForm(res.data);
}

async function deleteRow() {
  if (!state.selectedId) {
    setStatus(t('status_select_first'));
    return;
  }
  const id = state.selectedId;
  const res = await postNui('delete', { id });
  if (!res || !res.ok) {
    setStatus(t('err_delete_failed', { error: res?.error || 'unknown' }));
    return;
  }
  setStatus(t('status_deleted', { id }));
  state.selectedId = null;
  writeForm(null);
  await refreshAdminList();
}

async function toggleRow() {
  if (!state.selectedId) {
    setStatus(t('status_select_first'));
    return;
  }
  const current = state.rows.find(x => x.id === state.selectedId);
  if (!current) return;

  const enabled = !(current.enabled == 1);
  const res = await postNui('toggle', { id: current.id, enabled });
  if (!res || !res.ok) {
    setStatus(t('err_toggle_failed', { error: res?.error || 'unknown' }));
    return;
  }
  setStatus(t('status_toggle', { id: current.id, state: enabled ? 'ENABLED' : 'DISABLED' }));
  await refreshAdminList();
}

/* Picker helpers */
function show(id){ $(id).classList.remove('hidden'); }
function hide(id){ $(id).classList.add('hidden'); }

function openSpritePicker(){
  show('spritePicker');
  spritePage = 1;
  renderSpriteGrid(true);
  $('spriteSearch').focus();
}
function closeSpritePicker(){ hide('spritePicker'); }

function openColorPicker(){
  show('colorPicker');
  renderColorGrid();
  $('colorSearch').focus();
}
function closeColorPicker(){ hide('colorPicker'); }

function renderSpriteGrid(reset = false){
  const q = $('spriteSearch').value.trim().toLowerCase();
  const grid = $('spriteGrid');

  let items = REF.blips || [];
  if (q){
    items = items.filter(x =>
      String(x.id).includes(q) || (x.name||'').toLowerCase().includes(q)
    );
  }

  const total = items.length;
  const maxToShow = Math.min(total, spritePage * SPRITES_PER_PAGE);
  const visible = items.slice(0, maxToShow);

  // Render
  const html = visible.map(x => `
    <div class="tile" data-id="${x.id}">
      <div class="tileIcon">
        ${x.icon
          ? `<img src="${x.icon}" alt="${x.id}" loading="lazy" onerror="this.outerHTML='<div style=&quot;opacity:.6;font-size:12px;&quot;>#${x.id}</div>';">`
          : `<div style="opacity:.6;font-size:12px;">#${x.id}</div>`
        }
      </div>
      <div class="tileText">
        <div class="t1">#${x.id}</div>
        <div class="t2">${escapeHtml(x.name || '')}</div>
      </div>
    </div>
  `).join('');

  grid.innerHTML = html;

  // Click handlers
  grid.querySelectorAll('.tile').forEach(el => {
    el.addEventListener('click', () => {
      const id = Number(el.getAttribute('data-id'));
      $('sprite').value = String(id);
      closeSpritePicker();
      preview().catch(()=>{});
    });
  });

  // Footer info + Load more button
  $('spriteCount').textContent = `Showing ${maxToShow} / ${total}`;
  const moreBtn = $('btnMoreSprites');
  const hasMore = maxToShow < total;

  moreBtn.style.display = hasMore ? 'inline-flex' : 'none';
  moreBtn.onclick = () => {
    spritePage++;
    renderSpriteGrid(false);
  };
}

function renderColorGrid(){
  const q = $('colorSearch').value.trim().toLowerCase();
  const grid = $('colorGrid');

  let items = REF.colors || [];
  if (q){
    items = items.filter(x =>
      String(x.id).includes(q) || (x.name||'').toLowerCase().includes(q)
    );
  }

  grid.innerHTML = items.map(x => `
    <div class="tile" data-id="${x.id}">
      <div class="colorSwatch" style="background:${x.hex || 'rgba(255,255,255,0.25)'}"></div>
      <div class="tileText">
        <div class="t1">#${x.id}</div>
        <div class="t2">${escapeHtml(x.name || '')}</div>
      </div>
    </div>
  `).join('');

  grid.querySelectorAll('.tile').forEach(el => {
    el.addEventListener('click', () => {
      const id = Number(el.getAttribute('data-id'));
      $('color').value = String(id);
      closeColorPicker();
      preview().catch(()=>{});
    });
  });
}

/* Bind UI */
function bind() {
  if (didBind) return;
  didBind = true;

  $('btnClose').addEventListener('click', closeUi);
  $('search').addEventListener('input', renderList);

  $('btnUsePos').addEventListener('click', useMyPos);
  $('btnPreview').addEventListener('click', preview);

  $('btnCreate').addEventListener('click', createRow);
  $('btnUpdate').addEventListener('click', updateRow);
  $('btnDelete').addEventListener('click', deleteRow);
  $('btnToggle').addEventListener('click', toggleRow);

  $('btnPickSprite').addEventListener('click', openSpritePicker);
  $('btnPickColor').addEventListener('click', openColorPicker);
  $('btnCloseSpritePicker').addEventListener('click', closeSpritePicker);
  $('btnCloseColorPicker').addEventListener('click', closeColorPicker);
  $('spriteSearch').addEventListener('input', () => {
    spritePage = 1;
    renderSpriteGrid(true);
  });
  $('colorSearch').addEventListener('input', renderColorGrid);

  // Auto preview (debounced)
  let tt = null;
  const autoPreview = () => {
    clearTimeout(tt);
    tt = setTimeout(() => preview().catch(()=>{}), 140);
  };

  ['name','label','sprite','color','scale','display','short_range','enabled','visibility','job','job_grade','x','y','z'].forEach(id => {
    $(id).addEventListener('input', autoPreview);
    $(id).addEventListener('change', autoPreview);
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!$('spritePicker').classList.contains('hidden')) return closeSpritePicker();
      if (!$('colorPicker').classList.contains('hidden')) return closeColorPicker();
      return closeUi();
    }
  });
}

async function openUi() {
  $('app').classList.remove('hidden');
  bind();
  writeForm(null);

  await loadLocale();
  await loadRefs();
  await refreshAdminList();

  setStatus(t('status_opened'));
}

function closeUi() {
  $('app').classList.add('hidden');
  postNui('close', {}).catch(()=>{});
  setStatus('');
}

/* NUI messages */
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.action) return;
  if (data.action === 'open') openUi();
});