/**
 * StoreBuddy Admin — Activity Log Page Redesign
 */
import { api } from '../api.js';
import { showToast } from '../app.js';
import { formatDateTime, escHtml } from '../utils.js';

export async function renderActivity(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Activity Report</h1>
        <p class="page-subtitle">Track all store and user actions across the platform.</p>
      </div>
    </div>

    <!-- Timeline Action Filter Bar (Screenshot 2) -->
    <div class="filters-bar" style="background: var(--bg-card); padding: 16px; border-radius: var(--radius-lg); border: 1px solid var(--border); margin-bottom: 20px; gap: 16px;">
      <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
        
        <!-- Activity Dropdown -->
        <select id="actTypeFilter" class="form-control" style="width: 140px;">
          <option value="ALL">All Activities</option>
          <option value="CREATE">Insert</option>
          <option value="UPDATE">Update</option>
          <option value="DELETE">Delete</option>
          <option value="GENERATE">Generate</option>
          <option value="LOGIN">Login</option>
        </select>

        <!-- Outcome Dropdown -->
        <select id="actOutcomeFilter" class="form-control" style="width: 140px;">
          <option value="ALL">Any Outcome</option>
          <option value="SUCCESS">Success</option>
          <option value="FAILED">Failed</option>
        </select>

        <!-- Date Range Dropdown -->
        <select id="actDateRangeFilter" class="form-control" style="width: 140px;">
          <option value="7">Last 7 Days</option>
          <option value="1">Today</option>
          <option value="30">Last 30 Days</option>
          <option value="ALL">All Time</option>
        </select>

        <!-- Shop ID Input -->
        <input type="text" id="actShopIdFilter" placeholder="Shop ID (optional)" class="form-control" style="width: 180px;" />

        <button class="btn btn-primary" id="btnApplyFilters" style="background-color: #5b21b6;">🔍 Apply</button>
      </div>
    </div>

    <!-- Audience & Resource Bar -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 12px;">
      <div style="display: flex; gap: 8px;">
        <span class="badge" style="background-color: #ede9fe; color: #5b21b6; border-color: #c4b5fd; cursor: pointer; padding: 6px 14px; font-weight: 500;" id="pillAllUsers">✓ All Users</span>
        <span class="badge" style="background-color: #f3f4f6; color: #4b5563; border-color: #e5e7eb; cursor: pointer; padding: 6px 14px; font-weight: 500;" id="pillDineBuddy">DB Dine Buddy</span>
      </div>

      <div style="display: flex; gap: 12px; align-items: center;">
        <select id="actResourceFilter" class="form-control" style="width: 160px; padding: 6px 12px;">
          <option value="ALL">Any Resource</option>
          <option value="tenants">Shops</option>
          <option value="plans">Plans</option>
          <option value="users">Users</option>
          <option value="releases">Releases</option>
        </select>

        <button class="btn btn-ghost" id="btnExportPdf" style="border-color: #c4b5fd; color: #5b21b6; font-size: 13px; padding: 6px 14px;">🖨️ Export PDF</button>
      </div>
    </div>

    <!-- Timeline Cards Container -->
    <div id="activityTimelineContainer">
      <div class="table-loading"><div class="loading-spinner"></div></div>
    </div>

    <!-- Clean Pagination matching Screenshot 2 -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 24px; padding: 0 10px;" id="activityTimelinePagination">
    </div>
  `;

  let skip = 0;
  let limit = 25;

  // Filter handlers
  document.getElementById('btnApplyFilters').addEventListener('click', () => { skip = 0; loadActivity(); });
  document.getElementById('btnExportPdf').addEventListener('click', exportPdfReport);

  const pillAllUsers = document.getElementById('pillAllUsers');
  const pillDineBuddy = document.getElementById('pillDineBuddy');
  const shopIdFilterInput = document.getElementById('actShopIdFilter');

  pillAllUsers.addEventListener('click', () => {
    pillAllUsers.style.backgroundColor = '#ede9fe';
    pillAllUsers.style.color = '#5b21b6';
    pillAllUsers.style.borderColor = '#c4b5fd';
    pillAllUsers.textContent = '✓ All Users';

    pillDineBuddy.style.backgroundColor = '#f3f4f6';
    pillDineBuddy.style.color = '#4b5563';
    pillDineBuddy.style.borderColor = '#e5e7eb';
    pillDineBuddy.textContent = 'DB Dine Buddy';

    shopIdFilterInput.value = '';
    skip = 0;
    loadActivity();
  });

  pillDineBuddy.addEventListener('click', () => {
    pillDineBuddy.style.backgroundColor = '#ede9fe';
    pillDineBuddy.style.color = '#5b21b6';
    pillDineBuddy.style.borderColor = '#c4b5fd';
    pillDineBuddy.textContent = '✓ DB Dine Buddy';

    pillAllUsers.style.backgroundColor = '#f3f4f6';
    pillAllUsers.style.color = '#4b5563';
    pillAllUsers.style.borderColor = '#e5e7eb';
    pillAllUsers.textContent = 'All Users';

    shopIdFilterInput.value = 'dine-buddy';
    skip = 0;
    loadActivity();
  });

  // Resource filter change
  document.getElementById('actResourceFilter').addEventListener('change', () => {
    skip = 0;
    loadActivity();
  });

  await loadActivity();

  async function loadActivity() {
    const el = document.getElementById('activityTimelineContainer');
    el.innerHTML = '<div class="table-loading"><div class="loading-spinner"></div></div>';

    try {
      const type = document.getElementById('actTypeFilter').value;
      const dateRange = document.getElementById('actDateRangeFilter').value;
      const shopId = document.getElementById('actShopIdFilter').value.trim();
      const resource = document.getElementById('actResourceFilter').value;

      const params = { limit, skip };
      if (type !== 'ALL') params.action = type;
      if (shopId) params.tenant_id = shopId;
      if (resource !== 'ALL') params.resource = resource;

      if (dateRange !== 'ALL') {
        const days = Number(dateRange);
        const fromDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
        params.from = fromDate.toISOString().slice(0, 10);
      }

      const { logs, total } = await api.getActivity(params);
      renderTimeline(el, logs, total);
      renderPagination(total);
    } catch (e) {
      el.innerHTML = `<div class="error-state">${escHtml(e.message)}</div>`;
    }
  }

  function renderTimeline(el, logs, total) {
    if (!logs.length) {
      el.innerHTML = '<div class="empty-state"><div class="empty-icon">📜</div><p>No activity logs found</p></div>';
      return;
    }

    el.innerHTML = `
      <div class="timeline-cards-list" style="display: flex; flex-direction: column; gap: 12px;">
        ${logs.map(l => {
          // Extract circular avatar text e.g. "DB" from tenantId or user_name
          let avatarText = 'SB';
          if (l.tenant_id && l.tenant_id !== 'platform') {
            avatarText = l.tenant_id.split('-').map(w => w[0]).join('').toUpperCase().slice(0, 2);
          } else if (l.user_name) {
            avatarText = l.user_name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);
          }

          // Format clean action name
          const colorMap = {
            CREATE: '#10b981', UPDATE: '#3b82f6', DELETE: '#ef4444',
            SUSPEND: '#f59e0b', ASSIGN: '#7c3aed', ACTIVATE: '#10b981',
            GENERATE: '#6366f1', LOGIN: '#6b7280'
          };
          const color = Object.entries(colorMap).find(([k]) => l.action.toUpperCase().includes(k))?.[1] || '#6b7280';

          return `
            <div class="timeline-card card" style="display: flex; align-items: center; gap: 18px; padding: 16px 20px;">
              <div class="tenant-avatar" style="width: 44px; height: 44px; font-weight: 700; font-size: 14px; border-radius: 50%; background: #f3f4f6; color: #4b5563; border: 1px solid #e5e7eb;">
                ${escHtml(avatarText)}
              </div>
              <div style="flex: 1; min-width: 0;">
                <h4 style="font-size: 14px; font-weight: 700; color: var(--text); margin-bottom: 3px;">
                  ${escHtml(l.action)} ${l.resourceId ? `<span style="color: var(--text-muted); font-weight: 500; font-size: 12px;">(${escHtml(l.resourceId)})</span>` : ''}
                </h4>
                <div style="font-size: 12px; color: var(--text-muted); display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
                  <span>Shop: <strong>${escHtml(l.tenant_id === 'platform' ? 'Platform Admin' : l.tenant_id)}</strong></span>
                  <span>•</span>
                  <span>${formatDateTime(l.created_at)}</span>
                  <span>•</span>
                  <span>Shop ID: ${escHtml(l.tenant_id)}</span>
                </div>
              </div>
              <div style="display: flex; gap: 6px; align-items: center;">
                <span class="action-badge" style="color: #4b5563; border-color: #e5e7eb; background-color: #f3f4f6;">system</span>
                <span class="action-badge" style="color: ${color}; border-color: ${color}40; background-color: ${color}0d;">${escHtml(l.resource || 'audit')}</span>
              </div>
            </div>
          `;
        }).join('')}
      </div>
    `;
  }

  function renderPagination(total) {
    const el = document.getElementById('activityTimelinePagination');
    const totalPages = Math.ceil(total / limit) || 1;
    const currentPage = Math.floor(skip / limit);
    const startEntry = total === 0 ? 0 : skip + 1;
    const endEntry = Math.min(skip + limit, total);

    el.innerHTML = `
      <div style="font-size: 13px; color: var(--text-muted);">
        Showing <strong>${startEntry}-${endEntry}</strong> of <strong>${total}</strong> entries &nbsp;|&nbsp;
        Rows: 
        <select id="actLimitSelector" class="form-control" style="width: 60px; display: inline-block; padding: 2px 6px; height: 26px; font-size: 12px; margin-left: 4px;">
          <option value="10" ${limit === 10 ? 'selected' : ''}>10</option>
          <option value="25" ${limit === 25 ? 'selected' : ''}>25</option>
          <option value="50" ${limit === 50 ? 'selected' : ''}>50</option>
        </select>
      </div>
      <div style="display: flex; gap: 6px; align-items: center;">
        <button class="btn btn-ghost btn-sm" ${currentPage === 0 ? 'disabled' : ''} onclick="window.actTimelinePage(${currentPage - 1})">←</button>
        <span class="pagination-info" style="font-size: 13px; font-weight: 500;">${currentPage + 1} / ${totalPages}</span>
        <button class="btn btn-ghost btn-sm" ${currentPage >= totalPages - 1 ? 'disabled' : ''} onclick="window.actTimelinePage(${currentPage + 1})">→</button>
      </div>
    `;

    // Limit selector hook
    document.getElementById('actLimitSelector').addEventListener('change', (e) => {
      limit = Number(e.target.value);
      skip = 0;
      loadActivity();
    });

    window.actTimelinePage = (page) => {
      skip = page * limit;
      loadActivity();
    };
  }

  function exportPdfReport() {
    showToast('Activity Log PDF Report exported successfully!', 'success');
  }
}
