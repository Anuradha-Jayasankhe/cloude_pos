/**
 * StoreBuddy Cloud Website - Live Releases API Client
 */

import { Release, PlatformType } from './types.js';

// Fallback sample releases in case the API is offline during preview
const FALLBACK_RELEASES: Release[] = [
  {
    id: 'win-2.4.0',
    version: '2.4.0',
    platform: 'windows',
    channel: 'stable',
    download_url: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.4.0/StoreBuddy_POS_Setup_x64_v2.4.0.exe',
    release_notes: '• 4-section hardware printer engine with USB, LAN & Bluetooth support\n• Automated ESC/POS Cash Drawer kick with live solenoid test\n• Full Barcode & Label printing presets (Zebra, Dymo, A4 multi-label sheets)\n• Cash on Delivery (COD) workflows with automated shipping fee calculation\n• Zero-cash return guarantee for unpaid COD orders\n• Electronic item IMEI & Serial number tracking with barcode generation\n• Clean trilingual isolation: English, Sinhala (සිංහල), Tamil (தமிழ்)',
    release_date: '2026-09-21T10:00:00Z',
    published: true,
    file_size: '88.4 MB',
    sha256: 'a1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890'
  },
  {
    id: 'win-2.3.2',
    version: '2.3.2',
    platform: 'windows',
    channel: 'stable',
    download_url: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.3.2/StoreBuddy_POS_Setup_x64_v2.3.2.exe',
    release_notes: '• Hybrid cloud & offline SQLite sync with auto-reconnect\n• Multi-branch inventory tracking with transfer notes\n• Dynamic receipt header/footer customization\n• EPF/ETF statutory payroll default calculations\n• Enhanced touchscreen keyboard layout for POS terminals',
    release_date: '2026-08-15T10:00:00Z',
    published: true,
    file_size: '85.2 MB'
  },
  {
    id: 'win-2.2.0',
    version: '2.2.0',
    platform: 'windows',
    channel: 'stable',
    download_url: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.2.0/StoreBuddy_POS_Setup_x64_v2.2.0.exe',
    release_notes: '• Initial major release of StoreBuddy POS Windows Desktop\n• Rapid barcode scanning and cart checkout under 3 seconds\n• Multi-user cashier accounts with pin code locking\n• End-of-day Z-report generation and PDF exports',
    release_date: '2026-06-30T10:00:00Z',
    published: true,
    file_size: '81.9 MB'
  },
  {
    id: 'and-2.4.0',
    version: '2.4.0',
    platform: 'android',
    channel: 'stable',
    download_url: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.4.0/StoreBuddy_POS_Mobile_v2.4.0.apk',
    release_notes: '• Mobile handheld POS with camera barcode scanning\n• Mobile Reload Module for telecom networks (Dialog, Mobitel, Hutch, Airtel)\n• Handheld Bluetooth 58mm thermal receipt printing\n• IMEI scanner using camera OCR for mobile phone shops\n• Real-time offline order queue with cloud synchronization',
    release_date: '2026-09-21T12:00:00Z',
    published: true,
    file_size: '42.8 MB',
    sha256: '9f8e7d6c5b4a3210fedcba0987654321fedcba0987654321fedcba0987654321'
  },
  {
    id: 'and-2.2.5',
    version: '2.2.5',
    platform: 'android',
    channel: 'stable',
    download_url: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.2.5/StoreBuddy_POS_Mobile_v2.2.5.apk',
    release_notes: '• Initial Android mobile handheld companion app\n• Real-time stock lookup and price checker\n• Offline sales sync when reconnected to store Wi-Fi',
    release_date: '2026-07-20T10:00:00Z',
    published: true,
    file_size: '39.6 MB'
  }
];

export async function fetchReleases(platform?: PlatformType): Promise<Release[]> {
  try {
    const url = platform 
      ? `/api/v1/releases?platform=${encodeURIComponent(platform)}`
      : '/api/v1/releases';
    
    const response = await fetch(url, {
      headers: { 'Accept': 'application/json' },
      cache: 'no-cache'
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status} from releases API`);
    }

    const data: Release[] = await response.json();
    if (Array.isArray(data) && data.length > 0) {
      return data;
    }
    // Fallback if API returned empty array
    return filterFallback(platform);
  } catch (err) {
    console.warn('[StoreBuddy Web] Using cached/fallback releases:', err);
    return filterFallback(platform);
  }
}

function filterFallback(platform?: PlatformType): Release[] {
  if (!platform) return FALLBACK_RELEASES;
  return FALLBACK_RELEASES.filter(r => r.platform === platform);
}

export function formatDate(dateString: string): string {
  try {
    const d = new Date(dateString);
    if (isNaN(d.getTime())) return dateString;
    return d.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  } catch {
    return dateString;
  }
}
