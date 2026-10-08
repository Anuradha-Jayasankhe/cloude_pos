import crypto from 'crypto';
import { Router } from 'express';
import { settings } from '../config';
import { requireAuth, requirePlatformAdmin } from '../middleware/auth';
import { ActivityLogModel, logActivity } from '../models/ActivityLog';
import { DeviceSessionModel } from '../models/DeviceSession';
import { PlanModel } from '../models/Plan';
import { SyncEventModel } from '../models/SyncEvent';
import { TenantModel } from '../models/Tenant';
import { UserModel } from '../models/User';
import { QrPaymentModel } from '../models/QrPayment';
import { DocModel } from '../models/Doc';
import { TutorialModel } from '../models/Tutorial';
import { PlatformSettingModel } from '../models/PlatformSetting';
import { hashPassword } from '../utils/password';

const adminRouter = Router();

// ─── Offline License Key Helpers ──────────────────────────────────────────────

const offlineKeyChecksum = (data: string): string => {
  return crypto.createHash('sha256').update(`SB_OFFLINE_SECRET_${data}`).digest('hex').slice(0, 8).toUpperCase();
};

export const generateOfflineLicenseKey = (args: {
  tenantId: string;
  planId: string;
  expiryDate: Date;
}): string => {
  const expiry = args.expiryDate.toISOString().slice(0, 10).replace(/-/g, '');
  const data = `${args.tenantId}|${args.planId}|${expiry}`;
  const checksum = offlineKeyChecksum(data);
  return `SBOFF-${args.tenantId.toUpperCase()}-${args.planId.toUpperCase()}-${expiry}-${checksum}`;
};

export const validateOfflineLicenseKey = (key: string): {
  valid: boolean;
  tenantId?: string;
  planId?: string;
  expiryDate?: Date;
  expired?: boolean;
  reason?: string;
} => {
  try {
    const normalized = key.trim().toUpperCase();
    const parts = normalized.split('-');
    // Format: SBOFF-TENANTID-PLANID-YYYYMMDD-CHECKSUM
    if (parts.length < 5 || parts[0] !== 'SBOFF') {
      return { valid: false, reason: 'Invalid format' };
    }

    const checksum = parts[parts.length - 1];
    const expiry = parts[parts.length - 2];
    const planId = parts.slice(2, parts.length - 2).join('-').toLowerCase();
    const tenantId = parts[1].toLowerCase();

    const data = `${tenantId}|${planId}|${expiry}`;
    const expectedChecksum = offlineKeyChecksum(data);

    if (checksum !== expectedChecksum) {
      return { valid: false, reason: 'Invalid checksum' };
    }

    const year = parseInt(expiry.slice(0, 4), 10);
    const month = parseInt(expiry.slice(4, 6), 10) - 1;
    const day = parseInt(expiry.slice(6, 8), 10);
    const expiryDate = new Date(year, month, day, 23, 59, 59);

    if (isNaN(expiryDate.getTime())) {
      return { valid: false, reason: 'Invalid expiry date' };
    }

    const now = new Date();
    if (now > expiryDate) {
      return { valid: true, tenantId, planId, expiryDate, expired: true };
    }

    return { valid: true, tenantId, planId, expiryDate, expired: false };
  } catch {
    return { valid: false, reason: 'Parse error' };
  }
};

// ─── Stats ─────────────────────────────────────────────────────────────────────

adminRouter.get('/stats', requireAuth, requirePlatformAdmin, async (_req, res) => {
  const [totalTenants, activeTenants, suspendedTenants, trialTenants, offlineTenants, totalUsers, totalSyncEvents] =
    await Promise.all([
      TenantModel.countDocuments({ tenantId: { $ne: settings.platformTenantId } }),
      TenantModel.countDocuments({ tenantId: { $ne: settings.platformTenantId }, status: 'ACTIVE' }),
      TenantModel.countDocuments({ tenantId: { $ne: settings.platformTenantId }, status: 'SUSPENDED' }),
      TenantModel.countDocuments({ tenantId: { $ne: settings.platformTenantId }, status: 'TRIAL' }),
      TenantModel.countDocuments({ tenantId: { $ne: settings.platformTenantId }, status: 'OFFLINE' }),
      UserModel.countDocuments({ tenantId: { $ne: settings.platformTenantId } }),
      SyncEventModel.countDocuments({}),
    ]);

  const recentTenants = await TenantModel.find({ tenantId: { $ne: settings.platformTenantId } })
    .sort({ createdAt: -1 })
    .limit(5)
    .lean();

  res.json({
    total_tenants: totalTenants,
    active_tenants: activeTenants,
    suspended_tenants: suspendedTenants,
    trial_tenants: trialTenants,
    offline_tenants: offlineTenants,
    total_users: totalUsers,
    total_sync_events: totalSyncEvents,
    recent_tenants: recentTenants.map(t => ({
      tenant_id: t.tenantId,
      store_name: t.storeName,
      owner_email: t.ownerEmail,
      plan_name: t.planName || 'Trial',
      status: t.status,
      created_at: t.createdAt,
    })),
  });
});

// ─── Tenants ───────────────────────────────────────────────────────────────────

const activationChecksum = (tenantId: string): string => {
  let hash = 0;
  for (const char of tenantId) {
    hash = (hash * 31 + char.charCodeAt(0)) % 104729;
  }
  return hash.toString(36).toUpperCase().padStart(4, '0');
};

const activationCodeForTenant = (tenantId: string): string =>
  `SB_${tenantId.toUpperCase()}_${activationChecksum(tenantId)}`;

const formatTenant = (t: any) => ({
  tenant_id: t.tenantId,
  store_name: t.storeName,
  owner_email: t.ownerEmail,
  owner_phone: t.ownerPhone ?? '',
  address: t.address ?? '',
  activation_code: activationCodeForTenant(t.tenantId),
  trial_starts_at: t.trialStartsAt,
  trial_ends_at: t.trialEndsAt,
  trial_active: t.trialActive,
  plan_id: t.planId ?? 'trial',
  plan_name: t.planName ?? 'Trial',
  plan_expires_at: t.planExpiresAt ?? null,
  plan_assigned_at: t.planAssignedAt ?? null,
  sync_enabled: t.syncEnabled ?? true,
  status: t.status ?? 'TRIAL',
  max_locations: t.maxLocations ?? 3,
  max_users: t.maxUsers ?? 15,
  max_products: t.maxProducts ?? 500,
  offline_license_key: t.offlineLicenseKey ?? null,
  deactivated_at: t.deactivatedAt ?? null,
  deactivated_by: t.deactivatedBy ?? null,
  created_at: t.createdAt,
});

adminRouter.get('/tenants', requireAuth, requirePlatformAdmin, async (req, res) => {
  const statusFilter = String(req.query.status ?? '').trim().toUpperCase();
  const searchQuery = String(req.query.search ?? '').trim();
  const limit = Math.min(500, Math.max(1, Number(req.query.limit ?? 100)));
  const skip = Math.max(0, Number(req.query.skip ?? 0));

  const query: Record<string, unknown> = { tenantId: { $ne: settings.platformTenantId } };
  if (statusFilter && statusFilter !== 'ALL') query.status = statusFilter;
  if (searchQuery) {
    query.$or = [
      { storeName: { $regex: searchQuery, $options: 'i' } },
      { ownerEmail: { $regex: searchQuery, $options: 'i' } },
      { tenantId: { $regex: searchQuery, $options: 'i' } },
    ];
  }

  const [tenants, total] = await Promise.all([
    TenantModel.find(query).sort({ createdAt: -1 }).limit(limit).skip(skip).lean(),
    TenantModel.countDocuments(query),
  ]);

  res.json({ total, tenants: tenants.map(formatTenant) });
});

adminRouter.get('/tenants/:tenantId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const tenant = await TenantModel.findOne({ tenantId }).lean();
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }
  res.json(formatTenant(tenant));
});

adminRouter.post('/tenants', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, unknown>;
  const tenantId = String(body.tenant_id ?? '').trim().toLowerCase();
  const storeName = String(body.store_name ?? '').trim();
  const ownerEmail = String(body.owner_email ?? '').trim().toLowerCase();
  const ownerName = String(body.owner_name ?? '').trim();
  const ownerPhone = String(body.owner_phone ?? '').trim();
  const address = String(body.address ?? '').trim();
  const password = String(body.password ?? 'StorePass123!').trim();
  const planId = String(body.plan_id ?? 'trial').trim().toLowerCase();
  const daysOverride = Number(body.days ?? 0);

  if (!tenantId || !storeName || !ownerEmail) {
    res.status(422).json({ detail: 'tenant_id, store_name, owner_email are required' });
    return;
  }

  const existingTenant = await TenantModel.findOne({ tenantId }).lean();
  if (existingTenant) {
    res.status(409).json({ detail: 'Tenant ID already exists' });
    return;
  }

  const existingUser = await UserModel.findOne({ email: ownerEmail }).lean();
  if (existingUser) {
    res.status(409).json({ detail: 'Email already exists' });
    return;
  }

  const plan = await PlanModel.findOne({ planId }).lean();
  const durationDays = daysOverride > 0 ? daysOverride : (plan?.durationDays ?? 7);

  const now = new Date();
  const trialEndsAt = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
  const isOffline = plan?.type === 'OFFLINE' || !plan?.syncEnabled;

  const tenant = await TenantModel.create({
    tenantId,
    storeName,
    ownerEmail,
    ownerPhone,
    address,
    trialStartsAt: now,
    trialEndsAt,
    trialActive: true,
    maxLocations: plan?.maxLocations ?? 3,
    planId: plan?.planId ?? 'trial',
    planName: plan?.name ?? 'Trial',
    planExpiresAt: durationDays > 0 ? trialEndsAt : null,
    planAssignedAt: now,
    syncEnabled: plan?.syncEnabled ?? true,
    status: plan?.type === 'FREE' ? 'ACTIVE' : plan?.type === 'OFFLINE' ? 'OFFLINE' : 'TRIAL',
    maxUsers: plan?.maxUsers ?? 15,
    maxProducts: plan?.maxProducts ?? 500,
  });

  await UserModel.create({
    tenantId,
    name: ownerName || storeName,
    email: ownerEmail,
    role: 'owner',
    passwordHash: await hashPassword(password),
    active: true,
  });

  // Generate offline license key if plan is offline
  if (isOffline && plan) {
    const offlineKey = generateOfflineLicenseKey({
      tenantId,
      planId: plan.planId,
      expiryDate: trialEndsAt,
    });
    tenant.offlineLicenseKey = offlineKey;
    await tenant.save();
  }

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'CREATE_TENANT',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Created store "${storeName}" with plan "${plan?.name ?? 'Trial'}"`,
  });

  res.status(201).json(formatTenant(tenant));
});

adminRouter.patch('/tenants/:tenantId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const body = req.body as Record<string, unknown>;
  if (body.store_name) tenant.storeName = String(body.store_name);
  if (body.owner_phone !== undefined) tenant.ownerPhone = String(body.owner_phone);
  if (body.address !== undefined) tenant.address = String(body.address);
  if (body.max_locations !== undefined) tenant.maxLocations = Number(body.max_locations);
  if (body.max_users !== undefined) tenant.maxUsers = Number(body.max_users);
  if (body.max_products !== undefined) tenant.maxProducts = Number(body.max_products);
  if (body.sync_enabled !== undefined) tenant.syncEnabled = Boolean(body.sync_enabled);

  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'UPDATE_TENANT',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Updated store "${tenant.storeName}"`,
  });

  res.json(formatTenant(tenant));
});

// POST /admin/tenants/:tenantId/assign-plan
adminRouter.post('/tenants/:tenantId/assign-plan', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const body = req.body as Record<string, unknown>;
  const planId = String(body.plan_id ?? '').trim().toLowerCase();
  const customDays = Number(body.days ?? 0);
  const customExpiryRaw = body.expires_at ? String(body.expires_at) : null;

  const plan = await PlanModel.findOne({ planId }).lean();
  if (!plan) {
    res.status(404).json({ detail: 'Plan not found' });
    return;
  }

  const now = new Date();
  let planExpiresAt: Date | null = null;

  if (customExpiryRaw) {
    const parsed = new Date(customExpiryRaw);
    if (!isNaN(parsed.getTime()) && parsed > now) {
      planExpiresAt = parsed;
    }
  } else if (customDays > 0) {
    planExpiresAt = new Date(now.getTime() + customDays * 24 * 60 * 60 * 1000);
  } else if (plan.durationDays > 0) {
    planExpiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);
  }

  tenant.planId = plan.planId;
  tenant.planName = plan.name;
  tenant.planExpiresAt = planExpiresAt;
  tenant.planAssignedAt = now;
  tenant.syncEnabled = plan.syncEnabled;
  tenant.maxUsers = plan.maxUsers;
  tenant.maxProducts = plan.maxProducts;
  tenant.maxLocations = plan.maxLocations;
  tenant.trialActive = true;
  tenant.trialEndsAt = planExpiresAt ?? new Date(now.getTime() + 36500 * 24 * 60 * 60 * 1000);
  tenant.deactivatedAt = null as any;
  tenant.deactivatedBy = null as any;

  // Determine status
  if (plan.type === 'OFFLINE') {
    tenant.status = 'OFFLINE';
    const offlineKey = generateOfflineLicenseKey({
      tenantId,
      planId: plan.planId,
      expiryDate: planExpiresAt ?? new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000),
    });
    tenant.offlineLicenseKey = offlineKey;
  } else if (plan.type === 'FREE') {
    tenant.status = 'ACTIVE';
  } else if (plan.type === 'TRIAL') {
    tenant.status = 'TRIAL';
  } else {
    tenant.status = 'ACTIVE';
  }

  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'ASSIGN_PLAN',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Assigned plan "${plan.name}" to store "${tenant.storeName}", expires: ${planExpiresAt?.toISOString() ?? 'never'}`,
  });

  res.json({ ...formatTenant(tenant), plan_expires_at: planExpiresAt });
});

// POST /admin/tenants/:tenantId/generate-offline-key
adminRouter.post('/tenants/:tenantId/generate-offline-key', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const body = req.body as Record<string, unknown>;
  const planId = String(body.plan_id ?? tenant.planId ?? 'offline').trim().toLowerCase();
  const daysRaw = Number(body.days ?? 365);
  const days = Math.max(1, Math.min(3650, daysRaw));

  const now = new Date();
  const expiryDate = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

  const offlineKey = generateOfflineLicenseKey({ tenantId, planId, expiryDate });
  tenant.offlineLicenseKey = offlineKey;
  tenant.planId = planId;
  tenant.planExpiresAt = expiryDate;
  tenant.syncEnabled = false;
  tenant.status = 'OFFLINE';
  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'GENERATE_OFFLINE_KEY',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Generated offline key for "${tenant.storeName}", expires: ${expiryDate.toISOString()}`,
  });

  res.json({
    tenant_id: tenantId,
    offline_license_key: offlineKey,
    plan_id: planId,
    expires_at: expiryDate,
  });
});

// POST /admin/tenants/:tenantId/suspend
adminRouter.post('/tenants/:tenantId/suspend', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  if (!tenantId || tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }
  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  tenant.trialActive = false;
  tenant.status = 'SUSPENDED';
  tenant.deactivatedAt = new Date();
  tenant.deactivatedBy = req.auth!.userId;
  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'SUSPEND_TENANT',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Suspended store "${tenant.storeName}"`,
  });

  res.json(formatTenant(tenant));
});

// POST /admin/tenants/:tenantId/activate
adminRouter.post('/tenants/:tenantId/activate', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const body = req.body as Record<string, unknown>;

  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const now = new Date();
  let days = Number(body.days);

  // If a plan_id is provided, apply its limits and set appropriate days
  const planId = body.plan_id ? String(body.plan_id).trim().toLowerCase() : null;
  if (planId) {
    const plan = await PlanModel.findOne({ planId }).lean();
    if (!plan) {
      res.status(404).json({ detail: 'Plan not found' });
      return;
    }
    tenant.planId = plan.planId;
    tenant.planName = plan.name;
    tenant.syncEnabled = plan.syncEnabled;
    tenant.maxUsers = plan.maxUsers;
    tenant.maxProducts = plan.maxProducts;
    tenant.maxLocations = plan.maxLocations;

    // Use custom days if provided, otherwise plan durationDays, otherwise 30
    if (!days || isNaN(days)) {
      days = plan.durationDays > 0 ? plan.durationDays : 30;
    }
  }

  if (!days || isNaN(days) || days <= 0) {
    days = 30; // default to 30 days if not set
  }
  days = Math.min(3650, days);

  let newExpiry: Date;
  if (body.expires_at) {
    const parsed = new Date(String(body.expires_at));
    if (!isNaN(parsed.getTime()) && parsed > now) {
      newExpiry = parsed;
    } else {
      newExpiry = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
    }
  } else {
    newExpiry = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
  }

  tenant.trialActive = true;
  tenant.trialStartsAt = now;
  tenant.trialEndsAt = newExpiry;
  tenant.planExpiresAt = newExpiry;
  tenant.status = 'ACTIVE';
  tenant.deactivatedAt = null as any;
  tenant.deactivatedBy = null as any;
  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'ACTIVATE_TENANT',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Reactivated store "${tenant.storeName}" with plan "${tenant.planName || 'none'}" expiring ${newExpiry.toISOString()}`,
  });

  res.json(formatTenant(tenant));
});

// POST /admin/tenants/:tenantId/convert-to-online
adminRouter.post('/tenants/:tenantId/convert-to-online', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const body = req.body as Record<string, unknown>;

  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const now = new Date();
  const planId = String(body.plan_id ?? '1month').trim().toLowerCase();
  const plan = await PlanModel.findOne({ planId }).lean();

  let newExpiry: Date;
  if (body.expires_at) {
    const parsed = new Date(String(body.expires_at));
    newExpiry = !isNaN(parsed.getTime()) && parsed > now ? parsed : new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  } else {
    const days = Number(body.days) || (plan && plan.durationDays > 0 ? plan.durationDays : 30);
    newExpiry = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
  }

  tenant.syncEnabled = true;
  tenant.status = 'ACTIVE';
  tenant.planId = plan ? plan.planId : '1month';
  tenant.planName = plan ? plan.name : '1 Month';
  tenant.planExpiresAt = newExpiry;
  tenant.planAssignedAt = now;
  tenant.trialActive = true;
  tenant.trialStartsAt = now;
  tenant.trialEndsAt = newExpiry;
  tenant.maxLocations = plan ? plan.maxLocations : 0;
  tenant.maxProducts = plan ? plan.maxProducts : 0;
  tenant.deactivatedAt = null as any;
  tenant.deactivatedBy = null as any;
  tenant.offlineLicenseKey = null; // Clear offline key as store is now online
  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'CONVERT_TO_ONLINE',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Converted store "${tenant.storeName}" from Offline to Online Cloud under plan "${tenant.planName}" expiring ${newExpiry.toISOString()}`,
  });

  res.json({
    ...formatTenant(tenant),
    converted_to_online: true,
    activation_code: activationCodeForTenant(tenant.tenantId),
  });
});

// POST /admin/tenants/:tenantId/convert-to-offline
adminRouter.post('/tenants/:tenantId/convert-to-offline', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant || tenant.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const now = new Date();
  const expiryDate = new Date(now.getTime() + 36500 * 24 * 60 * 60 * 1000); // 100-year lifetime
  const offlineKey = generateOfflineLicenseKey({ tenantId, planId: 'offline', expiryDate });

  tenant.syncEnabled = false;
  tenant.status = 'OFFLINE';
  tenant.planId = 'offline';
  tenant.planName = 'Offline Lifetime License';
  tenant.planExpiresAt = expiryDate;
  tenant.maxLocations = 1;
  tenant.offlineLicenseKey = offlineKey;
  await tenant.save();

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'CONVERT_TO_OFFLINE',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Switched store "${tenant.storeName}" to Offline Standalone mode with lifetime license key`,
  });

  res.json({
    ...formatTenant(tenant),
    converted_to_offline: true,
    offline_license_key: offlineKey,
  });
});

// DELETE /admin/tenants/:tenantId
adminRouter.delete('/tenants/:tenantId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  if (!tenantId || tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const tenant = await TenantModel.findOne({ tenantId }).lean();
  if (!tenant) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  await Promise.all([
    UserModel.deleteMany({ tenantId }),
    DeviceSessionModel.deleteMany({ tenantId }),
    TenantModel.deleteOne({ tenantId }),
  ]);

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'DELETE_TENANT',
    resource: 'tenants',
    resourceId: tenantId,
    details: `Deleted store "${tenant.storeName}"`,
  });

  res.status(204).send();
});

// ─── Users ─────────────────────────────────────────────────────────────────────

adminRouter.get('/users', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.query.tenant_id ?? '').trim().toLowerCase();
  const limit = Math.min(500, Math.max(1, Number(req.query.limit ?? 100)));
  const skip = Math.max(0, Number(req.query.skip ?? 0));

  const query: Record<string, unknown> = {};
  if (tenantId) query.tenantId = tenantId;

  const [users, total] = await Promise.all([
    UserModel.find(query).sort({ createdAt: -1 }).limit(limit).skip(skip).lean(),
    UserModel.countDocuments(query),
  ]);

  res.json({
    total,
    users: users.map(u => ({
      user_id: String(u._id),
      tenant_id: u.tenantId,
      name: u.name,
      email: u.email,
      role: u.role,
      location_ids: u.locationIds,
      active: u.active,
      created_at: u.createdAt,
    })),
  });
});

// ─── Activity Log ──────────────────────────────────────────────────────────────

adminRouter.get('/activity', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tenantId = String(req.query.tenant_id ?? '').trim();
  const action = String(req.query.action ?? '').trim();
  const resource = String(req.query.resource ?? '').trim();
  const limit = Math.min(500, Math.max(1, Number(req.query.limit ?? 50)));
  const skip = Math.max(0, Number(req.query.skip ?? 0));
  const fromDate = req.query.from ? new Date(String(req.query.from)) : null;
  const toDate = req.query.to ? new Date(String(req.query.to)) : null;

  const query: Record<string, unknown> = {};
  if (tenantId) query.tenantId = tenantId;
  if (action) query.action = { $regex: action, $options: 'i' };
  if (resource) query.resource = { $regex: resource, $options: 'i' };
  if (fromDate || toDate) {
    const dateRange: Record<string, Date> = {};
    if (fromDate && !isNaN(fromDate.getTime())) dateRange.$gte = fromDate;
    if (toDate && !isNaN(toDate.getTime())) dateRange.$lte = toDate;
    query.createdAt = dateRange;
  }

  const [logs, total] = await Promise.all([
    ActivityLogModel.find(query).sort({ createdAt: -1 }).limit(limit).skip(skip).lean(),
    ActivityLogModel.countDocuments(query),
  ]);

  res.json({
    total,
    logs: logs.map(l => ({
      id: String(l._id),
      tenant_id: l.tenantId,
      user_id: l.userId,
      user_name: l.userName,
      action: l.action,
      resource: l.resource,
      resource_id: l.resourceId,
      details: l.details,
      ip_address: l.ipAddress,
      created_at: l.createdAt,
    })),
  });
});

// ─── Validate Offline Key (public endpoint) ────────────────────────────────────

adminRouter.post('/validate-offline-key', async (req, res) => {
  const key = String(req.body?.offline_key ?? '').trim();
  if (!key) {
    res.status(422).json({ detail: 'offline_key is required' });
    return;
  }

  const result = validateOfflineLicenseKey(key);
  if (!result.valid) {
    res.status(400).json({ valid: false, reason: result.reason ?? 'Invalid key' });
    return;
  }

  // Look up plan info if available
  const plan = result.planId ? await PlanModel.findOne({ planId: result.planId }).lean() : null;

  res.json({
    valid: true,
    tenant_id: result.tenantId,
    plan_id: result.planId,
    plan_name: plan?.name ?? result.planId,
    expires_at: result.expiryDate,
    expired: result.expired,
    sync_enabled: false,
    max_users: plan?.maxUsers ?? 5,
    max_products: plan?.maxProducts ?? 500,
  });
});

// ─── QR Payments ───────────────────────────────────────────────────────────────

adminRouter.get('/qr-payments', requireAuth, requirePlatformAdmin, async (req, res) => {
  const statusFilter = String(req.query.status ?? '').trim().toUpperCase();
  const query: Record<string, unknown> = {};
  if (statusFilter && statusFilter !== 'ALL') {
    query.status = statusFilter;
  }

  const [payments, total, totalAmountResult, paidAmountResult] = await Promise.all([
    QrPaymentModel.find(query).sort({ createdAt: -1 }).lean(),
    QrPaymentModel.countDocuments(query),
    QrPaymentModel.aggregate([{ $group: { _id: null, total: { $sum: '$amount' } } }]),
    QrPaymentModel.aggregate([{ $match: { status: 'PAID' } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
  ]);

  res.json({
    total,
    total_amount: totalAmountResult[0]?.total ?? 0,
    paid_amount: paidAmountResult[0]?.total ?? 0,
    payments: payments.map(p => ({
      id: String(p._id),
      tenant_id: p.tenantId,
      store_name: p.storeName,
      amount: p.amount,
      payment_method: p.paymentMethod,
      status: p.status,
      order_id: p.orderId,
      customer_type: p.customerType,
      reference: p.reference,
      qr_reference: p.qrReference,
      sale_id: p.saleId,
      method: p.method,
      status_msg: p.statusMsg,
      created_at: p.createdAt,
    })),
  });
});

// ─── Documentation CRUD ────────────────────────────────────────────────────────

adminRouter.get('/docs', requireAuth, requirePlatformAdmin, async (_req, res) => {
  const docs = await DocModel.find({}).sort({ createdAt: -1 }).lean();
  res.json(docs.map(d => ({
    id: String(d._id),
    title: d.title,
    content: d.content,
    section: d.section,
    status: d.status,
    audience: d.audience,
    roles: d.roles,
    updated_at: d.updatedAt,
    created_at: d.createdAt,
  })));
});

adminRouter.post('/docs', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, any>;
  const doc = await DocModel.create({
    title: String(body.title ?? ''),
    content: String(body.content ?? ''),
    section: String(body.section ?? 'Getting Started'),
    status: String(body.status ?? 'PUBLISHED'),
    audience: String(body.audience ?? 'All Users'),
    roles: Array.isArray(body.roles) ? body.roles.map(String) : [],
    updatedAt: new Date(),
  });
  res.status(201).json({
    id: String(doc._id),
    title: doc.title,
    content: doc.content,
    section: doc.section,
    status: doc.status,
    audience: doc.audience,
    roles: doc.roles,
    updated_at: doc.updatedAt,
    created_at: doc.createdAt,
  });
});

adminRouter.patch('/docs/:id', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, any>;
  const update: Record<string, any> = { updatedAt: new Date() };
  if (body.title !== undefined) update.title = String(body.title);
  if (body.content !== undefined) update.content = String(body.content);
  if (body.section !== undefined) update.section = String(body.section);
  if (body.status !== undefined) update.status = String(body.status);
  if (body.audience !== undefined) update.audience = String(body.audience);
  if (body.roles !== undefined) update.roles = Array.isArray(body.roles) ? body.roles.map(String) : [];

  const doc = await DocModel.findByIdAndUpdate(req.params.id, { $set: update }, { new: true });
  if (!doc) {
    res.status(404).json({ detail: 'Doc not found' });
    return;
  }
  res.json({
    id: String(doc._id),
    title: doc.title,
    content: doc.content,
    section: doc.section,
    status: doc.status,
    audience: doc.audience,
    roles: doc.roles,
    updated_at: doc.updatedAt,
    created_at: doc.createdAt,
  });
});

adminRouter.delete('/docs/:id', requireAuth, requirePlatformAdmin, async (req, res) => {
  const doc = await DocModel.findByIdAndDelete(req.params.id);
  if (!doc) {
    res.status(404).json({ detail: 'Doc not found' });
    return;
  }
  res.status(204).send();
});

// ─── Tutorials CRUD ────────────────────────────────────────────────────────────

adminRouter.get('/tutorials', requireAuth, requirePlatformAdmin, async (_req, res) => {
  const tutorials = await TutorialModel.find({}).sort({ createdAt: -1 }).lean();
  res.json(tutorials.map(t => ({
    id: String(t._id),
    title: t.title,
    description: t.description,
    thumbnail_url: t.thumbnailUrl,
    video_url: t.videoUrl,
    audience: t.audience,
    status: t.status,
    created_at: t.createdAt,
  })));
});

adminRouter.post('/tutorials', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, any>;
  const tutorial = await TutorialModel.create({
    title: String(body.title ?? ''),
    description: String(body.description ?? ''),
    thumbnailUrl: String(body.thumbnail_url ?? ''),
    videoUrl: String(body.video_url ?? ''),
    audience: String(body.audience ?? 'All Users'),
    status: String(body.status ?? 'PUBLISHED'),
  });
  res.status(201).json({
    id: String(tutorial._id),
    title: tutorial.title,
    description: tutorial.description,
    thumbnail_url: tutorial.thumbnailUrl,
    video_url: tutorial.videoUrl,
    audience: tutorial.audience,
    status: tutorial.status,
    created_at: tutorial.createdAt,
  });
});

adminRouter.patch('/tutorials/:id', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, any>;
  const update: Record<string, any> = {};
  if (body.title !== undefined) update.title = String(body.title);
  if (body.description !== undefined) update.description = String(body.description);
  if (body.thumbnail_url !== undefined) update.thumbnailUrl = String(body.thumbnail_url);
  if (body.video_url !== undefined) update.videoUrl = String(body.video_url);
  if (body.audience !== undefined) update.audience = String(body.audience);
  if (body.status !== undefined) update.status = String(body.status);

  const tutorial = await TutorialModel.findByIdAndUpdate(req.params.id, { $set: update }, { new: true });
  if (!tutorial) {
    res.status(404).json({ detail: 'Tutorial not found' });
    return;
  }
  res.json({
    id: String(tutorial._id),
    title: tutorial.title,
    description: tutorial.description,
    thumbnail_url: tutorial.thumbnailUrl,
    video_url: tutorial.videoUrl,
    audience: tutorial.audience,
    status: tutorial.status,
    created_at: tutorial.createdAt,
  });
});

adminRouter.delete('/tutorials/:id', requireAuth, requirePlatformAdmin, async (req, res) => {
  const tutorial = await TutorialModel.findByIdAndDelete(req.params.id);
  if (!tutorial) {
    res.status(404).json({ detail: 'Tutorial not found' });
    return;
  }
  res.status(204).send();
});

// ─── Platform Settings (Default Trial Days, etc.) ──────────────────────────

adminRouter.get('/settings', requireAuth, requirePlatformAdmin, async (_req, res) => {
  const trialDaysSetting = await PlatformSettingModel.findOne({ key: 'default_trial_days' }).lean();
  const defaultTrialDays = trialDaysSetting ? Number(trialDaysSetting.value) : settings.defaultTrialDays;
  res.json({
    default_trial_days: defaultTrialDays,
    app_name: settings.appName,
  });
});

adminRouter.put('/settings', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, any>;
  const trialDays = Number(body.default_trial_days);
  if (!trialDays || isNaN(trialDays) || trialDays < 1 || trialDays > 365) {
    res.status(422).json({ detail: 'default_trial_days must be a valid number between 1 and 365' });
    return;
  }

  await PlatformSettingModel.findOneAndUpdate(
    { key: 'default_trial_days' },
    { key: 'default_trial_days', value: trialDays, updatedAt: new Date() },
    { upsert: true, new: true }
  );

  settings.defaultTrialDays = trialDays;

  // Also update the Trial plan durationDays/trialDays
  await PlanModel.findOneAndUpdate(
    { planId: 'trial' },
    { durationDays: trialDays, trialDays: trialDays }
  );

  await logActivity({
    tenantId: settings.platformTenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'UPDATE_SETTINGS',
    resource: 'settings',
    resourceId: 'platform_settings',
    details: `Updated default trial days to ${trialDays}`,
  });

  res.json({
    default_trial_days: trialDays,
    updated: true,
  });
});

export { adminRouter };
