/**
 * StoreBuddy Admin — Utility Functions
 */

export function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

export function formatDateTime(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleString('en-US', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export function formatCurrency(amount, currency = 'LKR') {
  if (amount === null || amount === undefined) return '—';
  if (currency === 'LKR') return `Rs. ${Number(amount).toLocaleString()}`;
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(amount);
}

export function statusBadge(status) {
  const map = {
    ACTIVE: { cls: 'badge-success', label: 'Active' },
    TRIAL: { cls: 'badge-warning', label: 'Trial' },
    SUSPENDED: { cls: 'badge-danger', label: 'Suspended' },
    OFFLINE: { cls: 'badge-info', label: 'Offline' },
    EXPIRED: { cls: 'badge-secondary', label: 'Expired' },
  };
  const b = map[String(status).toUpperCase()] || { cls: 'badge-secondary', label: status };
  return `<span class="badge ${b.cls}">${b.label}</span>`;
}

export function planBadge(planName) {
  const name = String(planName ?? 'Trial');
  const cls = name.toLowerCase().includes('year') ? 'badge-purple'
    : name.toLowerCase().includes('6') ? 'badge-blue'
    : name.toLowerCase().includes('month') ? 'badge-teal'
    : name.toLowerCase().includes('trial') ? 'badge-warning'
    : name.toLowerCase().includes('offline') ? 'badge-info'
    : name.toLowerCase().includes('free') ? 'badge-secondary'
    : 'badge-primary';
  return `<span class="badge ${cls}">${escHtml(name)}</span>`;
}

export function roleBadge(role) {
  const map = {
    platform_admin: { cls: 'badge-purple', label: 'Platform Admin' },
    owner: { cls: 'badge-blue', label: 'Owner' },
    admin: { cls: 'badge-teal', label: 'Admin' },
    manager: { cls: 'badge-warning', label: 'Manager' },
    cashier: { cls: 'badge-secondary', label: 'Cashier' },
  };
  const b = map[role] || { cls: 'badge-secondary', label: role };
  return `<span class="badge ${b.cls}">${b.label}</span>`;
}

export function escHtml(str) {
  return String(str ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

export function copyToClipboard(text) {
  navigator.clipboard.writeText(text).catch(() => {
    const ta = document.createElement('textarea');
    ta.value = text;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  });
}

export function daysUntil(dateStr) {
  if (!dateStr) return null;
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return null;
  const diff = Math.ceil((d - new Date()) / (1000 * 60 * 60 * 24));
  return diff;
}

export function formatExpiry(dateStr) {
  const days = daysUntil(dateStr);
  if (days === null) return '<span class="text-muted">Never</span>';
  if (days < 0) return `<span class="text-danger">Expired ${Math.abs(days)}d ago</span>`;
  if (days <= 7) return `<span class="text-warning">${days}d left</span>`;
  return `<span>${formatDate(dateStr)}</span>`;
}
