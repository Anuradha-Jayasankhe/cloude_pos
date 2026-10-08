/**
 * StoreBuddy Admin — Tutorials Page
 */
import { api } from '../api.js';
import { showToast, openModal, closeModal } from '../app.js';
import { escHtml } from '../utils.js';

export async function renderTutorials(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Tutorials Admin</h1>
        <p class="page-subtitle">Create and target tutorials for owners, staff, or everyone.</p>
      </div>
      <button class="btn btn-primary" id="btnNewTutorial" style="background-color: #5b21b6;">➕ New Tutorial</button>
    </div>

    <!-- Search box -->
    <div class="filters-bar" style="margin-bottom: 20px;">
      <div class="search-box" style="flex: 1; max-width: 100%; display: flex; gap: 8px;">
        <input type="text" id="tutorialSearch" placeholder="Search tutorials..." class="search-input" style="max-width: 100%;" />
        <button class="btn btn-primary" id="btnSearchTutorials" style="background-color: #5b21b6;">🔍 Search</button>
      </div>
    </div>

    <!-- Target Audience Filter pills -->
    <div class="filters-bar" style="margin-bottom: 24px;">
      <div class="filter-tabs" id="tutAudienceFilters">
        <button class="filter-tab active" data-audience="ALL">All Audiences</button>
        <button class="filter-tab" data-audience="All Users">All Users</button>
        <button class="filter-tab" data-audience="Owners">Owners</button>
        <button class="filter-tab" data-audience="Staff">Staff</button>
      </div>
    </div>

    <!-- Tutorials Grid Layout -->
    <div class="tutorials-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 24px;" id="tutorialsGridContainer">
      <div class="table-loading"><div class="loading-spinner"></div></div>
    </div>
  `;

  let tutorialsList = [];
  let activeAudienceFilter = 'ALL';

  document.getElementById('btnNewTutorial').addEventListener('click', () => showTutorialFormModal(null));
  document.getElementById('btnSearchTutorials').addEventListener('click', applyFiltersAndRender);
  document.getElementById('tutorialSearch').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') applyFiltersAndRender();
  });

  const filterTabs = document.getElementById('tutAudienceFilters').querySelectorAll('.filter-tab');
  filterTabs.forEach(tab => {
    tab.addEventListener('click', (e) => {
      filterTabs.forEach(t => t.classList.remove('active'));
      const target = e.currentTarget;
      target.classList.add('active');
      activeAudienceFilter = target.getAttribute('data-audience');
      applyFiltersAndRender();
    });
  });

  await loadTutorials();

  async function loadTutorials() {
    const grid = document.getElementById('tutorialsGridContainer');
    grid.innerHTML = '<div class="table-loading"><div class="loading-spinner"></div></div>';
    try {
      tutorialsList = await api.getTutorials();
      applyFiltersAndRender();
    } catch (e) {
      grid.innerHTML = `<div class="error-state">${escHtml(e.message)}</div>`;
    }
  }

  function applyFiltersAndRender() {
    const searchVal = document.getElementById('tutorialSearch').value.trim().toLowerCase();
    
    let filtered = tutorialsList;
    if (activeAudienceFilter !== 'ALL') {
      filtered = filtered.filter(t => t.audience === activeAudienceFilter);
    }
    if (searchVal) {
      filtered = filtered.filter(t => 
        t.title.toLowerCase().includes(searchVal) || 
        t.description.toLowerCase().includes(searchVal)
      );
    }

    renderGrid(filtered);
  }

  function renderGrid(tutorials) {
    const grid = document.getElementById('tutorialsGridContainer');
    if (!tutorials.length) {
      grid.innerHTML = '<div class="empty-state" style="grid-column: 1 / -1;"><div class="empty-icon">🎥</div><p>No video tutorials found</p></div>';
      return;
    }

    grid.innerHTML = tutorials.map(t => {
      // Use a custom video cover image or nice generic vector card
      const coverUrl = t.thumbnail_url || 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="300" height="180" viewBox="0 0 300 180"><rect width="300" height="180" rx="10" fill="%237c3aed" fill-opacity="0.1"/><path d="M120 60 L120 120 L170 90 Z" fill="%237c3aed"/></svg>';

      return `
        <div class="tutorial-card card" style="display: flex; flex-direction: column; gap: 14px; padding: 16px; position: relative;">
          
          <!-- Thumbnail cover matching Screenshot 4 -->
          <div class="tutorial-cover" style="position: relative; width: 100%; height: 160px; border-radius: var(--radius); overflow: hidden; background: #0f172a; border: 1px solid var(--border);">
            <img src="${coverUrl}" style="width: 100%; height: 100%; object-fit: cover;" alt="cover" />
            <div style="position: absolute; inset: 0; background: rgba(0,0,0,0.15); display: flex; align-items: center; justify-content: center;">
              <div style="width: 48px; height: 48px; border-radius: 50%; background: white; display: flex; align-items: center; justify-content: center; box-shadow: var(--shadow-lg); cursor: pointer; transition: transform 0.2s;" class="play-btn" data-video="${escHtml(t.video_url)}">
                <span style="color: #7c3aed; font-size: 20px; margin-left: 4px;">▶</span>
              </div>
            </div>
          </div>

          <!-- Info -->
          <div style="flex: 1; display: flex; flex-direction: column; gap: 8px;">
            <div style="display: flex; gap: 6px; flex-wrap: wrap;">
              <span class="badge badge-primary" style="font-size: 10px; padding: 2px 8px;">${escHtml(t.audience)}</span>
              <span class="badge ${t.status === 'PUBLISHED' ? 'badge-success' : 'badge-warning'}" style="font-size: 10px; padding: 2px 8px;">${escHtml(t.status)}</span>
            </div>
            <h3 style="font-size: 16px; font-weight: 700; color: var(--text); line-height: 1.3;">${escHtml(t.title)}</h3>
            <p style="font-size: 13px; color: var(--text-muted); line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; text-overflow: ellipsis;">
              ${escHtml(t.description)}
            </p>
          </div>

          <!-- Actions Footer matching Screenshot 4 -->
          <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-light); padding-top: 12px; margin-top: auto;">
            <button class="btn btn-primary btn-sm watch-btn" data-video="${escHtml(t.video_url)}" style="background-color: #5b21b6; padding: 6px 16px;">▶ Watch</button>
            <div style="display: flex; gap: 4px;">
              <button class="btn btn-ghost btn-sm edit-btn" data-id="${t.id}" style="padding: 4px 8px;">✏️</button>
              <button class="btn btn-ghost btn-sm toggle-btn" data-id="${t.id}" data-status="${t.status}" style="padding: 4px 8px;">${t.status === 'PUBLISHED' ? '👁️' : '👁️‍🗨️'}</button>
              <button class="btn btn-ghost btn-sm text-danger delete-btn" data-id="${t.id}" style="padding: 4px 8px;">🗑️</button>
            </div>
          </div>

        </div>
      `;
    }).join('');

    // Bind item actions
    grid.querySelectorAll('.play-btn, .watch-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const url = e.currentTarget.getAttribute('data-video');
        playVideoModal(url);
      });
    });

    grid.querySelectorAll('.edit-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.currentTarget.getAttribute('data-id');
        const tut = tutorialsList.find(t => t.id === id);
        showTutorialFormModal(tut);
      });
    });

    grid.querySelectorAll('.toggle-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const id = e.currentTarget.getAttribute('data-id');
        const status = e.currentTarget.getAttribute('data-status');
        const nextStatus = status === 'PUBLISHED' ? 'DRAFT' : 'PUBLISHED';
        try {
          const updated = await api.updateTutorial(id, { status: nextStatus });
          showToast(`Tutorial status updated to ${nextStatus}!`, 'success');
          tutorialsList = tutorialsList.map(t => t.id === id ? updated : t);
          applyFiltersAndRender();
        } catch (err) {
          showToast(err.message, 'error');
        }
      });
    });

    grid.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const id = e.currentTarget.getAttribute('data-id');
        const tut = tutorialsList.find(t => t.id === id);
        if (!confirm(`Are you sure you want to delete tutorial "${tut.title}"?`)) return;
        try {
          await api.deleteTutorial(id);
          showToast('Tutorial deleted successfully!', 'success');
          tutorialsList = tutorialsList.filter(t => t.id !== id);
          applyFiltersAndRender();
        } catch (err) {
          showToast(err.message, 'error');
        }
      });
    });
  }

  function playVideoModal(videoUrl) {
    if (!videoUrl) {
      showToast('Video URL not configured for this tutorial', 'warning');
      return;
    }
    // Convert watch link to embed link if needed
    let embedUrl = videoUrl;
    if (videoUrl.includes('youtube.com/watch?v=')) {
      const vid = videoUrl.split('v=')[1]?.split('&')[0];
      embedUrl = `https://www.youtube.com/embed/${vid}`;
    }
    const bodyHtml = `
      <div style="position: relative; width: 100%; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px;">
        <iframe src="${embedUrl}" style="position: absolute; top:0; left:0; width:100%; height:100%;" frameborder="0" allowfullscreen></iframe>
      </div>
    `;
    openModal('Watch Tutorial', bodyHtml, () => {
      closeModal();
    });
  }

  function showTutorialFormModal(tut = null) {
    const isEdit = !!tut;
    const bodyHtml = `
      <form class="form-grid" id="tutorialForm">
        <div class="form-group">
          <label>Tutorial Title *</label>
          <input type="text" name="title" class="form-control" placeholder="e.g. Printer setup" value="${tut ? escHtml(tut.title) : ''}" required />
        </div>
        <div class="form-group">
          <label>Audience Target</label>
          <select name="audience" class="form-control">
            <option value="All Users" ${tut && tut.audience === 'All Users' ? 'selected' : ''}>All Users</option>
            <option value="Owners" ${tut && tut.audience === 'Owners' ? 'selected' : ''}>Owners</option>
            <option value="Staff" ${tut && tut.audience === 'Staff' ? 'selected' : ''}>Staff</option>
          </select>
        </div>
        <div class="form-group">
          <label>Video URL / Embed Link *</label>
          <input type="url" name="videoUrl" class="form-control" placeholder="e.g. https://www.youtube.com/embed/..." value="${tut ? escHtml(tut.video_url) : 'https://www.youtube.com/embed/dQw4w9WgXcQ'}" required />
        </div>
        <div class="form-group">
          <label>Thumbnail / Cover Image URL</label>
          <input type="text" name="thumbnailUrl" class="form-control" placeholder="Optional image web link" value="${tut ? escHtml(tut.thumbnail_url) : ''}" />
        </div>
        <div class="form-group">
          <label>Description *</label>
          <textarea name="description" class="form-control" style="height: 100px;" placeholder="Brief summary of the video content..." required>${tut ? escHtml(tut.description) : ''}</textarea>
        </div>
        <div class="form-group">
          <label class="checkbox-label">
            <input type="checkbox" name="isPublished" ${!tut || tut.status === 'PUBLISHED' ? 'checked' : ''} />
            Publish instantly
          </label>
        </div>
      </form>
    `;

    openModal(isEdit ? 'Edit Tutorial' : 'New Tutorial', bodyHtml, async () => {
      const form = document.getElementById('tutorialForm');
      if (!form.reportValidity()) return false;

      const fd = new FormData(form);
      const payload = {
        title: fd.get('title').trim(),
        audience: fd.get('audience'),
        video_url: fd.get('videoUrl').trim(),
        thumbnail_url: fd.get('thumbnailUrl').trim(),
        description: fd.get('description'),
        status: form.elements.isPublished.checked ? 'PUBLISHED' : 'DRAFT',
      };

      try {
        let result;
        if (isEdit) {
          result = await api.updateTutorial(tut.id, payload);
          showToast('Tutorial updated successfully!', 'success');
          tutorialsList = tutorialsList.map(t => t.id === tut.id ? result : t);
        } else {
          result = await api.createTutorial(payload);
          showToast('Tutorial created successfully!', 'success');
          tutorialsList.unshift(result);
        }

        applyFiltersAndRender();
        closeModal();
      } catch (err) {
        showToast(err.message, 'error');
        return false;
      }
    });
  }
}
