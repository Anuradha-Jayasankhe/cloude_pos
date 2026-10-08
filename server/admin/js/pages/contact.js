/**
 * StoreBuddy Admin — Contact Page
 */
import { showToast } from '../app.js';

export async function renderContact(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Contact Us</h1>
        <p class="page-subtitle">Get in touch with StoreBuddy developers, sales managers, or business partners.</p>
      </div>
    </div>

    <div class="dashboard-grid" style="grid-template-columns: 1fr 400px; gap: 24px;">
      
      <!-- Left: Inquiries Contact Form -->
      <div class="card">
        <h3 style="font-size: 16px; font-weight: 700; color: var(--text); margin-bottom: 6px;">Send us a message</h3>
        <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 20px;">Have questions about pricing, customized plans, or feature requests? Send us an inquiry.</p>
        
        <form class="form-grid" id="contactInquiryForm">
          <div class="form-group">
            <label>Full Name *</label>
            <input type="text" name="name" class="form-control" placeholder="Enter your name" required />
          </div>

          <div class="form-group">
            <label>Business Email *</label>
            <input type="email" name="email" class="form-control" placeholder="Enter business email" required />
          </div>

          <div class="form-group">
            <label>Subject</label>
            <select name="subject" class="form-control">
              <option value="SALES" selected>Sales & Custom Pricing</option>
              <option value="PARTNERSHIP">Partnership / Reseller Program</option>
              <option value="CAREERS">Careers & Jobs</option>
              <option value="OTHER">Other / Feedback</option>
            </select>
          </div>

          <div class="form-group" style="margin-bottom: 16px;">
            <label>Message *</label>
            <textarea name="message" class="form-control" style="height: 120px;" placeholder="Write your message details..." required></textarea>
          </div>

          <button class="btn btn-primary" type="submit" style="background-color: #5b21b6; align-self: flex-start; padding: 10px 24px;">✉️ Send Message</button>
        </form>
      </div>

      <!-- Right: Office Address & Contacts -->
      <div style="display: flex; flex-direction: column; gap: 20px;">
        
        <!-- Office Location Card -->
        <div class="card">
          <h3 style="font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 12px;">Head Office</h3>
          <p style="font-size: 13px; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            🏢 <strong>StoreBuddy Tech Labs</strong><br/>
            45, Galle Road, Colombo 03,<br/>
            Sri Lanka.
          </p>
          <div style="display: flex; flex-direction: column; gap: 10px; font-size: 13px;">
            <div style="display: flex; gap: 8px; align-items: center;">
              <span>📞</span>
              <strong>General:</strong> <a href="tel:+94729545538" style="color: var(--brand-purple-light);">+94 72 954 5538</a>
            </div>
            <div style="display: flex; gap: 8px; align-items: center;">
              <span>✉️</span>
              <strong>Sales:</strong> <a href="mailto:contact@bizparkstudio.lk" style="color: var(--brand-purple-light);">contact@bizparkstudio.lk</a>
            </div>
          </div>
        </div>

        <!-- Social Media Card -->
        <div class="card">
          <h3 style="font-size: 15px; font-weight: 700; color: var(--text); margin-bottom: 12px;">Follow Us</h3>
          <p style="font-size: 13px; color: var(--text-muted); line-height: 1.6; margin-bottom: 12px;">
            Stay updated with releases and POS client version releases on our social feeds:
          </p>
          <div style="display: flex; gap: 12px; font-size: 14px;">
            <a href="https://linkedin.com" target="_blank" style="color: var(--brand-purple-light); font-weight: 600;">LinkedIn</a>
            <a href="https://twitter.com" target="_blank" style="color: var(--brand-purple-light); font-weight: 600;">Twitter</a>
            <a href="https://facebook.com" target="_blank" style="color: var(--brand-purple-light); font-weight: 600;">Facebook</a>
          </div>
        </div>

      </div>

    </div>
  `;

  document.getElementById('contactInquiryForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const form = e.target;
    form.reset();
    showToast('Inquiry sent successfully! We will contact you soon.', 'success');
  });
}
