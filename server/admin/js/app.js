/**
 * StoreBuddy Admin — App Shell, Router, Sidebar
 */
import { api } from './api.js?v=2';
import { renderDashboard } from './pages/dashboard.js?v=2';
import { renderTenants } from './pages/tenants.js?v=2';
import { renderPlans } from './pages/plans.js?v=2';
import { renderUsers } from './pages/users.js?v=2';
import { renderActivity } from './pages/activity.js?v=2';
import { renderReleases } from './pages/releases.js?v=2';
import { renderQrPayments } from './pages/qr_payments.js?v=2';
import { renderDocs } from './pages/documentation.js?v=2';
import { renderTutorials } from './pages/tutorials.js?v=2';
import { renderSupport } from './pages/support.js?v=2';
import { renderAbout } from './pages/about.js?v=2';
import { renderContact } from './pages/contact.js?v=2';

const ROUTES = [
  { path: '/dashboard', label: 'Dashboard', icon: '📊', render: renderDashboard },
  { path: '/tenants', label: 'Shops', icon: '🏪', render: renderTenants },
  { path: '/plans', label: 'Plans', icon: '📋', render: renderPlans },
  { path: '/users', label: 'Users', icon: '👥', render: renderUsers },
  { path: '/qr-payments', label: 'QR Payments', icon: '📱', render: renderQrPayments },
  { path: '/activity', label: 'Activity', icon: '📜', render: renderActivity },
  { path: '/releases', label: 'Releases', icon: '🚀', render: renderReleases },
  { path: '/documentation', label: 'Documentation', icon: '📄', render: renderDocs },
  { path: '/tutorials', label: 'Tutorials', icon: '🎥', render: renderTutorials },
  { path: '/support', label: 'Support', icon: '💬', render: renderSupport },
  { path: '/about', label: 'About', icon: 'ℹ️', render: renderAbout },
  { path: '/contact', label: 'Contact', icon: '📧', render: renderContact },
];

let currentRoute = null;

function getUser() {
  try { return JSON.parse(localStorage.getItem('sb_admin_user') || 'null'); } catch { return null; }
}

function isLoggedIn() {
  return !!localStorage.getItem('sb_admin_token');
}

function logout() {
  localStorage.removeItem('sb_admin_token');
  localStorage.removeItem('sb_admin_user');
  window.location.hash = '#/login';
}

function getPath() {
  return window.location.hash.replace('#', '') || '/dashboard';
}

function navigate(path) {
  window.location.hash = `#${path}`;
}

// ── Toast Notifications ──────────────────────────────────────────────────────

export function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;
  const id = `toast_${Date.now()}`;
  const icons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
  const toast = document.createElement('div');
  toast.id = id;
  toast.className = `toast toast--${type}`;
  toast.innerHTML = `<span class="toast-icon">${icons[type] || 'ℹ️'}</span><span class="toast-msg">${message}</span><button class="toast-close" onclick="document.getElementById('${id}').remove()">✕</button>`;
  container.appendChild(toast);
  requestAnimationFrame(() => toast.classList.add('toast--visible'));
  setTimeout(() => { toast.classList.remove('toast--visible'); setTimeout(() => toast.remove(), 300); }, 4000);
}

// ── Modal ────────────────────────────────────────────────────────────────────

export function openModal(title, bodyHtml, onConfirm) {
  const overlay = document.getElementById('modalOverlay');
  const titleEl = document.getElementById('modalTitle');
  const bodyEl = document.getElementById('modalBody');
  const confirmBtn = document.getElementById('modalConfirm');

  titleEl.textContent = title;
  bodyEl.innerHTML = bodyHtml;
  overlay.classList.add('open');

  const newConfirm = confirmBtn.cloneNode(true);
  confirmBtn.parentNode.replaceChild(newConfirm, confirmBtn);
  newConfirm.addEventListener('click', async () => {
    newConfirm.disabled = true;
    newConfirm.textContent = 'Saving…';
    try {
      const result = await onConfirm();
      if (result !== false) closeModal();
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      newConfirm.disabled = false;
      newConfirm.textContent = 'Save';
    }
  });
}

export function closeModal() {
  const overlay = document.getElementById('modalOverlay');
  overlay.classList.remove('open');
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

function renderSidebar() {
  const sidebar = document.getElementById('sidebar');
  const user = getUser();
  const path = getPath();

  sidebar.innerHTML = `
    <div class="sidebar-brand">
      <div class="brand-logo">
        <div class="brand-icon">SB</div>
      </div>
      <div class="brand-text">
        <div class="brand-name">StoreBuddy</div>
        <div class="brand-tagline">Admin Panel</div>
      </div>
    </div>

    <nav class="sidebar-nav">
      ${ROUTES.map(r => `
        <a href="#${r.path}" class="nav-item ${path === r.path ? 'nav-item--active' : ''}">
          <span class="nav-icon">${r.icon}</span>
          <span class="nav-label">${r.label}</span>
          ${r.path === '/tenants' ? '<span class="nav-badge" id="tenantBadge"></span>' : ''}
        </a>
      `).join('')}
    </nav>

    <div class="sidebar-footer">
      <div class="sidebar-user">
        <div class="user-avatar">${(user?.name || 'A')[0].toUpperCase()}</div>
        <div class="sidebar-user-info">
          <div class="fw-600 text-sm">${user?.name || 'Admin'}</div>
          <div class="text-muted text-xs">${user?.email || ''}</div>
        </div>
      </div>
      <button class="btn btn-ghost btn-sm" onclick="window.sbLogout()">⬅ Logout</button>
    </div>
  `;
}

function updateHeader(label) {
  const el = document.getElementById('headerTitle');
  if (el) el.textContent = label;
}

// ── Router ───────────────────────────────────────────────────────────────────

async function handleRoute() {
  const path = getPath();

  if (path === '/login') {
    renderLogin();
    return;
  }

  if (!isLoggedIn()) {
    window.location.hash = '#/login';
    return;
  }

  const appShell = document.getElementById('appShell');
  const loginPage = document.getElementById('loginPage');
  appShell.style.display = 'flex';
  loginPage.style.display = 'none';

  renderSidebar();

  const route = ROUTES.find(r => path.startsWith(r.path));
  if (!route) {
    window.location.hash = '#/dashboard';
    return;
  }

  updateHeader(route.label);

  if (currentRoute !== route.path) {
    currentRoute = route.path;
    const content = document.getElementById('mainContent');
    content.innerHTML = '';
    await route.render(content);
  }
}

// ── Login Page ────────────────────────────────────────────────────────────────

function renderLogin() {
  const appShell = document.getElementById('appShell');
  const loginPage = document.getElementById('loginPage');
  appShell.style.display = 'none';
  loginPage.style.display = 'flex';
}

async function handleLogin(e) {
  e.preventDefault();
  const form = e.target;
  const email = form.querySelector('[name=email]').value.trim();
  const password = form.querySelector('[name=password]').value;
  const btn = form.querySelector('button[type=submit]');
  btn.disabled = true;
  btn.textContent = 'Signing in…';

  try {
    const data = await api.login(email, password);
    if (data.role !== 'platform_admin') {
      showToast('Access denied. Platform admin only.', 'error');
      return;
    }
    localStorage.setItem('sb_admin_token', data.access_token);
    localStorage.setItem('sb_admin_user', JSON.stringify({ name: email.split('@')[0], email, role: data.role }));
    window.location.hash = '#/dashboard';
  } catch (err) {
    showToast(err.message || 'Login failed', 'error');
  } finally {
    btn.disabled = false;
    btn.textContent = 'Sign In';
  }
}

// ── Init ─────────────────────────────────────────────────────────────────────

export function init() {
  window.sbLogout = logout;

  document.getElementById('loginForm').addEventListener('submit', handleLogin);
  document.getElementById('modalCancel').addEventListener('click', closeModal);
  document.getElementById('modalClose').addEventListener('click', closeModal);
  document.getElementById('modalOverlay').addEventListener('click', (e) => {
    if (e.target === document.getElementById('modalOverlay')) closeModal();
  });

  window.addEventListener('hashchange', () => { currentRoute = null; handleRoute(); });
  handleRoute();
}
