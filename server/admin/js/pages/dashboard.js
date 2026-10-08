/**
 * StoreBuddy Admin — Dashboard Page
 */
import { api } from '../api.js';
import { showToast } from '../app.js';
import { formatDate, formatCurrency, statusBadge, planBadge } from '../utils.js';

export async function renderDashboard(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-subtitle">Platform overview and key metrics</p>
      </div>
      <button class="btn btn-primary" onclick="window.refreshDashboard()">
        <span class="btn-icon">↻</span> Refresh
      </button>
    </div>

    <div class="stats-grid" id="statsGrid">
      <div class="stat-card skeleton"></div>
      <div class="stat-card skeleton"></div>
      <div class="stat-card skeleton"></div>
      <div class="stat-card skeleton"></div>
      <div class="stat-card skeleton"></div>
    </div>

    <div class="dashboard-grid">
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Recent Stores</h3>
          <a href="#/tenants" class="btn btn-ghost btn-sm">View All →</a>
        </div>
        <div id="recentTenants" class="table-wrapper">
          <div class="loading-spinner"></div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Plan Distribution</h3>
        </div>
        <div id="planDistribution" class="plan-distribution"></div>
      </div>
    </div>
  `;

  window.refreshDashboard = loadDashboardData;
  await loadDashboardData();

  async function loadDashboardData() {
    try {
      const stats = await api.getStats();
      renderStats(stats);
      renderRecentTenants(stats.recent_tenants || []);
      await renderPlanDistribution();
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  function renderStats(stats) {
    const el = document.getElementById('statsGrid');
    el.innerHTML = `
      <div class="stat-card">
        <div class="stat-icon stat-icon--blue">🏪</div>
        <div class="stat-body">
          <div class="stat-value">${stats.total_tenants ?? 0}</div>
          <div class="stat-label">Total Stores</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--green">✅</div>
        <div class="stat-body">
          <div class="stat-value">${stats.active_tenants ?? 0}</div>
          <div class="stat-label">Active Stores</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--orange">🕐</div>
        <div class="stat-body">
          <div class="stat-value">${stats.trial_tenants ?? 0}</div>
          <div class="stat-label">On Trial</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--red">⛔</div>
        <div class="stat-body">
          <div class="stat-value">${stats.suspended_tenants ?? 0}</div>
          <div class="stat-label">Suspended</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--purple">☁️</div>
        <div class="stat-body">
          <div class="stat-value">${(stats.total_sync_events ?? 0).toLocaleString()}</div>
          <div class="stat-label">Sync Events</div>
        </div>
      </div>
    `;
  }

  function renderRecentTenants(tenants) {
    const el = document.getElementById('recentTenants');
    if (!tenants.length) {
      el.innerHTML = '<div class="empty-state"><p>No stores registered yet</p></div>';
      return;
    }
    el.innerHTML = `
      <table class="table">
        <thead><tr><th>Store</th><th>Plan</th><th>Status</th><th>Joined</th></tr></thead>
        <tbody>
          ${tenants.map(t => `
            <tr class="clickable-row" onclick="window.location.hash='#/tenants'">
              <td>
                <div class="tenant-cell">
                  <div class="tenant-avatar">${t.store_name[0].toUpperCase()}</div>
                  <div>
                    <div class="fw-600">${escHtml(t.store_name)}</div>
                    <div class="text-muted text-sm">${escHtml(t.owner_email)}</div>
                  </div>
                </div>
              </td>
              <td>${planBadge(t.plan_name)}</td>
              <td>${statusBadge(t.status)}</td>
              <td class="text-muted">${formatDate(t.created_at)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  async function renderPlanDistribution() {
    const el = document.getElementById('planDistribution');
    try {
      const { tenants } = await api.getTenants({ limit: 500 });
      const counts = {};
      tenants.forEach(t => {
        const name = t.plan_name || 'Trial';
        counts[name] = (counts[name] || 0) + 1;
      });

      const total = tenants.length || 1;
      const colors = ['#7c3aed', '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#6366f1'];
      const entries = Object.entries(counts).sort((a, b) => b[1] - a[1]);

      el.innerHTML = entries.map(([name, count], i) => `
        <div class="plan-bar-item">
          <div class="plan-bar-label">
            <span>${escHtml(name)}</span>
            <span class="fw-600">${count}</span>
          </div>
          <div class="plan-bar-track">
            <div class="plan-bar-fill" style="width:${Math.round(count/total*100)}%;background:${colors[i%colors.length]}"></div>
          </div>
          <div class="text-muted text-sm">${Math.round(count/total*100)}%</div>
        </div>
      `).join('') || '<div class="empty-state"><p>No data</p></div>';
    } catch {
      el.innerHTML = '<div class="empty-state"><p>Could not load distribution</p></div>';
    }
  }
}

function escHtml(str) {
  return String(str ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
