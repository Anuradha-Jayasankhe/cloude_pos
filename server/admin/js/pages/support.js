/**
 * StoreBuddy Admin — Customer Support Page
 */
import { escHtml } from '../utils.js';
import { showToast } from '../app.js';

export async function renderSupport(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Platform Support Desk</h1>
        <p class="page-subtitle">Submit support requests, view server status reports, and connect with tech support.</p>
      </div>
    </div>

    <!-- Quick Help Grid -->
    <div class="dashboard-grid" style="grid-template-columns: 1fr 400px; gap: 24px;">
      
      <!-- Left: Support Ticket Request Form -->
      <div class="card">
        <h3 style="font-size: 16px; font-weight: 700; color: var(--text); margin-bottom: 6px;">Submit a Ticket</h3>
        <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 20px;">Need technical help? Open a platform ticket and our support team will respond within 2 hours.</p>
        
        <form class="form-grid" id="supportTicketForm">
          <div class="form-group-2col" style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 14px;">
            <div class="form-group">
              <label>Your Name *</label>
              <input type="text" name="name" class="form-control" placeholder="Enter your full name" required />
            </div>
            <div class="form-group">
              <label>Shop Email Address *</label>
              <input type="email" name="email" class="form-control" placeholder="Enter email address" required />
            </div>
          </div>
          
          <div class="form-group-2col" style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 14px;">
            <div class="form-group">
              <label>Urgency Level</label>
              <select name="urgency" class="form-control">
                <option value="LOW">Low - General query</option>
                <option value="MEDIUM" selected>Medium - Issue impeding workflow</option>
                <option value="HIGH">High - Terminal offline / Fatal bug</option>
              </select>
            </div>
            <div class="form-group">
              <label>Affected Shop ID *</label>
              <input type="text" name="shopId" class="form-control" placeholder="e.g. dine-buddy" required />
            </div>
          </div>

          <div class="form-group" style="margin-bottom: 16px;">
            <label>Detailed Description of Issue *</label>
            <textarea name="description" class="form-control" style="height: 120px;" placeholder="Please describe what happened, any error messages displayed, and steps to reproduce..." required></textarea>
          </div>

          <button class="btn btn-primary" type="submit" style="background-color: #5b21b6; align-self: flex-start; padding: 10px 24px;">✉️ Submit Ticket</button>
        </form>
      </div>

      <!-- Right: Technical Support Info & System Status -->
      <div style="display: flex; flex-direction: column; gap: 20px;">
        
        <!-- System Health Status -->
        <div class="card" style="border-left: 4px solid var(--success);">
          <h3 style="font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 12px; display: flex; align-items: center; gap: 8px;">
            <span style="color: var(--success); font-size: 16px;">🟢</span> System Status
          </h3>
          <div style="display: flex; flex-direction: column; gap: 8px; font-size: 13px; color: var(--text-muted);">
            <div style="display: flex; justify-content: space-between;">
              <span>Database Server</span>
              <span class="badge badge-success">Online</span>
            </div>
            <div style="display: flex; justify-content: space-between;">
              <span>Cloud Sync API</span>
              <span class="badge badge-success">Operational</span>
            </div>
            <div style="display: flex; justify-content: space-between;">
              <span>License Validator</span>
              <span class="badge badge-success">Operational</span>
            </div>
          </div>
        </div>

        <!-- Support Info Card -->
        <div class="card">
          <h3 style="font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 10px;">Contact Tech Support</h3>
          <p style="font-size: 13px; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            If you have an urgent server outage, you can contact the systems administration hotline directly:
          </p>
          <div style="display: flex; flex-direction: column; gap: 10px; font-size: 13px;">
            <div style="display: flex; gap: 8px; align-items: center;">
              <span>📞</span>
              <strong>Hotline:</strong> <a href="tel:+94729545538" style="color: var(--brand-purple-light); font-weight: 600;">+94 72 954 5538</a>
            </div>
            <div style="display: flex; gap: 8px; align-items: center;">
              <span>✉️</span>
              <strong>Support Email:</strong> <a href="mailto:contact@bizparkstudio.lk" style="color: var(--brand-purple-light); font-weight: 600;">contact@bizparkstudio.lk</a>
            </div>
            <div style="display: flex; gap: 8px; align-items: center;">
              <span>⏰</span>
              <strong>Business Hours:</strong> Monday - Saturday (8:00 AM - 10:00 PM)
            </div>
          </div>
        </div>

      </div>

    </div>
  `;

  document.getElementById('supportTicketForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const form = e.target;
    form.reset();
    showToast('Support ticket submitted successfully! Check your email for confirmation.', 'success');
  });
}
