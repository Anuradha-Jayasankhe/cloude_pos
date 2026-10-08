/**
 * StoreBuddy Cloud Website - Main Application Controller (ES Module)
 */

import { fetchReleases, formatDate } from './api.js';

// Application State
let activePlatform = 'windows';
let cachedReleases = [];
let activeGuideStep = 1;

// User Guide Steps Data
const USER_GUIDE_STEPS = [
  {
    stepNumber: 1,
    title: 'Download & Install',
    subtitle: 'Get StoreBuddy POS on your desktop terminal or Android device',
    icon: '📥',
    badge: 'Step 1 • 1 Minute',
    description: 'Download the official installer for your operating system. StoreBuddy runs natively on Windows 10/11 and Android 8.0+ tablets and smartphones.',
    bullets: [
      'Windows: Run StoreBuddy_POS_Setup_x64.exe and follow the wizard.',
      'Android: Open the .apk file on your phone or POS terminal to install.',
      'No complex prerequisites or third-party database engines needed.',
      'Auto-creates desktop shortcuts and registers offline SQLite database.'
    ],
    codeSnippet: '# Windows Quick Silent Install (Powershell Admin)\nStart-Process -FilePath ".\\StoreBuddy_POS_Setup_x64.exe" -ArgumentList "/S" -Wait'
  },
  {
    stepNumber: 2,
    title: 'Store Onboarding & Currency',
    subtitle: 'Configure your company details, currency, and cashier accounts',
    icon: '🏪',
    badge: 'Step 2 • 2 Minutes',
    description: 'Launch StoreBuddy and complete the 30-second initial setup. Enter your store name, address, currency symbol (e.g. LKR, USD), and cashier pin code.',
    bullets: [
      'Open Settings > Company & Store to set your business name and logo.',
      'Open Store Operations to configure opening/closing hours and accepted payments.',
      'Create cashier logins with individual role permissions and security pins.',
      'Choose whether to run in Cloud Sync mode or Standalone Local mode.'
    ]
  },
  {
    stepNumber: 3,
    title: 'Hardware & Thermal Printer Setup',
    subtitle: 'Connect receipt printers, barcode scanners, and cash drawers',
    icon: '🖨️',
    badge: 'Step 3 • 2 Minutes',
    description: 'StoreBuddy includes built-in driverless ESC/POS hardware support. Connect your receipt printer via USB, Ethernet (LAN), or Bluetooth without installing bloated drivers.',
    bullets: [
      'Open Settings > Receipt & Printing to scan for local system printers.',
      'Select 80mm or 58mm thermal paper roll size.',
      'Configure Cash Drawer kick (Pin 2 or Pin 5) and click "Test Open Drawer".',
      'Plug in any standard USB or Bluetooth barcode scanner (auto-detects).'
    ],
    codeSnippet: '# ESC/POS Cash Drawer Kick Command\nPin: 0 (Pin 2 standard RJ11) | Pulse: 120ms ON, 240ms OFF'
  },
  {
    stepNumber: 4,
    title: 'Add Products & First Sale',
    subtitle: 'Scan your first barcode and ring up customers in under 3 seconds',
    icon: '⚡',
    badge: 'Step 4 • Instant',
    description: 'You are ready to sell! Open Point of Sale, scan product barcodes, choose Cash, Card, or Cash on Delivery (COD), and watch the receipt print automatically.',
    bullets: [
      'Scan barcodes directly into the cart or use the visual touch grid.',
      'Apply item discounts, line notes, or select Cash on Delivery (COD).',
      'Collect payment — cash drawer kicks open and thermal receipt prints instantly.',
      'Sales are automatically tracked in local SQLite and synced to the cloud.'
    ]
  }
];

// Core Features Data
const FEATURES = [
  {
    id: 'offline-sync',
    icon: '⚡',
    title: 'Offline-First Resilience',
    tag: 'Zero Downtime',
    summary: 'Never stop selling when the internet cuts out. High-speed local SQLite ensures zero latency during rush hours, auto-syncing when back online.',
    highlights: ['100% offline transactions', 'Automatic cloud sync queue', 'Conflict-free data resolution']
  },
  {
    id: 'hardware-printing',
    icon: '🖨️',
    title: 'Hardware & Printing Engine',
    tag: '58mm / 80mm / A4',
    summary: 'Advanced driverless ESC/POS receipt generation, cash drawer solenoid kick, and high-volume barcode label printing for Zebra and Dymo.',
    highlights: ['USB, LAN/Network & Bluetooth', 'Automated cash drawer pulse', 'A4 invoice sheets & label rolls']
  },
  {
    id: 'cod-delivery',
    icon: '🚚',
    title: 'COD & Delivery Management',
    tag: 'Courier Ready',
    summary: 'Specialized Cash on Delivery workflow. Auto-fills courier fees in cart, tracks dispatched parcels, and guarantees Rs. 0.00 zero-cash returns.',
    highlights: ['Customizable delivery charges', 'Delivery note generation', 'Safe unpaid order cancellations']
  },
  {
    id: 'mobile-shop',
    icon: '📱',
    title: 'Electronics & Mobile Shop Tools',
    tag: 'IMEI Serialization',
    summary: 'Designed for smartphone and electronics retailers. Track unique IMEI/serial numbers from purchase to checkout with barcode label printing.',
    highlights: ['IMEI/Serial lookup at checkout', 'Individual IMEI barcode labels', 'Warranty validity tracking']
  },
  {
    id: 'telecom-reload',
    icon: '📶',
    title: 'Telecom Mobile Reloads',
    tag: 'Dialog • Mobitel • Hutch',
    summary: 'Process mobile phone reloads and utility bill payments directly inside the POS with automated tier-based operator commission accounting.',
    highlights: ['Prepaid & postpaid reloads', 'Automated commission calculation', 'Daily reload reconciliation']
  },
  {
    id: 'multi-branch',
    icon: '🏢',
    title: 'Multi-Branch & Cloud Analytics',
    tag: 'Centralized Control',
    summary: 'Manage inventory, transfers, cashier shifts, and sales performance across all store branches in real-time from the System Admin Portal.',
    highlights: ['Inter-branch stock transfers', 'Statutory EPF/ETF payroll reports', 'Centralized web management']
  }
];

// FAQ Data
const FAQS = [
  {
    category: 'General',
    question: 'Can StoreBuddy POS operate completely without an internet connection?',
    answer: 'Yes, absolutely! StoreBuddy POS uses an embedded high-performance local database on every terminal. You can process sales, print receipts, scan barcodes, and manage customer orders 100% offline. Once an internet connection is available, all transactions synchronize seamlessly to your central cloud database.'
  },
  {
    category: 'Hardware',
    question: 'What thermal receipt printers and cash drawers are supported?',
    answer: 'StoreBuddy supports all standard ESC/POS thermal printers connected via USB, Network (Ethernet IP), or Bluetooth, including 58mm and 80mm roll sizes. Cash drawers connecting through standard RJ11/RJ12 printer kick ports (Pin 2 and Pin 5) fire automatically on cash transactions.'
  },
  {
    category: 'Updates',
    question: 'How do software updates work when a new release is posted?',
    answer: 'When a new version is published in the System Admin Portal, the POS terminal alerts you to the update. You can download the latest installer or APK directly from this website or let the desktop app update in place.'
  },
  {
    category: 'Billing',
    question: 'Can I track IMEI and Serial numbers for mobile phone sales?',
    answer: 'Yes! StoreBuddy POS has a dedicated Mobile Shop Mode. When selling serialized items, you can scan or select specific IMEI numbers. The serial number prints directly on the customer warranty receipt.'
  }
];

/**
 * Initialize Application
 */
document.addEventListener('DOMContentLoaded', async () => {
  setupThemeToggle();
  setupNavScroll();
  renderFeatures();
  renderUserGuide();
  renderFaqs();
  setupTerminalDemo();
  await loadAndRenderDownloads();
});

/**
 * Setup Theme Toggle (Dark / Light)
 */
function setupThemeToggle() {
  const toggleBtn = document.getElementById('themeToggleBtn');
  if (!toggleBtn) return;

  const currentTheme = localStorage.getItem('sb_theme') || 'dark';
  document.documentElement.setAttribute('data-theme', currentTheme);
  updateThemeIcon(currentTheme);

  toggleBtn.addEventListener('click', () => {
    const active = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', active);
    localStorage.setItem('sb_theme', active);
    updateThemeIcon(active);
  });
}

function updateThemeIcon(theme) {
  const iconEl = document.getElementById('themeToggleIcon');
  if (iconEl) {
    iconEl.textContent = theme === 'light' ? '🌙' : '☀️';
  }
}

/**
 * Smooth Navigation Scroll
 */
function setupNavScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
      const href = anchor.getAttribute('href');
      if (!href || href === '#') return;
      const target = document.querySelector(href);
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });
}

/**
 * Load and Render Downloads (Spotlight Newest on Top, Archive Below)
 */
async function loadAndRenderDownloads() {
  const container = document.getElementById('downloadsContainer');
  if (!container) return;

  // Platform Tabs Click Handler
  const winTab = document.getElementById('tabWin');
  const andTab = document.getElementById('tabAndroid');

  if (winTab && andTab) {
    winTab.addEventListener('click', () => {
      activePlatform = 'windows';
      winTab.classList.add('active');
      andTab.classList.remove('active');
      renderDownloads();
    });

    andTab.addEventListener('click', () => {
      activePlatform = 'android';
      andTab.classList.add('active');
      winTab.classList.remove('active');
      renderDownloads();
    });
  }

  // Fetch from API
  container.innerHTML = `
    <div class="loading-spinner-container">
      <div class="glow-spinner"></div>
      <p class="text-muted">Fetching live software releases from StoreBuddy Cloud...</p>
    </div>
  `;

  cachedReleases = await fetchReleases();
  renderDownloads();
}

/**
 * Render Downloads Section
 */
function renderDownloads() {
  const container = document.getElementById('downloadsContainer');
  if (!container) return;

  // Filter releases for current platform
  const filtered = cachedReleases.filter(r => r.platform === activePlatform);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="empty-releases-card">
        <div class="empty-icon">🚀</div>
        <h3>No published releases yet for ${activePlatform === 'windows' ? 'Windows' : 'Android'}</h3>
        <p>New releases can be added directly via the <a href="/admin" target="_blank">System Admin Portal</a>.</p>
      </div>
    `;
    return;
  }

  // Newest version is the first element
  const latest = filtered[0];
  // Older versions are the remaining elements
  const older = filtered.slice(1);

  const platformLabel = activePlatform === 'windows' ? 'Windows Desktop (x64)' : 'Android Mobile (APK)';
  const platformIcon = activePlatform === 'windows' ? '🪟' : '🤖';
  const fileExt = activePlatform === 'windows' ? '.exe' : '.apk';

  // Format release notes into list items
  const notesHtml = latest.release_notes
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.length > 0)
    .map(line => `<li><span class="bullet-check">✓</span> ${escapeHtml(line.replace(/^[•\-\*]\s*/, ''))}</li>`)
    .join('');

  container.innerHTML = `
    <!-- Top Spotlight Card (Newest Version) -->
    <div class="latest-spotlight-card">
      <div class="spotlight-badge-row">
        <span class="spotlight-glow-tag">🔥 LATEST STABLE RELEASE</span>
        <span class="platform-chip">${platformIcon} ${platformLabel}</span>
        <span class="channel-chip">${latest.channel.toUpperCase()}</span>
      </div>

      <div class="spotlight-content-grid">
        <div class="spotlight-info">
          <div class="version-hero-title">
            <h2>StoreBuddy POS <span class="gradient-text">v${latest.version}</span></h2>
            <span class="release-date-badge">Released on ${formatDate(latest.release_date)}</span>
          </div>
          
          <p class="spotlight-description">
            Production-grade release optimized for rapid checkout, barcode printing, ESC/POS hardware integration, and multi-branch cloud synchronization.
          </p>

          <div class="specs-pill-group">
            <span class="spec-pill">📦 ${latest.file_size || (activePlatform === 'windows' ? '~88 MB' : '~42 MB')}</span>
            <span class="spec-pill">🔒 SHA256 Verified</span>
            <span class="spec-pill">🛡️ Zero Virus / Malware</span>
            <span class="spec-pill">⚡ Direct Fast CDN</span>
          </div>

          <div class="spotlight-action-row">
            <a href="${latest.download_url}" class="btn btn-primary btn-lg download-glow-btn" download>
              <span class="btn-icon">⬇️</span>
              <span class="btn-text-group">
                <span class="btn-title">Download v${latest.version} for ${activePlatform === 'windows' ? 'Windows' : 'Android'}</span>
                <span class="btn-subtitle">Direct installer (${fileExt})</span>
              </span>
            </a>

            <button class="btn btn-secondary btn-copy" onclick="window.sbCopyLink('${latest.download_url}')" title="Copy Download Link">
              📋 Copy Link
            </button>
          </div>
        </div>

        <div class="spotlight-changelog-card">
          <div class="changelog-header">
            <h4>What's New in v${latest.version}</h4>
            <span class="badge-accent">Highlights</span>
          </div>
          <ul class="changelog-list">
            ${notesHtml || '<li>Performance enhancements and stability updates.</li>'}
          </ul>
        </div>
      </div>
    </div>

    <!-- Previous Versions & Changelog History -->
    <div class="previous-releases-section">
      <div class="section-subhead-row">
        <div>
          <h3 class="subhead-title">Previous Versions & History</h3>
          <p class="text-muted">Chronological archive of prior releases and changelogs</p>
        </div>
        <span class="archive-count-badge">${older.length} Previous Releases</span>
      </div>

      ${older.length === 0 ? `
        <div class="no-prior-card">
          <p class="text-muted">v${latest.version} is currently the initial published release for this platform.</p>
        </div>
      ` : `
        <div class="history-accordion-container">
          ${older.map((r, index) => renderHistoryCard(r, index)).join('')}
        </div>
      `}
    </div>

    <!-- Admin Release System Callout -->
    <div class="admin-sync-banner">
      <div class="banner-icon">🔄</div>
      <div class="banner-text">
        <strong>Live Admin Portal Sync:</strong> This page dynamically updates whenever a platform administrator posts or updates a software release in the <a href="/admin" target="_blank">System Admin Portal</a>.
      </div>
      <a href="/admin" target="_blank" class="btn btn-sm btn-ghost">Open Admin Portal →</a>
    </div>
  `;
}

function renderHistoryCard(release, index) {
  const notesHtml = release.release_notes
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.length > 0)
    .map(line => `<li><span class="bullet-dot">•</span> ${escapeHtml(line.replace(/^[•\-\*]\s*/, ''))}</li>`)
    .join('');

  return `
    <div class="history-item-card" id="history-item-${index}">
      <div class="history-header" onclick="window.sbToggleAccordion(${index})">
        <div class="history-title-group">
          <span class="history-version">v${release.version}</span>
          <span class="history-date">${formatDate(release.release_date)}</span>
          <span class="history-channel-tag">${release.channel}</span>
        </div>
        <div class="history-actions">
          <a href="${release.download_url}" class="btn btn-sm btn-outline" download onclick="event.stopPropagation()">
            ⬇️ Download
          </a>
          <span class="accordion-arrow" id="arrow-${index}">▼</span>
        </div>
      </div>
      <div class="history-body" id="body-${index}">
        <div class="history-notes-box">
          <h5>Release Changelog:</h5>
          <ul class="history-notes-list">
            ${notesHtml || '<li>Maintenance and bugfix release.</li>'}
          </ul>
        </div>
      </div>
    </div>
  `;
}

// Global window helpers for inline onclicks
window.sbCopyLink = (url) => {
  if (!url) return;
  navigator.clipboard.writeText(url).then(() => {
    showToast('Download link copied to clipboard!');
  }).catch(() => {
    prompt('Copy this download link:', url);
  });
};

window.sbToggleAccordion = (index) => {
  const body = document.getElementById(`body-${index}`);
  const arrow = document.getElementById(`arrow-${index}`);
  if (!body || !arrow) return;

  const isOpen = body.classList.contains('open');
  if (isOpen) {
    body.classList.remove('open');
    arrow.textContent = '▼';
  } else {
    body.classList.add('open');
    arrow.textContent = '▲';
  }
};

/**
 * Render Features Grid
 */
function renderFeatures() {
  const container = document.getElementById('featuresGrid');
  if (!container) return;

  container.innerHTML = FEATURES.map(f => `
    <div class="feature-card">
      <div class="feature-icon-wrapper">
        <span class="feature-emoji">${f.icon}</span>
        <span class="feature-tag">${f.tag}</span>
      </div>
      <h3 class="feature-title">${f.title}</h3>
      <p class="feature-summary">${f.summary}</p>
      <ul class="feature-highlights">
        ${f.highlights.map(h => `<li><span class="highlight-bullet">✦</span> ${h}</li>`).join('')}
      </ul>
    </div>
  `).join('');
}

/**
 * Render Interactive User Guide
 */
function renderUserGuide() {
  const tabContainer = document.getElementById('guideStepTabs');
  const displayContainer = document.getElementById('guideStepDisplay');
  if (!tabContainer || !displayContainer) return;

  // Render Tabs
  tabContainer.innerHTML = USER_GUIDE_STEPS.map(s => `
    <button class="guide-nav-tab ${s.stepNumber === activeGuideStep ? 'active' : ''}" onclick="window.sbSelectGuideStep(${s.stepNumber})">
      <span class="guide-tab-icon">${s.icon}</span>
      <span class="guide-tab-labels">
        <span class="guide-tab-step">STEP ${s.stepNumber}</span>
        <span class="guide-tab-title">${s.title}</span>
      </span>
    </button>
  `).join('');

  // Render Active Step Content
  const step = USER_GUIDE_STEPS.find(s => s.stepNumber === activeGuideStep) || USER_GUIDE_STEPS[0];

  displayContainer.innerHTML = `
    <div class="guide-display-card">
      <div class="guide-card-header">
        <div class="guide-badge-pill">${step.badge}</div>
        <h3 class="guide-card-title">${step.icon} ${step.title}</h3>
        <p class="guide-card-sub">${step.subtitle}</p>
      </div>

      <p class="guide-card-desc">${step.description}</p>

      <div class="guide-checklist-box">
        <h4>Setup Checklist:</h4>
        <ul class="guide-checklist">
          ${step.bullets.map(b => `<li><span class="check-box-icon">☑</span> <span>${escapeHtml(b)}</span></li>`).join('')}
        </ul>
      </div>

      ${step.codeSnippet ? `
        <div class="guide-code-box">
          <div class="code-header">
            <span>Terminal / Configuration Reference</span>
            <button class="btn-copy-code" onclick="window.sbCopyLink(\`${step.codeSnippet.replace(/`/g, '\\`')}\`)">Copy</button>
          </div>
          <pre><code>${escapeHtml(step.codeSnippet)}</code></pre>
        </div>
      ` : ''}

      <div class="guide-nav-footer">
        <button class="btn btn-ghost" ${step.stepNumber === 1 ? 'disabled' : ''} onclick="window.sbSelectGuideStep(${step.stepNumber - 1})">
          ← Previous Step
        </button>
        <div class="step-indicator-dots">
          ${USER_GUIDE_STEPS.map(s => `<span class="dot ${s.stepNumber === activeGuideStep ? 'active' : ''}"></span>`).join('')}
        </div>
        <button class="btn btn-primary" ${step.stepNumber === USER_GUIDE_STEPS.length ? 'disabled' : ''} onclick="window.sbSelectGuideStep(${step.stepNumber + 1})">
          Next Step →
        </button>
      </div>
    </div>
  `;
}

window.sbSelectGuideStep = (stepNumber) => {
  if (stepNumber < 1 || stepNumber > USER_GUIDE_STEPS.length) return;
  activeGuideStep = stepNumber;
  renderUserGuide();
};

/**
 * Render FAQ Accordion
 */
function renderFaqs() {
  const container = document.getElementById('faqContainer');
  if (!container) return;

  container.innerHTML = FAQS.map((faq, index) => `
    <div class="faq-item" onclick="window.sbToggleFaq(${index})">
      <div class="faq-question">
        <span>${faq.question}</span>
        <span class="faq-toggle-icon" id="faq-icon-${index}">+</span>
      </div>
      <div class="faq-answer" id="faq-ans-${index}">
        <p>${faq.answer}</p>
      </div>
    </div>
  `).join('');
}

window.sbToggleFaq = (index) => {
  const ans = document.getElementById(`faq-ans-${index}`);
  const icon = document.getElementById(`faq-icon-${index}`);
  if (!ans || !icon) return;

  const isOpen = ans.classList.contains('open');
  if (isOpen) {
    ans.classList.remove('open');
    icon.textContent = '+';
  } else {
    ans.classList.add('open');
    icon.textContent = '−';
  }
};

/**
 * Live Terminal UI Mockup Animation
 */
function setupTerminalDemo() {
  const totalAmountEl = document.getElementById('demoTotalAmount');
  if (!totalAmountEl) return;

  const amounts = ['3,850.00', '4,200.00', '1,750.00', '5,100.00'];
  let idx = 0;
  setInterval(() => {
    idx = (idx + 1) % amounts.length;
    totalAmountEl.textContent = `Rs. ${amounts[idx]}`;
  }, 4000);
}

/**
 * Simple Toast Notification
 */
function showToast(message) {
  let toast = document.getElementById('sbToast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'sbToast';
    toast.className = 'sb-toast';
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => {
    toast?.classList.remove('show');
  }, 2600);
}

function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
