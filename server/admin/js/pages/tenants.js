/**
 * StoreBuddy Admin — Tenants Page
 */
import { api } from '../api.js';
import { showToast, openModal, closeModal } from '../app.js';
import { formatDate, formatExpiry, statusBadge, planBadge, escHtml, copyToClipboard } from '../utils.js';

let allPlans = [];

export async function renderTenants(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Stores / Tenants</h1>
        <p class="page-subtitle">Manage all registered stores and their subscriptions</p>
      </div>
      <button class="btn btn-primary" id="btnNewTenant">
        <span>+ New Store</span>
      </button>
    </div>

    <div class="filters-bar">
      <div class="search-box">
        <span class="search-icon">🔍</span>
        <input type="text" id="tenantSearch" placeholder="Search stores, email…" class="search-input" />
      </div>
      <div class="filter-tabs" id="statusFilter">
        <button class="filter-tab active" data-status="">All</button>
        <button class="filter-tab" data-status="ACTIVE">Active</button>
        <button class="filter-tab" data-status="TRIAL">Trial</button>
        <button class="filter-tab" data-status="EXPIRED">Expired</button>
        <button class="filter-tab" data-status="SUSPENDED">Suspended</button>
        <button class="filter-tab" data-status="OFFLINE">Offline</button>
      </div>
    </div>

    <div class="card">
      <div id="tenantsTableContainer">
        <div class="table-loading"><div class="loading-spinner"></div></div>
      </div>
    </div>
  `;

  try { allPlans = (await api.getPlans()) || []; } catch { allPlans = []; }

  document.getElementById('btnNewTenant').addEventListener('click', () => showCreateTenantModal());

  let currentStatus = '';
  let searchTimeout;

  document.getElementById('tenantSearch').addEventListener('input', (e) => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => loadTenants(e.target.value, currentStatus), 350);
  });

  document.getElementById('statusFilter').addEventListener('click', (e) => {
    const tab = e.target.closest('[data-status]');
    if (!tab) return;
    document.querySelectorAll('.filter-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    currentStatus = tab.dataset.status;
    loadTenants(document.getElementById('tenantSearch').value, currentStatus);
  });

  await loadTenants('', '');

  async function loadTenants(search, status) {
    const el = document.getElementById('tenantsTableContainer');
    el.innerHTML = '<div class="table-loading"><div class="loading-spinner"></div></div>';
    try {
      const params = {};
      if (search) params.search = search;
      if (status) params.status = status;
      const { tenants, total } = await api.getTenants(params);
      renderTenantsTable(el, tenants, total);
    } catch (e) {
      el.innerHTML = `<div class="error-state">Failed to load stores: ${escHtml(e.message)}</div>`;
      showToast(e.message, 'error');
    }
  }

  function renderTenantsTable(el, tenants, total) {
    if (!tenants.length) {
      el.innerHTML = '<div class="empty-state"><div class="empty-icon">🏪</div><p>No stores found</p></div>';
      return;
    }
    el.innerHTML = `
      <div class="table-meta"><span>${total} stores</span></div>
      <div class="table-responsive">
        <table class="table">
          <thead>
            <tr>
              <th>Store</th>
              <th>Operating Mode</th>
              <th>Plan</th>
              <th>Status</th>
              <th>Expires</th>
              <th style="min-width: 175px;">Mode Switch</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            ${tenants.map(t => {
              const isOffline = t.status === 'OFFLINE' || !t.sync_enabled || t.plan_id === 'offline';
              return `
              <tr>
                <td>
                  <div class="tenant-cell">
                    <div class="tenant-avatar" style="background: ${isOffline ? 'linear-gradient(135deg, #f59e0b, #d97706)' : 'linear-gradient(135deg, #6366f1, #3b82f6)'};">${t.store_name[0].toUpperCase()}</div>
                    <div>
                      <div class="fw-600">${escHtml(t.store_name)}</div>
                      <div class="text-muted text-sm">${escHtml(t.owner_email)}</div>
                      <div class="text-muted text-xs">${escHtml(t.tenant_id)}</div>
                    </div>
                  </div>
                </td>
                <td>
                  ${isOffline 
                    ? '<span class="badge" style="background: rgba(245, 158, 11, 0.15); color: #d97706; border: 1px solid rgba(245, 158, 11, 0.3); font-weight: 700; padding: 4px 8px; border-radius: 6px;">📴 Offline Standalone</span>'
                    : '<span class="badge" style="background: rgba(59, 130, 246, 0.15); color: #2563eb; border: 1px solid rgba(59, 130, 246, 0.3); font-weight: 700; padding: 4px 8px; border-radius: 6px;">☁️ Online Cloud</span>'
                  }
                </td>
                <td>${planBadge(t.plan_name)}</td>
                <td>${statusBadge(t.status)}</td>
                <td class="text-sm">${formatExpiry(t.plan_expires_at)}</td>
                <td>
                  ${isOffline
                    ? `<button class="btn btn-sm" style="background: #2563eb; color: #fff; font-weight: 600; padding: 6px 12px; border-radius: 6px; box-shadow: 0 2px 4px rgba(37,99,235,0.25); cursor: pointer;" onclick="window.sbConvertToOnline('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">☁️ Convert to Online ↗</button>`
                    : `<button class="btn btn-sm btn-secondary" style="border: 1px solid #d97706; color: #d97706; font-weight: 600; padding: 6px 12px; border-radius: 6px; cursor: pointer;" onclick="window.sbConvertToOffline('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">📴 Switch to Offline</button>`
                  }
                </td>
                <td>
                  <div class="action-group">
                    <button class="btn btn-sm btn-ghost" onclick="window.sbShowAssignPlan('${escHtml(t.tenant_id)}','${escHtml(t.plan_id)}')">📋 Plan</button>
                    <div class="dropdown">
                      <button class="btn btn-sm btn-ghost btn-icon-only" data-dropdown="${t.tenant_id}">⋯</button>
                      <div class="dropdown-menu" id="dd_${t.tenant_id}">
                        <button class="dropdown-item" onclick="window.sbEditTenant('${escHtml(t.tenant_id)}')">✏️ Edit Details</button>
                        ${isOffline
                          ? `<button class="dropdown-item text-primary" onclick="window.sbConvertToOnline('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">☁️ Convert to Online Store</button>
                             <button class="dropdown-item" onclick="window.sbShowOfflineKey('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">🔑 Offline License Key</button>`
                          : `<button class="dropdown-item text-warning" onclick="window.sbConvertToOffline('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">📴 Switch to Offline Store</button>
                             <button class="dropdown-item" onclick="window.sbCopyActivationCode('${escHtml(t.activation_code || '')}')">📋 Copy Activation Code</button>`
                        }
                        <div class="dropdown-divider"></div>
                        <button class="dropdown-item text-success" onclick="window.sbActivateTenant('${escHtml(t.tenant_id)}')">✅ Set Exact Expiry</button>
                        ${(t.status === 'ACTIVE' || t.status === 'TRIAL' || t.status === 'OFFLINE') ? `<button class="dropdown-item text-danger" onclick="window.sbSuspendTenant('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">⛔ Suspend</button>` : ''}
                        <button class="dropdown-item text-danger" onclick="window.sbDeleteTenant('${escHtml(t.tenant_id)}','${escHtml(t.store_name)}')">🗑 Delete</button>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      </div>
    `;

    // Dropdown toggle
    document.querySelectorAll('[data-dropdown]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const id = btn.dataset.dropdown;
        const menu = document.getElementById(`dd_${id}`);
        const isOpen = menu.classList.contains('open');
        document.querySelectorAll('.dropdown-menu.open').forEach(m => m.classList.remove('open'));
        if (!isOpen) menu.classList.add('open');
      });
    });
    document.addEventListener('click', () => {
      document.querySelectorAll('.dropdown-menu.open').forEach(m => m.classList.remove('open'));
    }, { once: true, capture: true });
  }

  // ── Global action handlers ──
  window.sbShowAssignPlan = (tenantId, currentPlanId) => showAssignPlanModal(tenantId, currentPlanId, () => loadTenants('', currentStatus));
  window.sbEditTenant = (tenantId) => showEditTenantModal(tenantId, () => loadTenants('', currentStatus));
  window.sbShowOfflineKey = (tenantId, storeName) => showOfflineKeyModal(tenantId, storeName);
  window.sbCopyActivationCode = (code) => { copyToClipboard(code); showToast('Activation code copied!', 'success'); };
  window.sbConvertToOnline = (tenantId, storeName) => showConvertToOnlineModal(tenantId, storeName, () => loadTenants('', currentStatus));
  window.sbConvertToOffline = (tenantId, storeName) => showConvertToOfflineModal(tenantId, storeName, () => loadTenants('', currentStatus));
  window.sbSuspendTenant = async (tenantId, name) => {
    if (!confirm(`Suspend "${name}"? Their POS will stop working.`)) return;
    try {
      await api.suspendTenant(tenantId);
      showToast('Store suspended', 'success');
      loadTenants('', currentStatus);
    } catch (e) { showToast(e.message, 'error'); }
  };
  window.sbActivateTenant = (tenantId) => showActivateModal(tenantId, () => loadTenants('', currentStatus));
  window.sbDeleteTenant = async (tenantId, name) => {
    const confirm1 = confirm(`DELETE "${name}"? This is permanent and cannot be undone.`);
    if (!confirm1) return;
    const typed = prompt(`Type the store name "${name}" to confirm deletion:`);
    if (typed !== name) { showToast('Name did not match. Deletion cancelled.', 'error'); return; }
    try {
      await api.deleteTenant(tenantId);
      showToast('Store deleted', 'success');
      loadTenants('', currentStatus);
    } catch (e) { showToast(e.message, 'error'); }
  };
}

// ── Modals ──

function showCreateTenantModal() {
  const planOptions = allPlans.map(p => `<option value="${escHtml(p.plan_id)}">${escHtml(p.name)}</option>`).join('');
  openModal('Create New Store', `
    <form id="createTenantForm" class="form-grid">
      <div class="form-group">
        <label>Store Name *</label>
        <input type="text" name="store_name" class="form-control" required placeholder="My Store" />
      </div>
      <div class="form-group">
        <label>Tenant ID *</label>
        <input type="text" name="tenant_id" class="form-control" required placeholder="my-store" />
        <div class="form-hint">Lowercase letters, numbers, hyphens only. Cannot be changed.</div>
      </div>
      <div class="form-group">
        <label>Owner Name</label>
        <input type="text" name="owner_name" class="form-control" placeholder="John Silva" />
      </div>
      <div class="form-group">
        <label>Owner Email *</label>
        <input type="email" name="owner_email" class="form-control" required placeholder="owner@store.com" />
      </div>
      <div class="form-group">
        <label>Phone</label>
        <input type="text" name="owner_phone" class="form-control" placeholder="+94 77 123 4567" />
      </div>
      <div class="form-group">
        <label>Address</label>
        <input type="text" name="address" class="form-control" placeholder="No. 1, Main Street, Colombo" />
      </div>
      <div class="form-group">
        <label>Initial Password</label>
        <input type="text" name="password" class="form-control" placeholder="StorePass123!" />
      </div>
      <div class="form-group">
        <label>Plan</label>
        <select name="plan_id" class="form-control">${planOptions}</select>
      </div>
    </form>
  `, async () => {
    const form = document.getElementById('createTenantForm');
    const data = Object.fromEntries(new FormData(form));
    try {
      await api.createTenant(data);
      showToast('Store created successfully!', 'success');
      closeModal();
      window.location.reload();
    } catch (e) { showToast(e.message, 'error'); }
  });
}

function showAssignPlanModal(tenantId, currentPlanId, onDone) {
  const currentPlan = allPlans.find(p => p.plan_id === currentPlanId);
  const isCurrentlyOffline = currentPlan?.type === 'OFFLINE' || currentPlan?.sync_enabled === false;

  const planOptions = allPlans.map(p => {
    const modeTag = (!p.sync_enabled || p.type === 'OFFLINE') ? '📴 Offline' : '☁️ Cloud';
    return `<option value="${escHtml(p.plan_id)}" ${p.plan_id === currentPlanId ? 'selected' : ''}>[${modeTag}] ${escHtml(p.name)} (${p.duration_days > 0 ? p.duration_days + 'd' : 'Lifetime'})</option>`;
  }).join('');

  openModal('Assign Plan & Operating Mode', `
    <form id="assignPlanForm" class="form-grid">
      <div class="form-group" style="margin-bottom: 14px;">
        <label style="font-weight: 700; margin-bottom: 6px; display: block;">Operating Mode</label>
        <div style="display: flex; gap: 10px;">
          <button type="button" class="btn btn-sm ${!isCurrentlyOffline ? 'btn-primary' : 'btn-ghost'}" id="btnSelectCloudMode" style="flex:1; padding: 8px 12px; font-weight: 600;">
            ☁️ Cloud Online
          </button>
          <button type="button" class="btn btn-sm ${isCurrentlyOffline ? 'btn-primary' : 'btn-ghost'}" id="btnSelectOfflineMode" style="flex:1; padding: 8px 12px; font-weight: 600;">
            📴 Offline Standalone
          </button>
        </div>
        <p style="font-size: 11px; color: var(--text-muted); margin-top: 6px;" id="modeHelpText">
          ${!isCurrentlyOffline ? 'Store will have real-time cloud sync and multi-terminal access enabled.' : 'Store operates standalone on local SQLite. Multi-branch sync will be paused.'}
        </p>
      </div>
      <div class="form-group">
        <label>Subscription Plan *</label>
        <select name="plan_id" id="assignPlanSelect" class="form-control" required>${planOptions}</select>
      </div>
      <div class="form-group">
        <label>Custom Duration (days)</label>
        <input type="number" name="days" class="form-control" placeholder="Use plan default if empty" min="1" />
      </div>
      <div class="form-group">
        <label>Or Exact Expiry Date (Date Picker)</label>
        <input type="date" name="expires_at" class="form-control" />
      </div>
    </form>
  `, async () => {
    const form = document.getElementById('assignPlanForm');
    const data = Object.fromEntries(new FormData(form));
    if (!data.days) delete data.days;
    if (!data.expires_at) delete data.expires_at;
    try {
      await api.assignPlan(tenantId, data);
      showToast('Plan & Operating Mode updated!', 'success');
      closeModal();
      onDone();
    } catch (e) { showToast(e.message, 'error'); }
  });

  const btnCloud = document.getElementById('btnSelectCloudMode');
  const btnOffline = document.getElementById('btnSelectOfflineMode');
  const planSelect = document.getElementById('assignPlanSelect');
  const helpText = document.getElementById('modeHelpText');

  if (btnCloud && btnOffline) {
    btnCloud.onclick = () => {
      btnCloud.className = 'btn btn-sm btn-primary';
      btnOffline.className = 'btn btn-sm btn-ghost';
      helpText.textContent = 'Store will have real-time cloud sync and multi-terminal access enabled.';
      const cloudPlan = allPlans.find(p => p.sync_enabled && p.type !== 'OFFLINE');
      if (cloudPlan) planSelect.value = cloudPlan.plan_id;
    };
    btnOffline.onclick = () => {
      btnOffline.className = 'btn btn-sm btn-primary';
      btnCloud.className = 'btn btn-sm btn-ghost';
      helpText.textContent = 'Store operates standalone on local SQLite. Multi-branch sync will be paused.';
      const offlinePlan = allPlans.find(p => !p.sync_enabled || p.type === 'OFFLINE');
      if (offlinePlan) planSelect.value = offlinePlan.plan_id;
    };
  }
}

function showOfflineKeyModal(tenantId, storeName) {
  openModal('Generate Offline License Key', `
    <p class="modal-desc">Generate an offline license key for <strong>${escHtml(storeName)}</strong>. The store will operate without internet using this key.</p>
    <form id="offlineKeyForm" class="form-grid">
      <div class="form-group">
        <label>Plan</label>
        <select name="plan_id" class="form-control">
          ${allPlans.filter(p => !p.sync_enabled || p.type === 'OFFLINE').map(p =>
            `<option value="${escHtml(p.plan_id)}">${escHtml(p.name)}</option>`
          ).join('')}
          ${allPlans.filter(p => p.sync_enabled && p.type !== 'OFFLINE').map(p =>
            `<option value="${escHtml(p.plan_id)}">${escHtml(p.name)} (will disable sync)</option>`
          ).join('')}
        </select>
      </div>
      <div class="form-group">
        <label>Duration (days) *</label>
        <input type="number" name="days" class="form-control" value="365" min="1" max="3650" required />
      </div>
    </form>
    <div id="generatedKeyBox" style="display:none" class="key-box">
      <label>Generated Key:</label>
      <div class="key-display" id="generatedKey"></div>
      <button class="btn btn-sm btn-primary" onclick="window.sbCopyKey()">📋 Copy Key</button>
    </div>
  `, async () => {
    const form = document.getElementById('offlineKeyForm');
    const data = Object.fromEntries(new FormData(form));
    try {
      const result = await api.generateOfflineKey(tenantId, data);
      const box = document.getElementById('generatedKeyBox');
      const keyEl = document.getElementById('generatedKey');
      keyEl.textContent = result.offline_license_key;
      box.style.display = 'block';
      window.sbCopyKey = () => { copyToClipboard(result.offline_license_key); showToast('Key copied!', 'success'); };
    } catch (e) { showToast(e.message, 'error'); }
    return false; // Don't close modal yet
  });
}

function showActivateModal(tenantId, onDone) {
  openModal('Reactivate Store / Activate Subscription', `
    <form id="activateForm" class="form-grid">
      <div class="form-group">
        <label>Subscription / Plan *</label>
        <select name="subscription_type" id="subscriptionType" class="form-control" required>
          <option value="1month">Monthly Subscription (30 Days - Rs. 5,000)</option>
          <option value="6month">6 Months Subscription (180 Days - Rs. 27,000)</option>
          <option value="1year">Yearly Subscription (365 Days - Rs. 48,000)</option>
          <option value="custom">Custom Duration in Days</option>
          <option value="date">Exact Expiry Date (Date Picker)</option>
        </select>
      </div>
      <div class="form-group" id="customDaysGroup" style="display:none;">
        <label>Extension (days) *</label>
        <input type="number" name="days" id="customDays" class="form-control" value="30" min="1" max="3650" />
      </div>
      <div class="form-group" id="exactDateGroup" style="display:none;">
        <label>Exact Expiry Date *</label>
        <input type="date" name="expires_at" id="exactDate" class="form-control" />
      </div>
    </form>
  `, async () => {
    const type = document.getElementById('subscriptionType').value;
    const daysVal = document.getElementById('customDays').value;
    const exactDateVal = document.getElementById('exactDate').value;
    const payload = {};

    if (type === '1month') {
      payload.plan_id = '1month';
      payload.days = 30;
    } else if (type === '6month') {
      payload.plan_id = '6month';
      payload.days = 180;
    } else if (type === '1year') {
      payload.plan_id = '1year';
      payload.days = 365;
    } else if (type === 'date') {
      if (!exactDateVal) {
        showToast('Please pick an expiration date', 'error');
        return false;
      }
      payload.expires_at = exactDateVal;
      payload.plan_id = '1month';
    } else {
      payload.days = Number(daysVal) || 30;
    }

    try {
      await api.activateTenant(tenantId, payload);
      showToast('Store activated successfully!', 'success');
      closeModal();
      onDone();
    } catch (e) { showToast(e.message, 'error'); }
  });

  const select = document.getElementById('subscriptionType');
  const customGroup = document.getElementById('customDaysGroup');
  const customDaysInput = document.getElementById('customDays');
  const exactDateGroup = document.getElementById('exactDateGroup');
  const exactDateInput = document.getElementById('exactDate');
  
  select.addEventListener('change', () => {
    customGroup.style.display = select.value === 'custom' ? 'block' : 'none';
    customDaysInput.required = select.value === 'custom';
    exactDateGroup.style.display = select.value === 'date' ? 'block' : 'none';
    exactDateInput.required = select.value === 'date';
  });
}

function showConvertToOnlineModal(tenantId, storeName, onDone) {
  openModal(`Convert "${escHtml(storeName)}" to Online Cloud Store`, `
    <p class="modal-desc" style="font-size: 13px; color: var(--text-muted); margin-bottom: 16px;">
      Upgrade this offline store to StoreBuddy Cloud. Once converted, the cashier can enter the activation code into the POS terminal to sync all local SQLite data to the cloud.
    </p>
    <form id="convertToOnlineForm" class="form-grid">
      <div class="form-group">
        <label>Cloud Subscription Plan *</label>
        <select name="plan_id" id="convertPlanSelect" class="form-control" required>
          <option value="1month">Monthly Plan (Rs. 5,000 / mo - 30 Days)</option>
          <option value="6month">6 Months Package (Rs. 27,000 - 180 Days)</option>
          <option value="1year">Annual Subscription (Rs. 48,000 / yr - 365 Days)</option>
        </select>
      </div>
      <div class="form-group">
        <label>Exact Expiry Date (optional)</label>
        <input type="date" name="expires_at" id="convertExpiresAt" class="form-control" />
      </div>
      <div class="form-group">
        <label>Custom Duration in Days (optional)</label>
        <input type="number" name="days" id="convertDays" class="form-control" placeholder="Use plan default if empty" min="1" max="3650" />
      </div>
    </form>
    <div id="convertSuccessBox" style="display:none; margin-top: 16px; background: rgba(16, 185, 129, 0.1); border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 8px; padding: 16px;">
      <div style="color: var(--success); font-weight: bold; margin-bottom: 8px;">✓ Store successfully converted to Online Cloud!</div>
      <label style="font-size: 12px; font-weight: 600; color: var(--text-muted); display: block; margin-bottom: 4px;">Cloud Activation Code for POS Terminal:</label>
      <div style="font-family: monospace; font-size: 16px; font-weight: bold; color: var(--brand-purple-light); padding: 8px 12px; background: rgba(0,0,0,0.2); border-radius: 4px; margin-bottom: 12px;" id="convertActivationCode"></div>
      <button class="btn btn-sm btn-primary" id="btnCopyConvertCode">📋 Copy Activation Code</button>
      <p style="font-size: 12px; color: var(--text-muted); margin-top: 10px; line-height: 1.4;">
        Share this code with the cashier. In the POS app, open <strong>Sync Manager > Activate Sync</strong>, enter this code, and the local SQLite database will auto-sync to the cloud.
      </p>
    </div>
  `, async () => {
    const planId = document.getElementById('convertPlanSelect').value;
    const expiresAt = document.getElementById('convertExpiresAt').value;
    const days = document.getElementById('convertDays').value;
    const payload = { plan_id: planId };
    if (expiresAt) payload.expires_at = expiresAt;
    if (days) payload.days = Number(days);

    try {
      const res = await api.convertToOnline(tenantId, payload);
      document.getElementById('convertToOnlineForm').style.display = 'none';
      const box = document.getElementById('convertSuccessBox');
      box.style.display = 'block';
      document.getElementById('convertActivationCode').textContent = res.activation_code;
      document.getElementById('btnCopyConvertCode').onclick = () => {
        copyToClipboard(res.activation_code);
        showToast('Activation code copied to clipboard!', 'success');
      };
      showToast('Store converted to Online Cloud!', 'success');
      onDone();
      return false; // Keep modal open to copy code
    } catch (e) {
      showToast(e.message, 'error');
      return false;
    }
  });
}

function showConvertToOfflineModal(tenantId, storeName, onDone) {
  openModal(`Switch "${escHtml(storeName)}" to Offline Standalone`, `
    <div style="padding: 4px 0;">
      <p class="modal-desc" style="font-size: 13px; color: var(--text-muted); margin-bottom: 16px; line-height: 1.5;">
        You are switching <strong>${escHtml(storeName)}</strong> to <strong>Offline Standalone Mode</strong>. 
        Cloud synchronization will be disabled for this store and a lifetime standalone license key (SBOFF) will be generated for the cashier's local terminal.
      </p>
      <div id="offlineConvertForm">
        <div style="background: rgba(245, 158, 11, 0.1); border-left: 4px solid #f59e0b; padding: 12px; border-radius: 4px; margin-bottom: 16px;">
          <strong style="color: #f59e0b;">⚠️ Notice:</strong>
          <span style="font-size: 12px; color: var(--text-muted); display: block; margin-top: 4px;">
            The store terminal will continue operating locally with full POS features, but multi-branch synchronization will pause.
          </span>
        </div>
      </div>
      <div id="offlineConvertResult" style="display:none; background: rgba(16, 185, 129, 0.1); border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 8px; padding: 16px;">
        <div style="color: var(--success); font-weight: bold; margin-bottom: 8px;">✓ Store successfully switched to Offline Mode!</div>
        <label style="font-size: 12px; font-weight: 600; color: var(--text-muted); display: block; margin-bottom: 4px;">Offline Lifetime License Key (SBOFF):</label>
        <div style="font-family: monospace; font-size: 15px; font-weight: bold; color: var(--brand-purple-light); padding: 8px 12px; background: rgba(0,0,0,0.2); border-radius: 4px; margin-bottom: 12px; word-break: break-all;" id="offlineConvertKeyText"></div>
        <button class="btn btn-sm btn-primary" id="btnCopyOfflineConvertKey">📋 Copy License Key</button>
      </div>
    </div>
  `, async () => {
    try {
      const res = await api.convertToOffline(tenantId);
      document.getElementById('offlineConvertForm').style.display = 'none';
      const box = document.getElementById('offlineConvertResult');
      box.style.display = 'block';
      document.getElementById('offlineConvertKeyText').textContent = res.offline_license_key;
      document.getElementById('btnCopyOfflineConvertKey').onclick = () => {
        copyToClipboard(res.offline_license_key);
        showToast('Offline license key copied!', 'success');
      };
      showToast('Store switched to Offline Standalone!', 'success');
      onDone();
      return false; // Keep modal open so admin can copy key
    } catch (e) {
      showToast(e.message, 'error');
      return false;
    }
  });
}

async function showEditTenantModal(tenantId, onDone) {
  let tenant;
  try { tenant = await api.getTenant(tenantId); } catch (e) { showToast(e.message, 'error'); return; }

  openModal('Edit Store', `
    <form id="editTenantForm" class="form-grid">
      <div class="form-group">
        <label>Store Name</label>
        <input type="text" name="store_name" class="form-control" value="${escHtml(tenant.store_name)}" />
      </div>
      <div class="form-group">
        <label>Phone</label>
        <input type="text" name="owner_phone" class="form-control" value="${escHtml(tenant.owner_phone)}" />
      </div>
      <div class="form-group">
        <label>Address</label>
        <input type="text" name="address" class="form-control" value="${escHtml(tenant.address)}" />
      </div>
      <div class="form-group">
        <label>Max Locations</label>
        <input type="number" name="max_locations" class="form-control" value="${tenant.max_locations}" min="1" />
      </div>
      <div class="form-group">
        <label>Max Users</label>
        <input type="number" name="max_users" class="form-control" value="${tenant.max_users}" min="1" />
      </div>
      <div class="form-group">
        <label>Max Products</label>
        <input type="number" name="max_products" class="form-control" value="${tenant.max_products}" min="1" />
      </div>
      <div class="form-group">
        <label>
          <input type="checkbox" name="sync_enabled" ${tenant.sync_enabled ? 'checked' : ''} />
          Cloud Sync Enabled
        </label>
      </div>
    </form>
  `, async () => {
    const form = document.getElementById('editTenantForm');
    const fd = new FormData(form);
    const data = Object.fromEntries(fd);
    data.sync_enabled = form.querySelector('[name=sync_enabled]').checked;
    try {
      await api.updateTenant(tenantId, data);
      showToast('Store updated!', 'success');
      closeModal();
      onDone();
    } catch (e) { showToast(e.message, 'error'); }
  });
}
