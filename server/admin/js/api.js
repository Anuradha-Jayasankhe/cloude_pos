/**
 * StoreBuddy Admin — API Client
 * Wraps all fetch calls with JWT auth, error handling, and toast notifications.
 */

const API_BASE = '/api/v1';

function getToken() {
  return localStorage.getItem('sb_admin_token');
}

async function request(method, path, body = null, options = {}) {
  const token = getToken();
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const fetchOptions = { method, headers, ...options };
  if (body !== null) fetchOptions.body = JSON.stringify(body);

  const res = await fetch(`${API_BASE}${path}`, fetchOptions);

  if (res.status === 401) {
    localStorage.removeItem('sb_admin_token');
    localStorage.removeItem('sb_admin_user');
    window.location.hash = '#/login';
    throw new Error('Session expired. Please log in again.');
  }

  if (res.status === 204) return null;

  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    throw new Error(data.detail || data.message || `HTTP ${res.status}`);
  }

  return data;
}

export const api = {
  get: (path) => request('GET', path),
  post: (path, body) => request('POST', path, body),
  patch: (path, body) => request('PATCH', path, body),
  delete: (path) => request('DELETE', path),

  // Auth
  login: (email, password) =>
    request('POST', '/auth/login', { email, password }),

  // Stats
  getStats: () => request('GET', '/admin/stats'),

  // Plans
  getPlans: () => request('GET', '/admin/plans'),
  createPlan: (data) => request('POST', '/admin/plans', data),
  updatePlan: (planId, data) => request('PATCH', `/admin/plans/${planId}`, data),
  deletePlan: (planId) => request('DELETE', `/admin/plans/${planId}`),

  // Tenants
  getTenants: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request('GET', `/admin/tenants${qs ? '?' + qs : ''}`);
  },
  getTenant: (tenantId) => request('GET', `/admin/tenants/${tenantId}`),
  createTenant: (data) => request('POST', '/admin/tenants', data),
  updateTenant: (tenantId, data) => request('PATCH', `/admin/tenants/${tenantId}`, data),
  assignPlan: (tenantId, data) => request('POST', `/admin/tenants/${tenantId}/assign-plan`, data),
  generateOfflineKey: (tenantId, data) =>
    request('POST', `/admin/tenants/${tenantId}/generate-offline-key`, data),
  suspendTenant: (tenantId) => request('POST', `/admin/tenants/${tenantId}/suspend`),
  activateTenant: (tenantId, data) => request('POST', `/admin/tenants/${tenantId}/activate`, data),
  convertToOnline: (tenantId, data) => request('POST', `/admin/tenants/${tenantId}/convert-to-online`, data),
  convertToOffline: (tenantId, data = {}) => request('POST', `/admin/tenants/${tenantId}/convert-to-offline`, data),
  deleteTenant: (tenantId) => request('DELETE', `/admin/tenants/${tenantId}`),

  // Platform Settings
  getSettings: () => request('GET', '/admin/settings'),
  updateSettings: (data) => request('PUT', '/admin/settings', data),

  // Users
  getUsers: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request('GET', `/admin/users${qs ? '?' + qs : ''}`);
  },
  createUser: (data) => request('POST', '/auth/users', data),

  // Activity
  getActivity: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request('GET', `/admin/activity${qs ? '?' + qs : ''}`);
  },

  // Releases
  getReleases: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request('GET', `/admin/releases${qs ? '?' + qs : ''}`);
  },
  createRelease: (data) => request('POST', '/admin/releases', data),
  updateRelease: (id, data) => request('PATCH', `/admin/releases/${id}`, data),
  deleteRelease: (id) => request('DELETE', `/admin/releases/${id}`),

  // QR Payments
  getQrPayments: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request('GET', `/admin/qr-payments${qs ? '?' + qs : ''}`);
  },

  // Documentation
  getDocs: () => request('GET', '/admin/docs'),
  createDoc: (data) => request('POST', '/admin/docs', data),
  updateDoc: (id, data) => request('PATCH', `/admin/docs/${id}`, data),
  deleteDoc: (id) => request('DELETE', `/admin/docs/${id}`),

  // Tutorials
  getTutorials: () => request('GET', '/admin/tutorials'),
  createTutorial: (data) => request('POST', '/admin/tutorials', data),
  updateTutorial: (id, data) => request('PATCH', `/admin/tutorials/${id}`, data),
  deleteTutorial: (id) => request('DELETE', `/admin/tutorials/${id}`),
};
