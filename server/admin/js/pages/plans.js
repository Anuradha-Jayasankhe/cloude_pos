/**
 * StoreBuddy Admin — Plans Page
 */
import { api } from '../api.js';
import { showToast, openModal, closeModal } from '../app.js';
import { formatCurrency, escHtml } from '../utils.js';

export async function renderPlans(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Subscription Plans & Trial Settings</h1>
        <p class="page-subtitle">Manage default trial duration, plan tiers, pricing, and feature limits</p>
      </div>
      <button class="btn btn-primary" id="btnNewPlan">+ New Plan</button>
    </div>

    <!-- Default Trial Period Settings Card -->
    <div class="card" style="margin-bottom: 24px; padding: 20px; border-left: 4px solid #f59e0b; background: rgba(245, 158, 11, 0.05);">
      <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
        <div>
          <h3 style="margin: 0 0 6px 0; display: flex; align-items: center; gap: 8px; font-size: 1.1rem;">
            <span>⏱️</span> Default Free Trial Period for New Accounts
          </h3>
          <p style="margin: 0; color: #64748b; font-size: 0.88rem;">
            Permanent free accounts are deactivated. Newly registered stores automatically receive this trial period (default: 7 days).
          </p>
        </div>
        <div style="display: flex; align-items: center; gap: 12px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <input type="number" id="trialDaysInput" class="form-control" style="width: 90px; text-align: center; font-weight: 600; font-size: 1rem;" min="1" max="90" value="7" />
            <span style="font-weight: 500; color: #475569;">Days</span>
          </div>
          <button class="btn btn-secondary btn-sm" id="btnSet7Days">7 Days</button>
          <button class="btn btn-secondary btn-sm" id="btnSet14Days">14 Days</button>
          <button class="btn btn-primary" id="btnSaveTrialSetting">Save Settings</button>
        </div>
      </div>
    </div>

    <div id="plansGrid" class="plans-grid">
      <div class="loading-spinner"></div>
    </div>
  `;

  document.getElementById('btnNewPlan').addEventListener('click', () => showPlanModal(null, loadPlans));

  // Trial settings wiring
  const trialInput = document.getElementById('trialDaysInput');
  const btnSave = document.getElementById('btnSaveTrialSetting');
  document.getElementById('btnSet7Days').addEventListener('click', () => { trialInput.value = '7'; });
  document.getElementById('btnSet14Days').addEventListener('click', () => { trialInput.value = '14'; });

  try {
    const settings = await api.getSettings();
    if (settings && settings.default_trial_days) {
      trialInput.value = settings.default_trial_days;
    }
  } catch (e) {
    console.warn('Could not load platform settings:', e);
  }

  btnSave.addEventListener('click', async () => {
    const val = parseInt(trialInput.value, 10);
    if (isNaN(val) || val < 1) {
      showToast('Please enter a valid number of days (at least 1)', 'error');
      return;
    }
    btnSave.disabled = true;
    btnSave.textContent = 'Saving...';
    try {
      await api.updateSettings({ default_trial_days: val });
      showToast(`Default trial duration updated to ${val} days!`, 'success');
    } catch (e) {
      showToast(e.message, 'error');
    } finally {
      btnSave.disabled = false;
      btnSave.textContent = 'Save Settings';
    }
  });

  await loadPlans();

  async function loadPlans() {
    const el = document.getElementById('plansGrid');
    try {
      const plans = await api.getPlans();
      if (!plans.length) {
        el.innerHTML = '<div class="empty-state"><p>No plans configured</p></div>';
        return;
      }
      el.innerHTML = plans.map(p => renderPlanCard(p)).join('');
      el.querySelectorAll('[data-edit-plan]').forEach(btn => {
        btn.addEventListener('click', () => showPlanModal(btn.dataset.editPlan, loadPlans));
      });
      el.querySelectorAll('[data-toggle-plan]').forEach(btn => {
        btn.addEventListener('click', async () => {
          const planId = btn.dataset.togglePlan;
          const isActive = btn.dataset.active === 'true';
          try {
            await api.updatePlan(planId, { is_active: !isActive });
            showToast(isActive ? 'Plan hidden' : 'Plan visible', 'success');
            loadPlans();
          } catch (e) { showToast(e.message, 'error'); }
        });
      });
    } catch (e) {
      el.innerHTML = `<div class="error-state">${escHtml(e.message)}</div>`;
    }
  }
}

function renderPlanCard(p) {
  const typeColors = {
    FREE: '#6b7280', TRIAL: '#f59e0b', MONTHLY: '#3b82f6',
    BIANNUAL: '#10b981', ANNUAL: '#7c3aed', CUSTOM: '#ec4899', OFFLINE: '#6366f1',
  };
  const color = typeColors[p.type] || '#7c3aed';
  const opacity = p.is_active ? '1' : '0.5';

  const productsDisplay = (!p.max_products || p.max_products === 0) ? 'Unlimited products' : `${p.max_products} products`;
  const locationsDisplay = (!p.max_locations || p.max_locations === 0) ? 'Unlimited locations' : `${p.max_locations} location${p.max_locations > 1 ? 's' : ''}`;

  return `
    <div class="plan-card" style="--plan-color:${color};opacity:${opacity}">
      <div class="plan-card-header">
        <div class="plan-card-type">${escHtml(p.type)}</div>
        <div class="plan-card-actions">
          <button class="btn btn-sm btn-ghost" data-edit-plan="${escHtml(p.plan_id)}">✏️</button>
          <button class="btn btn-sm btn-ghost" data-toggle-plan="${escHtml(p.plan_id)}" data-active="${p.is_active}">
            ${p.is_active ? '👁' : '👁‍🗨'}
          </button>
        </div>
      </div>
      <div class="plan-card-name">${escHtml(p.name)}</div>
      <div class="plan-card-price">
        <span class="price-amount">${p.price_monthly > 0 ? formatCurrency(p.price_monthly) : (p.price_yearly > 0 ? formatCurrency(p.price_yearly) : 'Free Trial')}</span>
        ${p.price_monthly > 0 ? '<span class="price-period">/month</span>' : ''}
      </div>
      ${p.price_yearly > 0 ? `<div class="plan-card-yearly">${formatCurrency(p.price_yearly)}${p.type === 'OFFLINE' ? ' (One-Time Lifetime License)' : '/year'}</div>` : ''}
      <div class="plan-card-desc">${escHtml(p.description)}</div>
      <div class="plan-limits">
        <div class="plan-limit"><span class="limit-icon">👤</span> ${p.max_users} users</div>
        <div class="plan-limit"><span class="limit-icon">📦</span> <strong>${productsDisplay}</strong></div>
        <div class="plan-limit"><span class="limit-icon">📍</span> <strong>${locationsDisplay}</strong></div>
        <div class="plan-limit"><span class="limit-icon">${p.sync_enabled ? '☁️' : '📴'}</span> ${p.sync_enabled ? 'Cloud sync' : 'Offline only'}</div>
        <div class="plan-limit"><span class="limit-icon">🗓</span> ${p.duration_days > 0 ? (p.type === 'OFFLINE' ? 'Lifetime (Permanent)' : `${p.duration_days} days`) : 'No expiry'}</div>
      </div>
      ${p.features.length ? `
        <div class="plan-features">
          ${p.features.map(f => `<div class="plan-feature">✓ ${escHtml(f)}</div>`).join('')}
        </div>
      ` : ''}
      <div class="plan-card-footer">
        <span class="badge ${p.is_public ? 'badge-success' : 'badge-secondary'}">${p.is_public ? 'Public' : 'Private'}</span>
        <span class="badge ${p.is_active ? 'badge-success' : 'badge-secondary'}">${p.is_active ? 'Active' : 'Deactivated'}</span>
      </div>
    </div>
  `;
}

async function showPlanModal(planId, onDone) {
  let plan = null;
  if (planId) {
    try {
      const plans = await api.getPlans();
      plan = plans.find(p => p.plan_id === planId);
    } catch {}
  }

  const v = (field, def = '') => plan ? (plan[field] ?? def) : def;

  openModal(plan ? 'Edit Plan' : 'Create Plan', `
    <form id="planForm" class="form-grid form-grid-2col">
      <div class="form-group">
        <label>Plan ID ${plan ? '' : '*'}</label>
        <input type="text" name="plan_id" class="form-control" value="${escHtml(v('plan_id'))}" ${plan ? 'readonly' : 'required'} placeholder="e.g. 3month" />
        ${!plan ? '<div class="form-hint">Lowercase, no spaces. Cannot be changed later.</div>' : ''}
      </div>
      <div class="form-group">
        <label>Name *</label>
        <input type="text" name="name" class="form-control" value="${escHtml(v('name'))}" required placeholder="3 Months" />
      </div>
      <div class="form-group">
        <label>Type</label>
        <select name="type" class="form-control">
          ${['FREE','TRIAL','MONTHLY','BIANNUAL','ANNUAL','CUSTOM','OFFLINE'].map(t =>
            `<option value="${t}" ${v('type') === t ? 'selected' : ''}>${t}</option>`
          ).join('')}
        </select>
      </div>
      <div class="form-group">
        <label>Duration (days, 0 = no expiry)</label>
        <input type="number" name="duration_days" class="form-control" value="${v('duration_days', 30)}" min="0" />
      </div>
      <div class="form-group">
        <label>Price / Month (LKR)</label>
        <input type="number" name="price_monthly" class="form-control" value="${v('price_monthly', 0)}" min="0" />
      </div>
      <div class="form-group">
        <label>Price / Year (LKR)</label>
        <input type="number" name="price_yearly" class="form-control" value="${v('price_yearly', 0)}" min="0" />
      </div>
      <div class="form-group">
        <label>Max Users</label>
        <input type="number" name="max_users" class="form-control" value="${v('max_users', 5)}" min="1" />
      </div>
      <div class="form-group">
        <label>Max Products (0 = Unlimited)</label>
        <input type="number" name="max_products" class="form-control" value="${v('max_products', 0)}" min="0" />
      </div>
      <div class="form-group">
        <label>Max Locations (0 = Unlimited)</label>
        <input type="number" name="max_locations" class="form-control" value="${v('max_locations', 0)}" min="0" />
      </div>
      <div class="form-group">
        <label>Trial Days</label>
        <input type="number" name="trial_days" class="form-control" value="${v('trial_days', 0)}" min="0" />
      </div>
      <div class="form-group form-group-full">
        <label>Description</label>
        <textarea name="description" class="form-control" rows="2" placeholder="Brief description for customers">${escHtml(v('description'))}</textarea>
      </div>
      <div class="form-group form-group-full">
        <label>Features (one per line)</label>
        <textarea name="features_text" class="form-control" rows="4" placeholder="Full POS&#10;Cloud Sync&#10;Reports">${escHtml((v('features', [])).join('\n'))}</textarea>
      </div>
      <div class="form-group">
        <label class="checkbox-label">
          <input type="checkbox" name="sync_enabled" ${v('sync_enabled', true) ? 'checked' : ''} />
          Cloud Sync Enabled
        </label>
      </div>
      <div class="form-group">
        <label class="checkbox-label">
          <input type="checkbox" name="is_public" ${v('is_public', true) ? 'checked' : ''} />
          Publicly Visible
        </label>
      </div>
      <div class="form-group">
        <label class="checkbox-label">
          <input type="checkbox" name="is_active" ${v('is_active', true) ? 'checked' : ''} />
          Active
        </label>
      </div>
    </form>
  `, async () => {
    const form = document.getElementById('planForm');
    const fd = new FormData(form);
    const data = Object.fromEntries(fd);
    data.sync_enabled = form.querySelector('[name=sync_enabled]').checked;
    data.is_public = form.querySelector('[name=is_public]').checked;
    data.is_active = form.querySelector('[name=is_active]').checked;
    data.features = (data.features_text || '').split('\n').map(s => s.trim()).filter(Boolean);
    delete data.features_text;

    try {
      if (plan) {
        await api.updatePlan(plan.plan_id, data);
        showToast('Plan updated!', 'success');
      } else {
        await api.createPlan(data);
        showToast('Plan created!', 'success');
      }
      closeModal();
      onDone();
    } catch (e) { showToast(e.message, 'error'); }
  });
}
