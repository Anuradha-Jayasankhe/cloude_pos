import { settings } from './config';
import { PlanModel } from './models/Plan';
import { TenantModel } from './models/Tenant';
import { UserModel } from './models/User';
import { QrPaymentModel } from './models/QrPayment';
import { DocModel } from './models/Doc';
import { TutorialModel } from './models/Tutorial';
import { ReleaseModel } from './models/Release';
import { hashPassword } from './utils/password';

const DEFAULT_PLANS = [
  {
    planId: 'free',
    name: 'Free (Deactivated)',
    type: 'FREE' as const,
    description: 'Deactivated — StoreBuddy does not offer permanent free plans',
    priceMonthly: 0,
    priceYearly: 0,
    durationDays: 0,
    trialDays: 0,
    maxUsers: 1,
    maxProducts: 0,
    maxLocations: 1,
    syncEnabled: false,
    features: ['Deactivated'],
    isPublic: false,
    isActive: false,
  },
  {
    planId: 'trial',
    name: 'Trial',
    type: 'TRIAL' as const,
    description: 'Official 7-Day full access trial for new stores (Unlimited Products & Cloud Locations)',
    priceMonthly: 0,
    priceYearly: 0,
    durationDays: 7,
    trialDays: 7,
    maxUsers: 25,
    maxProducts: 0, // 0 = Unlimited
    maxLocations: 0, // 0 = Unlimited
    syncEnabled: true,
    features: ['Full POS', 'Cloud Sync', 'Unlimited Products', 'Unlimited Locations', 'Reports', 'Multi-user', 'Inventory'],
    isPublic: true,
    isActive: true,
  },
  {
    planId: '1month',
    name: '1 Month',
    type: 'MONTHLY' as const,
    description: 'Monthly cloud plan (Rs. 5,000 / month) — Unlimited Products & Locations',
    priceMonthly: 5000,
    priceYearly: 60000,
    durationDays: 30,
    trialDays: 0,
    maxUsers: 25,
    maxProducts: 0, // 0 = Unlimited
    maxLocations: 0, // 0 = Unlimited
    syncEnabled: true,
    features: ['Full POS', 'Cloud Sync', 'Unlimited Products', 'Unlimited Locations', 'Advanced Reports', 'Multi-user', 'Inventory', 'Priority Support'],
    isPublic: true,
    isActive: true,
  },
  {
    planId: '6month',
    name: '6 Months',
    type: 'BIANNUAL' as const,
    description: '6-Month cloud package — Unlimited Products & Locations',
    priceMonthly: 4500,
    priceYearly: 27000,
    durationDays: 180,
    trialDays: 0,
    maxUsers: 50,
    maxProducts: 0, // 0 = Unlimited
    maxLocations: 0, // 0 = Unlimited
    syncEnabled: true,
    features: ['Full POS', 'Cloud Sync', 'Unlimited Products', 'Unlimited Locations', 'Advanced Reports', 'Inventory', 'Priority Support', 'Commission Management'],
    isPublic: true,
    isActive: true,
  },
  {
    planId: '1year',
    name: '1 Year',
    type: 'ANNUAL' as const,
    description: 'Annual cloud subscription (Rs. 4,000 / month, Rs. 48,000 / yr) — Unlimited Products & Locations',
    priceMonthly: 4000,
    priceYearly: 48000,
    durationDays: 365,
    trialDays: 0,
    maxUsers: 100,
    maxProducts: 0, // 0 = Unlimited
    maxLocations: 0, // 0 = Unlimited
    syncEnabled: true,
    features: ['Full POS', 'Cloud Sync', 'Unlimited Products', 'Unlimited Locations', 'Advanced Reports', 'Priority Support', 'API Access', 'Custom Branding'],
    isPublic: true,
    isActive: true,
  },
  {
    planId: 'offline',
    name: 'Offline Lifetime License',
    type: 'OFFLINE' as const,
    description: 'Lifetime standalone offline license (Rs. 70,000 fixed) — 1 local location, Unlimited Products, Zero Internet',
    priceMonthly: 0,
    priceYearly: 70000,
    durationDays: 36500, // 100 years lifetime
    trialDays: 0,
    maxUsers: 15,
    maxProducts: 0, // 0 = Unlimited
    maxLocations: 1, // 1 location for offline
    syncEnabled: false,
    features: ['Full POS', 'Unlimited Products', 'Single Location', '100% Offline SQLite', 'Lifetime SBOFF Key'],
    isPublic: true,
    isActive: true,
  },
];

export const bootstrapPlatform = async (): Promise<void> => {
  const now = new Date();
  const trialEndsAt = new Date(now.getTime() + 36500 * 24 * 60 * 60 * 1000);

  // Bootstrap platform tenant
  await TenantModel.findOneAndUpdate(
    { tenantId: settings.platformTenantId },
    {
      $set: {
        tenantId: settings.platformTenantId,
        storeName: 'StoreBuddy Platform',
        ownerEmail: settings.platformAdminEmail,
        trialStartsAt: now,
        trialEndsAt,
        trialActive: true,
        planId: '1year',
        planName: '1 Year',
        planExpiresAt: trialEndsAt,
        syncEnabled: true,
        status: 'ACTIVE',
        maxUsers: 9999,
        maxProducts: 9999,
      },
    },
    { upsert: true, new: true }
  );

  // Bootstrap platform admin user
  const adminExists = await UserModel.findOne({ email: settings.platformAdminEmail });
  if (!adminExists) {
    await UserModel.create({
      tenantId: settings.platformTenantId,
      name: settings.platformAdminName,
      email: settings.platformAdminEmail,
      role: 'platform_admin',
      passwordHash: await hashPassword(settings.platformAdminPassword),
      active: true,
    });
  } else {
    await UserModel.updateOne(
      { email: settings.platformAdminEmail },
      {
        $set: {
          tenantId: settings.platformTenantId,
          name: settings.platformAdminName,
          role: 'platform_admin',
          passwordHash: await hashPassword(settings.platformAdminPassword),
          active: true,
        },
      }
    );
  }

  // Seed/update default plans to ensure active plan definitions, limits, and pricing are in sync
  for (const plan of DEFAULT_PLANS) {
    await PlanModel.findOneAndUpdate(
      { planId: plan.planId },
      { $set: plan },
      { upsert: true, new: true }
    );
  }

  // Seed sample QR payments
  const qrCount = await QrPaymentModel.countDocuments();
  if (qrCount === 0) {
    const samplePayments = [
      {
        tenantId: 'dine-buddy',
        storeName: 'Dine Buddy',
        amount: 60,
        paymentMethod: 'HELAPAY',
        status: 'PAID' as const,
        orderId: 'Order 9a01f56b-3ab8-46c6-ae99-cf479416b5c5',
        reference: '2c49da156b178115568056e5c58bc1',
        qrReference: '0069450197609781155680717',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 2),
      },
      {
        tenantId: 'dine-buddy',
        storeName: 'Dine Buddy',
        amount: 1000,
        paymentMethod: 'HELAPAY',
        status: 'PENDING' as const,
        orderId: 'Order 2c49da15-8b98-46c6-ae99-df479416b5c5',
        reference: '2c49da156b178115568056e5c58bc1',
        qrReference: '0069450197609781155680717',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Cannot Find Sale',
        createdAt: new Date(Date.now() - 3600 * 1000 * 24),
      },
      {
        tenantId: 'dine-buddy',
        storeName: 'Dine Buddy',
        amount: 500,
        paymentMethod: 'HELAPAY',
        status: 'PENDING' as const,
        orderId: 'Order c52dec97-480c-4ee5-af86-94ccf092af7c',
        reference: 'c52dec974817810693776485e64cdd8',
        qrReference: '0069450197609781069377830',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 25),
      },
      {
        tenantId: 'fashion-buddy',
        storeName: 'Aura Boutique',
        amount: 1200,
        paymentMethod: 'LANKAQR',
        status: 'PENDING' as const,
        orderId: 'Order f02abc45-1234-5678-abcd-ef1234567890',
        reference: 'f02abc4517810693776485e64cdd8',
        qrReference: '0069450197609781069377831',
        saleId: 'Pending',
        method: 'LANKAQR',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 30),
      },
      {
        tenantId: 'fashion-buddy',
        storeName: 'Aura Boutique',
        amount: 800,
        paymentMethod: 'LANKAQR',
        status: 'PENDING' as const,
        orderId: 'Order a12bc345-5678-90ab-cdef-1234567890ab',
        reference: 'a12bc34517810693776485e64cdd8',
        qrReference: '0069450197609781069377832',
        saleId: 'Pending',
        method: 'LANKAQR',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 35),
      },
      {
        tenantId: 'aura-style',
        storeName: 'Urban Style',
        amount: 1500,
        paymentMethod: 'HELAPAY',
        status: 'PENDING' as const,
        orderId: 'Order b34cd567-90ab-cdef-1234-567890abcdef',
        reference: 'b34cd56717810693776485e64cdd8',
        qrReference: '0069450197609781069377833',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Pending validation',
        createdAt: new Date(Date.now() - 3600 * 1000 * 40),
      },
      {
        tenantId: 'aura-style',
        storeName: 'Urban Style',
        amount: 900,
        paymentMethod: 'HELAPAY',
        status: 'PENDING' as const,
        orderId: 'Order c56de789-cdef-1234-5678-90abcdef1234',
        reference: 'c56de78917810693776485e64cdd8',
        qrReference: '0069450197609781069377834',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Pending validation',
        createdAt: new Date(Date.now() - 3600 * 1000 * 45),
      },
      {
        tenantId: 'dine-buddy',
        storeName: 'Dine Buddy',
        amount: 1100,
        paymentMethod: 'LANKAQR',
        status: 'PENDING' as const,
        orderId: 'Order d78ef90a-1234-5678-90ab-cdef12345678',
        reference: 'd78ef90a17810693776485e64cdd8',
        qrReference: '0069450197609781069377835',
        saleId: 'Pending',
        method: 'LANKAQR',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 50),
      },
      {
        tenantId: 'fashion-buddy',
        storeName: 'Aura Boutique',
        amount: 750,
        paymentMethod: 'HELAPAY',
        status: 'PENDING' as const,
        orderId: 'Order e90ab12c-3456-7890-abcd-ef1234567890',
        reference: 'e90ab12c17810693776485e64cdd8',
        qrReference: '0069450197609781069377836',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Pending validation',
        createdAt: new Date(Date.now() - 3600 * 1000 * 55),
      },
      {
        tenantId: 'aura-style',
        storeName: 'Urban Style',
        amount: 650,
        paymentMethod: 'LANKAQR',
        status: 'PENDING' as const,
        orderId: 'Order f12bc34d-5678-90ab-cdef-1234567890ab',
        reference: 'f12bc34d17810693776485e64cdd8',
        qrReference: '0069450197609781069377837',
        saleId: 'Pending',
        method: 'LANKAQR',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 60),
      },
      {
        tenantId: 'dine-buddy',
        storeName: 'Dine Buddy',
        amount: 850,
        paymentMethod: 'HELAPAY',
        status: 'PENDING' as const,
        orderId: 'Order a34cd56e-7890-abcd-ef12-34567890abcd',
        reference: 'a34cd56e17810693776485e64cdd8',
        qrReference: '0069450197609781069377838',
        saleId: 'Pending',
        method: 'Unknown',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 65),
      },
      {
        tenantId: 'aura-style',
        storeName: 'Urban Style',
        amount: 366,
        paymentMethod: 'LANKAQR',
        status: 'PENDING' as const,
        orderId: 'Order b56ef78g-90ab-cdef-1234-567890abcdef',
        reference: 'b56ef78g17810693776485e64cdd8',
        qrReference: '0069450197609781069377839',
        saleId: 'Pending',
        method: 'LANKAQR',
        statusMsg: 'Success',
        createdAt: new Date(Date.now() - 3600 * 1000 * 70),
      },
    ];
    await QrPaymentModel.insertMany(samplePayments);
  }

  // Seed sample Docs
  const docCount = await DocModel.countDocuments();
  if (docCount === 0) {
    await DocModel.insertMany([
      {
        title: 'StoreBuddy: How to Create a Sale',
        content: `### How to Create a Sale in StoreBuddy POS

Follow these quick steps to complete a checkout operation:
1. **Add items to cart**: Select products from the catalog or scan barcodes.
2. **Apply discounts**: Enter manual item-level or overall invoice discounts if allowed.
3. **Select Customer**: Associate a customer or keep it as Walk-in.
4. **Choose Payment Mode**: Select Cash, Card, Cheque, Installment, or Cash on Delivery (COD).
5. **Checkout**: Review details and hit checkout. The invoice PDF will be generated immediately for printing or sharing.`,
        section: 'Getting Started',
        status: 'PUBLISHED' as const,
        audience: 'All Users' as const,
        roles: ['role-restricted'],
        updatedAt: new Date(),
        createdAt: new Date(),
      },
      {
        title: 'Login Screen',
        content: `### Sign In to StoreBuddy POS Client

How to access the POS terminal offline or online:
* **Online Mode**: Input your active **Tenant ID**, **Email**, and **Password**. Hit Login.
* **Offline Mode**: Activate device with offline license key. Use the offline default credentials \`owner@storebuddy.local\` with password \`offline\`.`,
        section: 'Getting Started',
        status: 'PUBLISHED' as const,
        audience: 'All Users' as const,
        roles: [],
        updatedAt: new Date(),
        createdAt: new Date(),
      },
    ]);
  }

  // Seed sample Tutorials
  const tutCount = await TutorialModel.countDocuments();
  if (tutCount === 0) {
    await TutorialModel.insertMany([
      {
        title: 'Printer setup',
        description: 'This video provides a complete guide on setting up a printer for your system. Learn how to configure printing settings, connect devices, and ensure smooth printing of receipts and order details.',
        thumbnailUrl: '',
        videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        audience: 'All Users' as const,
        status: 'PUBLISHED' as const,
      },
      {
        title: 'Add Staff Member',
        description: 'In this tutorial, you will learn how to add and manage staff members in the system. The video covers entering employee details, assigning roles, and setting permissions to ensure smooth staff management and secure access control.',
        thumbnailUrl: '',
        videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        audience: 'Owners' as const,
        status: 'PUBLISHED' as const,
      },
      {
        title: 'Order cancellation and notification',
        description: 'Watch this tutorial to understand how order cancellations work and how notifications are handled within the system. Learn how to cancel orders properly and ensure that all relevant parties receive timely updates.',
        thumbnailUrl: '',
        videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        audience: 'All Users' as const,
        status: 'PUBLISHED' as const,
      },
      {
        title: 'Order (Complete / Edit / Cancel / Split)',
        description: 'This video explains how to handle orders efficiently, including completing, editing, canceling, and splitting orders in the POS system.',
        thumbnailUrl: '',
        videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        audience: 'All Users' as const,
        status: 'PUBLISHED' as const,
      },
      {
        title: 'Item Add',
        description: 'This video guides you through the process of adding items to your system. You will learn how to create new items, set catalog categories, prices, units, and details.',
        thumbnailUrl: '',
        videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        audience: 'All Users' as const,
        status: 'PUBLISHED' as const,
      },
      {
        title: 'Add Inventory Item',
        description: 'Learn how to easily add inventory items and manage stock levels, minimum stocks, adjustments, and supplier information.',
        thumbnailUrl: '',
        videoUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        audience: 'All Users' as const,
        status: 'PUBLISHED' as const,
      },
    ]);
  }

  // Seed Initial Product Software Releases (Windows Desktop & Android Mobile)
  try {
    const SEED_RELEASES = [
      {
        version: '2.4.0',
        platform: 'windows' as const,
        channel: 'stable' as const,
        downloadUrl: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.4.0/StoreBuddy_POS_Setup_x64_v2.4.0.exe',
        releaseNotes: '• Added 4-section hardware printer engine with USB, LAN/Ethernet & Bluetooth support\n• Automated ESC/POS Cash Drawer kick on checkout with live solenoid test\n• Full Barcode & Label printing presets (Zebra, Dymo, A4 multi-label sheets)\n• Cash on Delivery (COD) workflows with automated shipping fee calculation\n• Zero-cash return guarantee for unpaid COD orders\n• Electronic item IMEI & Serial number tracking with barcode generation\n• Clean bilingual isolation: English, Sinhala (සිංහල), Tamil (தமிழ்)',
        releaseDate: new Date('2026-09-21T10:00:00Z'),
        published: true,
      },
      {
        version: '2.3.2',
        platform: 'windows' as const,
        channel: 'stable' as const,
        downloadUrl: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.3.2/StoreBuddy_POS_Setup_x64_v2.3.2.exe',
        releaseNotes: '• Hybrid cloud & offline SQLite sync with auto-reconnect\n• Multi-branch inventory tracking with transfer notes\n• Dynamic receipt header/footer customization\n• EPF/ETF statutory payroll default calculations\n• Enhanced touchscreen keyboard layout for POS terminals',
        releaseDate: new Date('2026-08-15T10:00:00Z'),
        published: true,
      },
      {
        version: '2.2.0',
        platform: 'windows' as const,
        channel: 'stable' as const,
        downloadUrl: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.2.0/StoreBuddy_POS_Setup_x64_v2.2.0.exe',
        releaseNotes: '• Initial major release of StoreBuddy POS Windows Desktop\n• Rapid barcode scanning and cart checkout under 3 seconds\n• Multi-user cashier accounts with pin code locking\n• End-of-day Z-report generation and PDF exports',
        releaseDate: new Date('2026-06-30T10:00:00Z'),
        published: true,
      },
      {
        version: '2.4.0',
        platform: 'android' as const,
        channel: 'stable' as const,
        downloadUrl: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.4.0/StoreBuddy_POS_Mobile_v2.4.0.apk',
        releaseNotes: '• Mobile handheld POS with camera barcode scanning\n• Mobile Reload Module for telecom networks (Dialog, Mobitel, Hutch, Airtel)\n• Handheld Bluetooth 58mm thermal receipt printing\n• IMEI scanner using camera OCR for mobile phone shops\n• Real-time offline order queue with cloud synchronization',
        releaseDate: new Date('2026-09-21T12:00:00Z'),
        published: true,
      },
      {
        version: '2.2.5',
        platform: 'android' as const,
        channel: 'stable' as const,
        downloadUrl: 'https://github.com/AnuruddhaJayasanke/storebuddy-cloud/releases/download/v2.2.5/StoreBuddy_POS_Mobile_v2.2.5.apk',
        releaseNotes: '• Initial Android mobile handheld companion app\n• Real-time stock lookup and price checker\n• Offline sales sync when reconnected to store Wi-Fi',
        releaseDate: new Date('2026-07-20T10:00:00Z'),
        published: true,
      },
    ];

    for (const rel of SEED_RELEASES) {
      await ReleaseModel.findOneAndUpdate(
        { version: rel.version, platform: rel.platform, channel: rel.channel },
        { $setOnInsert: rel },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
    }
  } catch (err) {
    console.warn('[Bootstrap] Release seeding notice:', (err as Error).message);
  }

  console.log('Platform bootstrapped successfully');
};
