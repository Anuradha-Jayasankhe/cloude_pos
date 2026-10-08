/**
 * StoreBuddy Admin — About Page
 */
import { escHtml } from '../utils.js';
import { showToast } from '../app.js';
import { api } from '../api.js';

export async function renderAbout(container) {
  // Try to load active store information if available
  let storeInfo = {
    name: 'StoreBuddy Platform Admin',
    id: 'platform',
    deviceId: 'system-server-node',
    status: 'Activated',
  };

  try {
    const data = await api.getStats();
    // Use stats or tenant count to show platform stats
  } catch (_) {}

  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">About</h1>
        <p class="page-subtitle">Application information, software updates, and licensing details.</p>
      </div>
    </div>

    <div style="display: flex; flex-direction: column; gap: 24px; max-width: 800px;">
      
      <!-- System Info Card (Screenshot 5) -->
      <div class="card" style="display: flex; gap: 24px; align-items: center; padding: 24px;">
        <div style="width: 64px; height: 64px; border-radius: var(--radius-lg); background: linear-gradient(135deg, var(--brand-purple), var(--brand-indigo)); display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: 800; color: white; box-shadow: var(--shadow-lg);">
          SB
        </div>
        <div style="flex: 1;">
          <h2 style="font-size: 20px; font-weight: 800; color: var(--text); margin-bottom: 2px;">StoreBuddy Admin Panel</h2>
          <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 12px;">Cloud POS Platform Administration Suite</p>
          
          <div style="display: grid; grid-template-columns: 120px 1fr; gap: 8px; font-size: 13px; color: var(--text-muted);">
            <div><strong>Version</strong></div>
            <div style="color: var(--text);">v7.0.1</div>
            <div><strong>Platform</strong></div>
            <div style="color: var(--text);">WINDOWS</div>
            <div><strong>Channel</strong></div>
            <div style="color: var(--text);">Stable</div>
          </div>
        </div>
      </div>

      <!-- Updates Notification Card (Screenshot 5) -->
      <div class="card" style="padding: 24px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <h3 style="font-size: 15px; font-weight: 700; color: var(--text); display: flex; align-items: center; gap: 6px;">
            <span>🔄</span> Updates
          </h3>
          <span style="font-size: 12px; color: var(--brand-purple-light); font-weight: 600; cursor: pointer;" id="btnCheckNow">Check Now</span>
        </div>

        <!-- Available Update Banner -->
        <div style="background-color: #ecfdf5; border: 1px solid #a7f3d0; border-radius: var(--radius); padding: 16px 20px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
          <div>
            <h4 style="color: #065f46; font-size: 14px; font-weight: 700; display: flex; align-items: center; gap: 6px; margin-bottom: 2px;">
              <span>⬆️</span> v7.0.2 available
            </h4>
            <p style="color: #047857; font-size: 12px; font-weight: 500;">Bug fix for authentication and sync queue</p>
          </div>
          <button class="btn btn-success" id="btnDownloadUpdate" style="background-color: #10b981; padding: 8px 18px; font-size: 13px;">📥 Download Update</button>
        </div>
      </div>

      <!-- Restaurant/Store Licensing Details Card (Screenshot 5) -->
      <div class="card" style="padding: 24px;">
        <h3 style="font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 16px; display: flex; align-items: center; gap: 6px;">
          <span>🏪</span> Shop
        </h3>
        
        <div style="display: grid; grid-template-columns: 140px 1fr; gap: 12px; font-size: 13px; color: var(--text-muted);">
          <div>Name</div>
          <div style="color: var(--text); font-weight: 600;">${escHtml(storeInfo.name)}</div>

          <div>ID</div>
          <div style="color: var(--text); font-family: monospace;">${escHtml(storeInfo.id)}</div>

          <div>Device ID</div>
          <div style="color: var(--text); font-family: monospace;">${escHtml(storeInfo.deviceId)}</div>

          <div>Status</div>
          <div style="color: var(--success); font-weight: 700;">${escHtml(storeInfo.status)}</div>
        </div>
      </div>

    </div>
  `;

  document.getElementById('btnCheckNow').addEventListener('click', () => {
    showToast('Your software is checking for updates...', 'info');
  });

  document.getElementById('btnDownloadUpdate').addEventListener('click', () => {
    showToast('Downloading StoreBuddy v7.0.2 update...', 'success');
  });
}
