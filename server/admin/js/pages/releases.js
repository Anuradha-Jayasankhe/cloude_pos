/**
 * StoreBuddy Admin — Releases Page
 */
import { api } from '../api.js';
import { showToast, openModal, closeModal } from '../app.js';
import { formatDate, escHtml, copyToClipboard } from '../utils.js';

export async function renderReleases(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Releases</h1>
        <p class="page-subtitle">Manage platform software releases and download links</p>
      </div>
      <button class="btn btn-primary" id="btnNewRelease">+ New Release</button>
    </div>
    <div class="filters-bar">
      <div class="filter-tabs" id="platformFilter">
        <button class="filter-tab active" data-platform="">All</button>
        <button class="filter-tab" data-platform="windows">🪟 Windows</button>
        <button class="filter-tab" data-platform="mac">🍎 Mac</button>
        <button class="filter-tab" data-platform="linux">🐧 Linux</button>
        <button class="filter-tab" data-platform="android">🤖 Android</button>
      </div>
    </div>
    <div class="card">
      <div id="releasesTableContainer"><div class="table-loading"><div class="loading-spinner"></div></div></div>
    </div>
  `;

  let currentPlatform = '';

  document.getElementById('btnNewRelease').addEventListener('click', () => showReleaseModal(null, loadReleases));
  document.getElementById('platformFilter').addEventListener('click', e => {
    const tab = e.target.closest('[data-platform]');
    if (!tab) return;
    document.querySelectorAll('.filter-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    currentPlatform = tab.dataset.platform;
    loadReleases();
  });

  await loadReleases();

  async function loadReleases() {
    const el = document.getElementById('releasesTableContainer');
    el.innerHTML = '<div class="table-loading"><div class="loading-spinner"></div></div>';
    try {
      const params = {};
      if (currentPlatform) params.platform = currentPlatform;
      const releases = await api.getReleases(params);
      renderTable(el, releases);
    } catch (e) {
      el.innerHTML = `<div class="error-state">${escHtml(e.message)}</div>`;
    }
  }

  function renderTable(el, releases) {
    if (!releases.length) {
      el.innerHTML = '<div class="empty-state"><div class="empty-icon">🚀</div><p>No releases yet</p></div>';
      return;
    }

    const platformIcons = { windows: '🪟', mac: '🍎', linux: '🐧', android: '🤖', ios: '📱' };
    const channelColors = { stable: '#10b981', beta: '#f59e0b', alpha: '#ef4444' };

    el.innerHTML = `
      <div class="table-responsive">
        <table class="table">
          <thead>
            <tr><th>Version</th><th>Platform</th><th>Channel</th><th>Release Date</th><th>Status</th><th>Actions</th></tr>
          </thead>
          <tbody>
            ${releases.map(r => `
              <tr>
                <td class="fw-600">v${escHtml(r.version)}</td>
                <td>
                  <span class="platform-badge">
                    ${platformIcons[r.platform] || '💻'} ${escHtml(r.platform)}
                  </span>
                </td>
                <td>
                  <span class="badge" style="background:${channelColors[r.channel] || '#6b7280'}20;color:${channelColors[r.channel] || '#6b7280'};border:1px solid ${channelColors[r.channel] || '#6b7280'}40">
                    ${escHtml(r.channel)}
                  </span>
                </td>
                <td class="text-muted">${formatDate(r.release_date)}</td>
                <td>
                  <button class="btn btn-sm ${r.published ? 'btn-success' : 'btn-ghost'}" onclick="window.sbTogglePublish('${r.id}', ${r.published})">
                    ${r.published ? '✅ Published' : '⬜ Draft'}
                  </button>
                </td>
                <td>
                  <div class="action-group">
                    ${r.download_url ? `<button class="btn btn-sm btn-ghost" onclick="window.sbCopyDlUrl('${escHtml(r.download_url)}')">📋 URL</button>` : ''}
                    <button class="btn btn-sm btn-ghost" onclick="window.sbEditRelease('${r.id}')">✏️</button>
                    <button class="btn btn-sm btn-ghost text-danger" onclick="window.sbDeleteRelease('${r.id}', 'v${escHtml(r.version)}')">🗑</button>
                  </div>
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;

    window.sbTogglePublish = async (id, currentPublished) => {
      try {
        await api.updateRelease(id, { published: !currentPublished });
        showToast(currentPublished ? 'Unpublished' : 'Published!', 'success');
        loadReleases();
      } catch (e) { showToast(e.message, 'error'); }
    };
    window.sbCopyDlUrl = (url) => { copyToClipboard(url); showToast('URL copied!', 'success'); };
    window.sbEditRelease = (id) => {
      const r = releases.find(r => r.id === id);
      if (r) showReleaseModal(r, loadReleases);
    };
    window.sbDeleteRelease = async (id, label) => {
      if (!confirm(`Delete release ${label}?`)) return;
      try {
        await api.deleteRelease(id);
        showToast('Release deleted', 'success');
        loadReleases();
      } catch (e) { showToast(e.message, 'error'); }
    };
  }
}

function showReleaseModal(release, onDone) {
  const v = (field, def = '') => release ? (release[field] ?? def) : def;
  const dateVal = v('release_date') ? new Date(v('release_date')).toISOString().slice(0, 10) : new Date().toISOString().slice(0, 10);

  openModal(release ? 'Edit Release' : 'New Release', `
    <form id="releaseForm" class="form-grid">
      <div class="form-group">
        <label>Version *</label>
        <input type="text" name="version" class="form-control" value="${escHtml(v('version'))}" required placeholder="1.2.3" />
      </div>
      <div class="form-group">
        <label>Platform *</label>
        <select name="platform" class="form-control" ${release ? 'disabled' : ''}>
          <option value="windows" ${v('platform') === 'windows' ? 'selected' : ''}>🪟 Windows</option>
          <option value="mac" ${v('platform') === 'mac' ? 'selected' : ''}>🍎 Mac</option>
          <option value="linux" ${v('platform') === 'linux' ? 'selected' : ''}>🐧 Linux</option>
          <option value="android" ${v('platform') === 'android' ? 'selected' : ''}>🤖 Android</option>
          <option value="ios" ${v('platform') === 'ios' ? 'selected' : ''}>📱 iOS</option>
        </select>
      </div>
      <div class="form-group">
        <label>Channel</label>
        <select name="channel" class="form-control">
          <option value="stable" ${v('channel', 'stable') === 'stable' ? 'selected' : ''}>Stable</option>
          <option value="beta" ${v('channel') === 'beta' ? 'selected' : ''}>Beta</option>
          <option value="alpha" ${v('channel') === 'alpha' ? 'selected' : ''}>Alpha</option>
        </select>
      </div>
      <div class="form-group">
        <label>Release Date</label>
        <input type="date" name="release_date" class="form-control" value="${dateVal}" />
      </div>
      <div class="form-group form-group-full">
        <label>Download URL</label>
        <input type="url" name="download_url" class="form-control" value="${escHtml(v('download_url'))}" placeholder="https://releases.storebuddy.com/v1.2.3/StorebuddySetup.exe" />
      </div>
      <div class="form-group form-group-full">
        <label>Release Notes</label>
        <textarea name="release_notes" class="form-control" rows="5" placeholder="- Fixed commission calculation bug&#10;- Improved sync performance">${escHtml(v('release_notes'))}</textarea>
      </div>
      <div class="form-group">
        <label class="checkbox-label">
          <input type="checkbox" name="published" ${v('published') ? 'checked' : ''} />
          Publish immediately
        </label>
      </div>
    </form>
  `, async () => {
    const form = document.getElementById('releaseForm');
    const fd = new FormData(form);
    const data = Object.fromEntries(fd);
    data.published = form.querySelector('[name=published]').checked;
    if (release && !data.platform) data.platform = release.platform; // restore disabled field

    try {
      if (release) {
        await api.updateRelease(release.id, data);
        showToast('Release updated!', 'success');
      } else {
        await api.createRelease(data);
        showToast('Release created!', 'success');
      }
      closeModal();
      onDone();
    } catch (e) { showToast(e.message, 'error'); }
  });
}
