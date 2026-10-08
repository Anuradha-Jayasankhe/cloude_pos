/**
 * StoreBuddy Admin — Documentation Studio Page
 */
import { api } from '../api.js';
import { showToast, openModal, closeModal } from '../app.js';
import { escHtml } from '../utils.js';

export async function renderDocs(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Documentation Studio</h1>
        <p class="page-subtitle">Build structured guides with markdown, linked topics, and inline media for every customer-facing workflow.</p>
      </div>
      <button class="btn btn-primary" id="btnNewDoc" style="background-color: #5b21b6;">➕ New Document</button>
    </div>

    <!-- Stats summary matching Screenshot 3 -->
    <div class="stats-grid" style="grid-template-columns: repeat(3, 1fr); margin-bottom: 24px;">
      <div class="stat-card" style="padding: 16px;">
        <div class="stat-icon stat-icon--purple" style="font-size: 18px; width: 36px; height: 36px;">📄</div>
        <div>
          <div class="stat-value" id="statsDocsCount" style="font-size: 20px;">0</div>
          <div class="stat-label" style="font-size: 11px;">Docs</div>
        </div>
      </div>
      <div class="stat-card" style="padding: 16px;">
        <div class="stat-icon stat-icon--blue" style="font-size: 18px; width: 36px; height: 36px;">📂</div>
        <div>
          <div class="stat-value" id="statsSectionsCount" style="font-size: 20px;">0</div>
          <div class="stat-label" style="font-size: 11px;">Sections</div>
        </div>
      </div>
      <div class="stat-card" style="padding: 16px;">
        <div class="stat-icon stat-icon--orange" style="font-size: 18px; width: 36px; height: 36px;">📝</div>
        <div>
          <div class="stat-value" id="statsDraftsCount" style="font-size: 20px;">0</div>
          <div class="stat-label" style="font-size: 11px;">Drafts</div>
        </div>
      </div>
    </div>

    <!-- Search box -->
    <div class="filters-bar" style="margin-bottom: 20px;">
      <div class="search-box" style="max-width: 100%;">
        <span class="search-icon">🔍</span>
        <input type="text" id="docSearch" placeholder="Search titles, markdown content, summaries, and drafts..." class="search-input" />
      </div>
    </div>

    <!-- Sections filter pills -->
    <div style="display: flex; gap: 8px; margin-bottom: 20px;" id="docSectionFilters">
      <span class="badge" style="background-color: #ede9fe; color: #5b21b6; border-color: #c4b5fd; cursor: pointer; padding: 6px 14px; font-weight: 500;" data-section="ALL">All sections</span>
    </div>

    <!-- Dual Pane Content Layout -->
    <div class="doc-studio-layout" style="display: grid; grid-template-columns: 340px 1fr; gap: 24px; min-height: 500px; height: calc(100vh - 360px);">
      
      <!-- Left Panel: Topics Navigation -->
      <div class="card doc-left-pane" style="padding: 16px; display: flex; flex-direction: column; overflow-y: auto;">
        <div id="topicsContainer" style="display: flex; flex-direction: column; gap: 16px;"></div>
      </div>

      <!-- Right Panel: Document Viewer -->
      <div class="card doc-right-pane" style="padding: 24px; overflow-y: auto; position: relative;" id="docViewerPane">
        <div class="empty-state" style="padding: 100px 20px;">
          <div class="empty-icon">📄</div>
          <p>Select a document from the left pane to view or edit</p>
        </div>
      </div>

    </div>
  `;

  let docsList = [];
  let selectedDoc = null;
  let activeSectionFilter = 'ALL';

  document.getElementById('btnNewDoc').addEventListener('click', () => showDocFormModal(null));
  document.getElementById('docSearch').addEventListener('input', applyFiltersAndRender);

  await loadDocs();

  async function loadDocs() {
    try {
      docsList = await api.getDocs();
      updateStatsAndFilters();
      applyFiltersAndRender();
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  function updateStatsAndFilters() {
    // Counts
    const docsCount = docsList.length;
    const sections = new Set(docsList.map(d => d.section));
    const draftsCount = docsList.filter(d => d.status === 'DRAFT').length;

    document.getElementById('statsDocsCount').textContent = docsCount;
    document.getElementById('statsSectionsCount').textContent = sections.size;
    document.getElementById('statsDraftsCount').textContent = draftsCount;

    // Render section filters
    const filtersBar = document.getElementById('docSectionFilters');
    filtersBar.innerHTML = `
      <span class="badge ${activeSectionFilter === 'ALL' ? 'badge-primary' : 'badge-secondary'}" style="cursor: pointer; padding: 6px 14px;" data-section="ALL">All sections</span>
      ${Array.from(sections).map(sec => `
        <span class="badge ${activeSectionFilter === sec ? 'badge-primary' : 'badge-secondary'}" style="cursor: pointer; padding: 6px 14px;" data-section="${escHtml(sec)}">${escHtml(sec)} (${docsList.filter(d => d.section === sec).length})</span>
      `).join('')}
    `;

    // Filter clicks
    filtersBar.querySelectorAll('.badge').forEach(el => {
      el.addEventListener('click', (e) => {
        activeSectionFilter = e.currentTarget.getAttribute('data-section');
        updateStatsAndFilters();
        applyFiltersAndRender();
      });
    });
  }

  function applyFiltersAndRender() {
    const searchVal = document.getElementById('docSearch').value.trim().toLowerCase();
    
    // Filter
    let filtered = docsList;
    if (activeSectionFilter !== 'ALL') {
      filtered = filtered.filter(d => d.section === activeSectionFilter);
    }
    if (searchVal) {
      filtered = filtered.filter(d => 
        d.title.toLowerCase().includes(searchVal) || 
        d.content.toLowerCase().includes(searchVal) ||
        d.section.toLowerCase().includes(searchVal)
      );
    }

    renderLeftPane(filtered);
  }

  function renderLeftPane(filteredDocs) {
    const container = document.getElementById('topicsContainer');
    container.innerHTML = '';

    // Group by section
    const grouped = {};
    filteredDocs.forEach(d => {
      if (!grouped[d.section]) grouped[d.section] = [];
      grouped[d.section].push(d);
    });

    if (Object.keys(grouped).length === 0) {
      container.innerHTML = '<div class="empty-state" style="padding: 40px 0;"><p>No documents match your filter</p></div>';
      return;
    }

    Object.entries(grouped).forEach(([section, items]) => {
      const sectionHeader = document.createElement('div');
      sectionHeader.className = 'doc-section-group';
      sectionHeader.innerHTML = `
        <div style="display: flex; align-items: center; gap: 8px; font-weight: 700; font-size: 13px; color: var(--text-muted); margin-bottom: 8px; text-transform: uppercase;">
          <span>📂</span>
          <span>${escHtml(section)}</span>
        </div>
        <div style="display: flex; flex-direction: column; gap: 4px; padding-left: 12px;" class="doc-section-items">
        </div>
      `;

      const itemsContainer = sectionHeader.querySelector('.doc-section-items');
      items.forEach(doc => {
        const itemEl = document.createElement('div');
        itemEl.className = `doc-nav-item ${selectedDoc && selectedDoc.id === doc.id ? 'active' : ''}`;
        itemEl.style.cssText = `
          padding: 10px 12px;
          border-radius: var(--radius);
          font-size: 13px;
          font-weight: 500;
          color: var(--text-muted);
          cursor: pointer;
          transition: background var(--transition), color var(--transition);
          background: ${selectedDoc && selectedDoc.id === doc.id ? '#ede9fe' : 'transparent'};
          color: ${selectedDoc && selectedDoc.id === doc.id ? '#5b21b6' : 'inherit'};
          border: 1px solid ${selectedDoc && selectedDoc.id === doc.id ? '#c4b5fd' : 'transparent'};
        `;
        itemEl.innerHTML = `
          <div style="font-weight: 600; margin-bottom: 2px;">${escHtml(doc.title)}</div>
          <div style="font-size: 11px; color: var(--text-light); display: flex; justify-content: space-between;">
            <span>${escHtml(doc.section)}</span>
            <span>${escHtml(doc.status)}</span>
          </div>
        `;

        itemEl.addEventListener('click', () => {
          selectedDoc = doc;
          // Re-render nav highlight
          renderLeftPane(filteredDocs);
          renderRightPane(doc);
        });

        itemsContainer.appendChild(itemEl);
      });

      container.appendChild(sectionHeader);
    });
  }

  function renderRightPane(doc) {
    const pane = document.getElementById('docViewerPane');
    if (!doc) {
      pane.innerHTML = `
        <div class="empty-state" style="padding: 100px 20px;">
          <div class="empty-icon">📄</div>
          <p>Select a document from the left pane to view or edit</p>
        </div>
      `;
      return;
    }

    // Convert markdown headings/bullets to simple HTML for preview
    let htmlContent = escHtml(doc.content)
      .replace(/\n/g, '<br/>')
      .replace(/^### (.*)$/gm, '<h3 style="font-size: 18px; font-weight: 700; margin: 16px 0 8px; color: var(--text);">$1</h3>')
      .replace(/^## (.*)$/gm, '<h2 style="font-size: 20px; font-weight: 700; margin: 20px 0 10px; color: var(--text);">$1</h2>')
      .replace(/^# (.*)$/gm, '<h1 style="font-size: 24px; font-weight: 800; margin: 24px 0 12px; color: var(--text);">$1</h1>')
      .replace(/^\* (.*)$/gm, '<li style="margin-left: 16px; margin-bottom: 4px;">$1</li>')
      .replace(/^\d+\. (.*)$/gm, '<li style="margin-left: 16px; margin-bottom: 4px; list-style-type: decimal;">$1</li>');

    pane.innerHTML = `
      <div class="doc-viewer-header" style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; border-bottom: 1px solid var(--border); padding-bottom: 16px;">
        <div style="flex: 1; min-width: 0;">
          <div style="font-size: 12px; font-weight: 600; color: var(--text-muted); margin-bottom: 4px;">${escHtml(doc.section)}</div>
          <h2 style="font-size: 24px; font-weight: 800; color: var(--text); margin-bottom: 8px; line-height: 1.2;">${escHtml(doc.title)}</h2>
          <div style="display: flex; gap: 8px; flex-wrap: wrap;">
            <span class="badge badge-secondary">${escHtml(doc.section)}</span>
            ${doc.roles && doc.roles.length ? doc.roles.map(r => `<span class="badge badge-primary">${escHtml(r)}</span>`).join('') : ''}
            <span class="badge" style="background-color: #f3f4f6; color: #4b5563;">Updated ${new Date(doc.updated_at || doc.created_at).toLocaleDateString()}</span>
            <span class="badge ${doc.status === 'PUBLISHED' ? 'badge-success' : 'badge-warning'}">${escHtml(doc.status)}</span>
          </div>
        </div>
        <div style="display: flex; gap: 8px; flex-shrink: 0; margin-left: 16px;">
          <button class="btn btn-ghost btn-sm" id="btnEditDoc" style="border-color: #c4b5fd; color: #5b21b6;">✏️ Edit</button>
          <button class="btn btn-ghost btn-sm" id="btnUnpublishDoc" style="border-color: #fca5a5; color: #ef4444;">🚫 ${doc.status === 'PUBLISHED' ? 'Unpublish' : 'Publish'}</button>
          <button class="btn btn-ghost btn-sm text-danger" id="btnDeleteDoc" style="border-color: #fee2e2;">🗑️ Delete</button>
        </div>
      </div>

      <!-- Document Content Body -->
      <div class="doc-viewer-body" style="font-size: 15px; color: #374151; line-height: 1.7; margin-bottom: 24px;">
        ${htmlContent}
      </div>

      <!-- Image placeholder matching Screenshot 3 -->
      <div class="doc-viewer-image-placeholder" style="background: #f9fafb; border: 1px dashed #d1d5db; border-radius: var(--radius); padding: 32px; text-align: center; color: var(--text-light); font-size: 13px;">
        🖼️ Cover image unavailable
      </div>
    `;

    // Bind action hooks
    document.getElementById('btnEditDoc').addEventListener('click', () => showDocFormModal(doc));
    document.getElementById('btnUnpublishDoc').addEventListener('click', () => togglePublishDoc(doc));
    document.getElementById('btnDeleteDoc').addEventListener('click', () => deleteDoc(doc));
  }

  async function togglePublishDoc(doc) {
    const nextStatus = doc.status === 'PUBLISHED' ? 'DRAFT' : 'PUBLISHED';
    try {
      const updated = await api.updateDoc(doc.id, { status: nextStatus });
      showToast(`Document ${nextStatus === 'PUBLISHED' ? 'published' : 'unpublished'} successfully!`, 'success');
      docsList = docsList.map(d => d.id === doc.id ? updated : d);
      selectedDoc = updated;
      updateStatsAndFilters();
      applyFiltersAndRender();
      renderRightPane(updated);
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  async function deleteDoc(doc) {
    if (!confirm(`Are you sure you want to delete "${doc.title}"?`)) return;
    try {
      await api.deleteDoc(doc.id);
      showToast('Document deleted successfully!', 'success');
      docsList = docsList.filter(d => d.id !== doc.id);
      selectedDoc = null;
      updateStatsAndFilters();
      applyFiltersAndRender();
      renderRightPane(null);
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  function showDocFormModal(doc = null) {
    const isEdit = !!doc;
    const bodyHtml = `
      <form class="form-grid" id="docForm">
        <div class="form-group">
          <label>Document Title *</label>
          <input type="text" name="title" class="form-control" placeholder="e.g. StoreBuddy: How to Create a Sale" value="${doc ? escHtml(doc.title) : ''}" required />
        </div>
        <div class="form-group">
          <label>Section / Folder *</label>
          <input type="text" name="section" class="form-control" placeholder="e.g. Getting Started" value="${doc ? escHtml(doc.section) : 'Getting Started'}" required />
        </div>
        <div class="form-group">
          <label>Audience</label>
          <select name="audience" class="form-control">
            <option value="All Users" ${doc && doc.audience === 'All Users' ? 'selected' : ''}>All Users</option>
            <option value="Owners" ${doc && doc.audience === 'Owners' ? 'selected' : ''}>Owners</option>
            <option value="Staff" ${doc && doc.audience === 'Staff' ? 'selected' : ''}>Staff</option>
          </select>
        </div>
        <div class="form-group">
          <label>Roles (comma separated)</label>
          <input type="text" name="roles" class="form-control" placeholder="e.g. role-restricted, admin-only" value="${doc && doc.roles ? escHtml(doc.roles.join(', ')) : ''}" />
        </div>
        <div class="form-group">
          <label>Document Content (Markdown) *</label>
          <textarea name="content" class="form-control" style="height: 180px;" placeholder="Use Markdown syntax: # Heading, * Bullets, etc." required>${doc ? escHtml(doc.content) : ''}</textarea>
        </div>
        <div class="form-group">
          <label class="checkbox-label">
            <input type="checkbox" name="isPublished" ${!doc || doc.status === 'PUBLISHED' ? 'checked' : ''} />
            Publish instantly
          </label>
        </div>
      </form>
    `;

    openModal(isEdit ? 'Edit Document' : 'New Document', bodyHtml, async () => {
      const form = document.getElementById('docForm');
      if (!form.reportValidity()) return false;

      const fd = new FormData(form);
      const rolesStr = fd.get('roles').trim();
      const payload = {
        title: fd.get('title').trim(),
        section: fd.get('section').trim(),
        audience: fd.get('audience'),
        roles: rolesStr ? rolesStr.split(',').map(s => s.trim()).filter(Boolean) : [],
        content: fd.get('content'),
        status: form.elements.isPublished.checked ? 'PUBLISHED' : 'DRAFT',
      };

      try {
        let result;
        if (isEdit) {
          result = await api.updateDoc(doc.id, payload);
          showToast('Document updated successfully!', 'success');
          docsList = docsList.map(d => d.id === doc.id ? result : d);
        } else {
          result = await api.createDoc(payload);
          showToast('Document created successfully!', 'success');
          docsList.unshift(result);
        }

        selectedDoc = result;
        updateStatsAndFilters();
        applyFiltersAndRender();
        renderRightPane(result);
        closeModal();
      } catch (e) {
        showToast(e.message, 'error');
        return false;
      }
    });
  }
}
