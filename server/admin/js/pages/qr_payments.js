/**
 * StoreBuddy Admin — QR Payments Page
 */
import { api } from '../api.js';
import { escHtml, formatDateTime } from '../utils.js';

export async function renderQrPayments(container) {
  container.innerHTML = `
    <div class="page-header">
      <div>
        <h1 class="page-title">Platform QR Payments</h1>
        <p class="page-subtitle">Track all QR payment sessions created across shops, including status, references, and provider details.</p>
      </div>
    </div>

    <!-- QR Stats Grid -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon stat-icon--purple">📱</div>
        <div>
          <div class="stat-value" id="qrSessionsCount">0</div>
          <div class="stat-label">Sessions</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--blue">💳</div>
        <div>
          <div class="stat-value" id="qrTotalAmount">Rs 0.00</div>
          <div class="stat-label">Total Amount</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon--green">✅</div>
        <div>
          <div class="stat-value" id="qrPaidAmount">Rs 0.00</div>
          <div class="stat-label">Paid Amount</div>
        </div>
      </div>
    </div>

    <!-- Filter Pills -->
    <div class="filters-bar" style="margin-bottom: 24px;">
      <div class="filter-tabs" id="qrStatusFilters">
        <button class="filter-tab active" data-status="ALL">All Sessions</button>
        <button class="filter-tab" data-status="PAID">Paid <span id="badgePaid">0</span></button>
        <button class="filter-tab" data-status="PENDING">Pending <span id="badgePending">0</span></button>
        <button class="filter-tab" data-status="FAILED">Failed <span id="badgeFailed">0</span></button>
        <button class="filter-tab" data-status="EXPIRED">Expired <span id="badgeExpired">0</span></button>
        <button class="filter-tab" data-status="CANCELLED">Cancelled <span id="badgeCancelled">0</span></button>
      </div>
    </div>

    <!-- Transactions List -->
    <div id="qrListContainer">
      <div class="table-loading"><div class="loading-spinner"></div></div>
    </div>
  `;

  let activeStatus = 'ALL';

  // Attach status tab handlers
  const filterTabs = document.getElementById('qrStatusFilters').querySelectorAll('.filter-tab');
  filterTabs.forEach(tab => {
    tab.addEventListener('click', (e) => {
      filterTabs.forEach(t => t.classList.remove('active'));
      const target = e.currentTarget;
      target.classList.add('active');
      activeStatus = target.getAttribute('data-status');
      loadPayments();
    });
  });

  await loadPayments();

  async function loadPayments() {
    const listContainer = document.getElementById('qrListContainer');
    listContainer.innerHTML = '<div class="table-loading"><div class="loading-spinner"></div></div>';

    try {
      const params = {};
      if (activeStatus !== 'ALL') {
        params.status = activeStatus;
      }
      const data = await api.getQrPayments(params);

      // Update counters & metrics
      document.getElementById('qrSessionsCount').textContent = data.total;
      document.getElementById('qrTotalAmount').textContent = `Rs ${Number(data.total_amount).toFixed(2)}`;
      document.getElementById('qrPaidAmount').textContent = `Rs ${Number(data.paid_amount).toFixed(2)}`;

      // Load all counts to update badges (only once, or pull all to count locally)
      const allData = await api.getQrPayments({ status: 'ALL' });
      const counts = { PAID: 0, PENDING: 0, FAILED: 0, EXPIRED: 0, CANCELLED: 0 };
      allData.payments.forEach(p => {
        if (counts[p.status] !== undefined) counts[p.status]++;
      });

      document.getElementById('badgePaid').textContent = counts.PAID;
      document.getElementById('badgePending').textContent = counts.PENDING;
      document.getElementById('badgeFailed').textContent = counts.FAILED;
      document.getElementById('badgeExpired').textContent = counts.EXPIRED;
      document.getElementById('badgeCancelled').textContent = counts.CANCELLED;

      renderPaymentsList(listContainer, data.payments);
    } catch (e) {
      listContainer.innerHTML = `<div class="error-state">${escHtml(e.message)}</div>`;
    }
  }

  function renderPaymentsList(el, payments) {
    if (!payments.length) {
      el.innerHTML = '<div class="empty-state"><div class="empty-icon">💳</div><p>No QR payment sessions found</p></div>';
      return;
    }

    el.innerHTML = `
      <div class="qr-payments-list">
        ${payments.map(p => {
          let statusColor = '#f59e0b'; // pending
          if (p.status === 'PAID') statusColor = '#10b981';
          if (p.status === 'FAILED') statusColor = '#ef4444';
          if (p.status === 'EXPIRED') statusColor = '#6b7280';
          if (p.status === 'CANCELLED') statusColor = '#ef4444';

          const isStatusPending = p.status === 'PENDING';

          return `
            <div class="qr-payment-card card" style="margin-bottom: 16px;">
              <div class="qr-payment-card-header" style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px;">
                <div>
                  <h3 class="qr-store-name" style="font-size: 18px; font-weight: 700; color: var(--text); margin-bottom: 4px;">${escHtml(p.store_name)}</h3>
                  <div style="display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
                    <span class="badge" style="background-color: #f3f4f6; border-color: #e5e7eb; color: #4b5563;">${escHtml(p.payment_method)}</span>
                    <span class="badge" style="background-color: ${statusColor}1a; border-color: ${statusColor}40; color: ${statusColor};">${escHtml(p.status)}</span>
                    <span class="badge" style="background-color: #f3f4f6; border-color: #e5e7eb; color: #4b5563; font-family: monospace; font-size: 11px;">${escHtml(p.order_id)}</span>
                  </div>
                </div>
                <div class="qr-amount" style="font-size: 22px; font-weight: 800; color: ${p.status === 'PAID' ? 'var(--success)' : 'var(--warning)'};">
                  Rs ${Number(p.amount).toFixed(2)}
                </div>
              </div>
              <div class="qr-customer-info" style="font-size: 13px; color: var(--text-muted); margin-bottom: 8px;">
                ${escHtml(p.customer_type)}
              </div>
              <div class="qr-references-line" style="font-size: 11px; color: var(--text-light); line-height: 1.6; font-family: monospace; word-break: break-all;">
                <strong>Reference:</strong> ${escHtml(p.reference)} &nbsp;|&nbsp; 
                <strong>QR Reference:</strong> ${escHtml(p.qr_reference)} &nbsp;|&nbsp; 
                <strong>Sale ID:</strong> ${escHtml(p.sale_id)} &nbsp;|&nbsp; 
                <strong>Method:</strong> ${escHtml(p.method)} &nbsp;|&nbsp; 
                <strong>Created:</strong> ${formatDateTime(p.created_at)}
              </div>
              <div class="qr-status-msg" style="font-size: 12px; font-weight: 500; margin-top: 8px; color: ${p.statusMsg === 'Success' ? 'var(--success)' : 'var(--warning)'}">
                ${escHtml(p.status_msg)}
              </div>
            </div>
          `;
        }).join('')}
      </div>
    `;
  }
}
