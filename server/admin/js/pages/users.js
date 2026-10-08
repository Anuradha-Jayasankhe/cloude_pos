/**
 * StoreBuddy Admin — Users Page
 */
import { api } from '../api.js';
import { showToast, openModal, closeModal } from '../app.js';
import { formatDate, roleBadge, statusBadge, escHtml } from '../utils.js';

export async function renderUsers(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Users</h1>
        <p class="page-subtitle">All platform and store users</p>
      </div>
      <button class="btn btn-primary" id="btnNewUser">+ New User</button>
    </div>
    <div class="filters-bar">
      <div class="search-box">
        <span class="search-icon">🔍</span>
        <input type="text" id="userSearch" placeholder="Filter by name or email…" class="search-input" />
      </div>
    </div>
    <div class="card">
      <div id="usersTableContainer"><div class="table-loading"><div class="loading-spinner"></div></div></div>
    </div>
  `;

  let searchTimeout;
  document.getElementById('btnNewUser').addEventListener('click', () => showCreateUserModal(() => loadUsers('')));
  document.getElementById('userSearch').addEventListener('input', e => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => loadUsers(e.target.value), 350);
  });

  await loadUsers('');

  async function loadUsers(search) {
    const el = document.getElementById('usersTableContainer');
    el.innerHTML = '<div class="table-loading"><div class="loading-spinner"></div></div>';
    try {
      const params = {};
      if (search) params.search = search; // server doesn't filter by search yet, done client-side
      const { users, total } = await api.getUsers(params);
      const filtered = search
        ? users.filter(u => u.name.toLowerCase().includes(search.toLowerCase()) || u.email.toLowerCase().includes(search.toLowerCase()))
        : users;
      renderTable(el, filtered, total);
    } catch (e) {
      el.innerHTML = `<div class="error-state">${escHtml(e.message)}</div>`;
    }
  }

  function renderTable(el, users, total) {
    if (!users.length) {
      el.innerHTML = '<div class="empty-state"><div class="empty-icon">👤</div><p>No users found</p></div>';
      return;
    }
    // Group by platform vs store users
    const platform = users.filter(u => u.tenant_id === 'platform' || u.role === 'platform_admin');
    const store = users.filter(u => u.tenant_id !== 'platform' && u.role !== 'platform_admin');

    el.innerHTML = `
      <div class="table-meta"><span>${total} users total</span></div>
      ${platform.length ? `
        <div class="table-section-header">Platform Operators</div>
        ${buildTable(platform)}
      ` : ''}
      ${store.length ? `
        <div class="table-section-header">Store Users</div>
        ${buildTable(store)}
      ` : ''}
    `;
  }

  function buildTable(users) {
    return `
      <div class="table-responsive">
        <table class="table">
          <thead>
            <tr><th>Name</th><th>Email</th><th>Role</th><th>Tenant</th><th>Status</th><th>Joined</th></tr>
          </thead>
          <tbody>
            ${users.map(u => `
              <tr>
                <td>
                  <div class="user-cell">
                    <div class="user-avatar">${u.name[0].toUpperCase()}</div>
                    <span class="fw-600">${escHtml(u.name)}</span>
                  </div>
                </td>
                <td class="text-muted">${escHtml(u.email)}</td>
                <td>${roleBadge(u.role)}</td>
                <td class="text-muted text-sm">${escHtml(u.tenant_id)}</td>
                <td>${u.active ? '<span class="badge badge-success">Active</span>' : '<span class="badge badge-danger">Inactive</span>'}</td>
                <td class="text-muted text-sm">${formatDate(u.created_at)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  }
}

function showCreateUserModal(onDone) {
  openModal('Create User', `
    <form id="createUserForm" class="form-grid">
      <div class="form-group">
        <label>Name *</label>
        <input type="text" name="name" class="form-control" required placeholder="John Silva" />
      </div>
      <div class="form-group">
        <label>Email *</label>
        <input type="email" name="email" class="form-control" required placeholder="john@store.com" />
      </div>
      <div class="form-group">
        <label>Password *</label>
        <input type="password" name="password" class="form-control" required placeholder="Min 8 chars" />
      </div>
      <div class="form-group">
        <label>Tenant ID *</label>
        <input type="text" name="tenant_id" class="form-control" required placeholder="store-id" />
      </div>
      <div class="form-group">
        <label>Role</label>
        <select name="role" class="form-control">
          <option value="cashier">Cashier</option>
          <option value="manager" selected>Manager</option>
          <option value="admin">Admin</option>
          <option value="owner">Owner</option>
        </select>
      </div>
    </form>
  `, async () => {
    const form = document.getElementById('createUserForm');
    const data = Object.fromEntries(new FormData(form));
    try {
      await api.createUser(data);
      showToast('User created!', 'success');
      closeModal();
      onDone();
    } catch (e) { showToast(e.message, 'error'); }
  });
}
