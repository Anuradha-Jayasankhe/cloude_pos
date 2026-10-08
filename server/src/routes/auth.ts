import { Router } from 'express';

import { settings } from '../config';
import { requireAuth, requirePlatformAdmin } from '../middleware/auth';
import { DeviceSessionModel } from '../models/DeviceSession';
import { PlanModel } from '../models/Plan';
import { TenantModel } from '../models/Tenant';
import { UserModel } from '../models/User';
import { createAccessToken } from '../utils/jwt';
import { hashPassword, verifyPassword } from '../utils/password';
import { validateOfflineLicenseKey } from './admin';

const authRouter = Router();

const canManageTenantUsers = (role: string): boolean =>
  role === 'platform_admin' || role === 'owner' || role === 'admin' || role === 'manager';

const activationChecksum = (tenantId: string): string => {
  let hash = 0;
  for (const char of tenantId) {
    hash = (hash * 31 + char.charCodeAt(0)) % 104729;
  }
  return hash.toString(36).toUpperCase().padStart(4, '0');
};

const activationCodeForTenant = (tenantId: string): string =>
  `SB_${tenantId.toUpperCase()}_${activationChecksum(tenantId)}`;

const tenantIdFromActivationCode = (code: string): string | null => {
  const normalized = code.trim().toUpperCase();
  const match = /^SB_([A-Z0-9-]+)_([A-Z0-9]{4,8})$/.exec(normalized);
  if (!match) return null;

  const tenantId = match[1].toLowerCase();
  const checksum = match[2];
  if (activationChecksum(tenantId) !== checksum) return null;
  return tenantId;
};

const toTokenResponse = (args: {
  accessToken: string;
  userId: string;
  tenantId: string;
  role: string;
  locationIds?: string[];
  trialEndsAt?: Date | null;
  maxLocations?: number;
  planId?: string;
  planName?: string;
  status?: string;
  syncEnabled?: boolean;
  planExpiresAt?: Date | null;
}) => ({
  access_token: args.accessToken,
  token_type: 'bearer',
  user_id: args.userId,
  tenant_id: args.tenantId,
  role: args.role,
  location_ids: args.locationIds ?? [],
  trial_ends_at: args.trialEndsAt ?? null,
  max_locations: args.maxLocations ?? 3,
  plan_id: args.planId ?? 'trial',
  plan_name: args.planName ?? 'Trial',
  status: args.status ?? 'TRIAL',
  sync_enabled: args.syncEnabled !== undefined ? args.syncEnabled : true,
  plan_expires_at: args.planExpiresAt ?? args.trialEndsAt ?? null,
});

authRouter.post('/register-store', async (req, res) => {
  const payload = req.body as {
    store_name?: string;
    tenant_id?: string;
    owner_name?: string;
    owner_email?: string;
    password?: string;
  };

  const ownerEmail = (payload.owner_email ?? '').toLowerCase().trim();
  const tenantId = (payload.tenant_id ?? '').trim().toLowerCase();
  const storeName = (payload.store_name ?? '').trim();
  const ownerName = (payload.owner_name ?? '').trim();
  const password = payload.password ?? '';

  if (!ownerEmail || !tenantId) {
    res.status(422).json({ detail: 'Owner email and tenant id are required' });
    return;
  }

  const tenant = await TenantModel.findOne({ tenantId }).lean();
  if (tenant) {
    res.status(409).json({ detail: 'Tenant id already exists' });
    return;
  }

  const existingUser = await UserModel.findOne({ email: ownerEmail }).lean();
  if (existingUser) {
    res.status(409).json({ detail: 'Email already exists' });
    return;
  }

  const now = new Date();
  const trialEndsAt = new Date(now.getTime() + settings.defaultTrialDays * 24 * 60 * 60 * 1000);

  const createdTenant = await TenantModel.create({
    tenantId,
    storeName: storeName || tenantId,
    ownerEmail,
    trialStartsAt: now,
    trialEndsAt,
    trialActive: true,
    maxLocations: 3,
  });

  const createdOwner = await UserModel.create({
    tenantId,
    name: ownerName || storeName || tenantId,
    email: ownerEmail,
    role: 'owner',
    passwordHash: await hashPassword(password),
    active: true,
  });

  const token = createAccessToken({
    subject: createdOwner.email,
    tenantId,
    role: createdOwner.role,
    userId: String(createdOwner._id),
  });

  res.status(200).json(
    toTokenResponse({
      accessToken: token,
      userId: String(createdOwner._id),
      tenantId,
      role: createdOwner.role,
      locationIds: createdOwner.locationIds,
      trialEndsAt: createdTenant.trialEndsAt,
      maxLocations: createdTenant.maxLocations,
      planId: createdTenant.planId,
      planName: createdTenant.planName,
      status: createdTenant.status,
      syncEnabled: createdTenant.syncEnabled,
      planExpiresAt: createdTenant.planExpiresAt,
    })
  );
});

authRouter.post('/login', async (req, res) => {
  const payload = req.body as {
    tenant_id?: string | null;
    email?: string;
    password?: string;
    device_id?: string;
    device_name?: string;
  };

  const email = (payload.email ?? '').toLowerCase().trim();
  const password = payload.password ?? '';
  const tenantId = payload.tenant_id?.trim().toLowerCase();

  const user = tenantId
    ? await UserModel.findOne({ tenantId, email })
    : await UserModel.findOne({ email });

  if (!user || !(await verifyPassword(password, user.passwordHash))) {
    res.status(401).json({ detail: 'Invalid credentials' });
    return;
  }

  if (!user.active) {
    res.status(403).json({ detail: 'User inactive' });
    return;
  }

  const tenant = await TenantModel.findOne({ tenantId: user.tenantId });
  if (user.role !== 'platform_admin') {
    if (!tenant) {
      res.status(403).json({ detail: 'Tenant is not active' });
      return;
    }

    const now = new Date();
    if (tenant.status === 'SUSPENDED') {
      res.status(403).json({ detail: 'Tenant account suspended. Contact support.' });
      return;
    }

    if (tenant.planId && tenant.planId !== 'trial' && tenant.planId !== 'free') {
      if (tenant.planExpiresAt && now > tenant.planExpiresAt) {
        if (tenant.status !== 'EXPIRED') {
          tenant.status = 'EXPIRED';
          await tenant.save();
        }
        res.status(403).json({ detail: 'Subscription expired. Please renew your plan.' });
        return;
      }
    } else if (tenant.planId === 'trial') {
      if (!tenant.trialActive || now > tenant.trialEndsAt) {
        if (tenant.trialActive || tenant.status !== 'EXPIRED') {
          tenant.trialActive = false;
          tenant.status = 'EXPIRED';
          await tenant.save();
        }
        res.status(403).json({ detail: 'Trial expired. Contact platform admin to reactivate your trial.' });
        return;
      }
    }
  }

  const deviceId = payload.device_id ?? '';
  const deviceName = payload.device_name ?? 'Unknown Device';
  if (deviceId) {
    await DeviceSessionModel.findOneAndUpdate(
      {
        tenantId: user.tenantId,
        deviceId,
      },
      {
        tenantId: user.tenantId,
        userId: String(user._id),
        deviceId,
        deviceName,
        lastSeenAt: new Date(),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  const token = createAccessToken({
    subject: user.email,
    tenantId: user.tenantId,
    role: user.role,
    userId: String(user._id),
  });

  res.status(200).json(
    toTokenResponse({
      accessToken: token,
      userId: String(user._id),
      tenantId: user.tenantId,
      role: user.role,
      locationIds: user.locationIds,
      trialEndsAt: tenant?.trialEndsAt ?? null,
      maxLocations: tenant?.maxLocations ?? 3,
      planId: tenant?.planId,
      planName: tenant?.planName,
      status: tenant?.status,
      syncEnabled: tenant?.syncEnabled,
      planExpiresAt: tenant?.planExpiresAt,
    })
  );
});

authRouter.post('/activate-device', async (req, res) => {
  const payload = req.body as {
    activation_code?: string;
    device_id?: string;
    device_name?: string;
  };

  const activationCode = String(payload.activation_code ?? '').trim();
  const tenantId = tenantIdFromActivationCode(activationCode);
  if (!tenantId) {
    res.status(401).json({ detail: 'Invalid activation code' });
    return;
  }

  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant) {
    res.status(404).json({ detail: 'Tenant not found for activation code' });
    return;
  }

  const now = new Date();
  if (tenant.status === 'SUSPENDED') {
    res.status(403).json({ detail: 'Tenant account suspended. Contact support.' });
    return;
  }

  if (tenant.planId && tenant.planId !== 'trial' && tenant.planId !== 'free') {
    if (tenant.planExpiresAt && now > tenant.planExpiresAt) {
      if (tenant.status !== 'EXPIRED') {
        tenant.status = 'EXPIRED';
        await tenant.save();
      }
      res.status(403).json({ detail: 'Subscription expired. Please renew your plan.' });
      return;
    }
  } else if (tenant.planId === 'trial') {
    if (!tenant.trialActive || now > tenant.trialEndsAt) {
      if (tenant.trialActive || tenant.status !== 'EXPIRED') {
        tenant.trialActive = false;
        tenant.status = 'EXPIRED';
        await tenant.save();
      }
      res.status(403).json({ detail: 'Trial expired. Contact platform admin to reactivate your trial.' });
      return;
    }
  }

  const deviceId = String(payload.device_id ?? '').trim();
  const deviceName = String(payload.device_name ?? '').trim() || 'Unknown Device';
  if (deviceId) {
    await DeviceSessionModel.findOneAndUpdate(
      { tenantId, deviceId },
      {
        tenantId,
        userId: 'activation-pending',
        deviceId,
        deviceName,
        lastSeenAt: new Date(),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  res.json({
    activation_valid: true,
    activation_code: activationCodeForTenant(tenant.tenantId),
    tenant_id: tenant.tenantId,
    store_name: tenant.storeName,
    trial_ends_at: tenant.trialEndsAt,
  });
});

// GET /api/v1/auth/subscription-status?tenant_id=xxx
authRouter.get('/subscription-status', async (req, res) => {
  const tenantId = String(req.query.tenant_id ?? '').trim().toLowerCase();
  if (!tenantId) {
    res.status(422).json({ detail: 'tenant_id is required' });
    return;
  }

  const tenant = await TenantModel.findOne({ tenantId });
  if (!tenant) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  const now = new Date();
  let isExpired = false;
  let status = tenant.status ?? 'TRIAL';

  if (status === 'SUSPENDED') {
    isExpired = true;
  } else if (tenant.planExpiresAt && now > tenant.planExpiresAt) {
    isExpired = true;
    status = 'EXPIRED';
    if (tenant.status !== 'EXPIRED') {
      tenant.status = 'EXPIRED';
      await tenant.save();
    }
  } else if (status === 'TRIAL' && tenant.trialEndsAt && now > tenant.trialEndsAt) {
    isExpired = true;
    status = 'EXPIRED';
    if (tenant.status !== 'EXPIRED') {
      tenant.status = 'EXPIRED';
      tenant.trialActive = false;
      await tenant.save();
    }
  }

  res.json({
    tenant_id: tenant.tenantId,
    store_name: tenant.storeName,
    plan_id: tenant.planId ?? 'trial',
    plan_name: tenant.planName ?? 'Trial',
    status,
    is_expired: isExpired,
    sync_enabled: tenant.syncEnabled ?? true,
    plan_expires_at: tenant.planExpiresAt,
    trial_ends_at: tenant.trialEndsAt,
    support_hotline: '+94 72 954 5538',
    support_email: 'contact@bizparkstudio.lk',
  });
});

authRouter.post('/users', requireAuth, async (req, res) => {
  if (!req.auth || !canManageTenantUsers(req.auth.role)) {
    res.status(403).json({ detail: 'Not allowed to create users' });
    return;
  }

  const payload = req.body as {
    tenant_id?: string;
    name?: string;
    email?: string;
    password?: string;
    role?: string;
    location_ids?: string[];
    active?: boolean;
  };

  const requestedTenantId = (payload.tenant_id ?? '').trim().toLowerCase();
  const targetTenantId =
    req.auth.role === 'platform_admin'
      ? requestedTenantId || req.auth.tenantId
      : req.auth.tenantId;
  const name = (payload.name ?? '').trim();
  const email = (payload.email ?? '').trim().toLowerCase();
  const password = payload.password ?? '';
  const role = (payload.role ?? 'manager').trim().toLowerCase();
  const locationIds = (payload.location_ids ?? [])
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0);
  const active = payload.active ?? true;

  if (!targetTenantId || !name || !email || !password) {
    res.status(422).json({ detail: 'Tenant id, name, email and password are required' });
    return;
  }

  if (role === 'platform_admin') {
    res.status(422).json({ detail: 'Invalid role for tenant user' });
    return;
  }

  const tenant = await TenantModel.findOne({ tenantId: targetTenantId }).lean();
  if (!tenant) {
    res.status(404).json({ detail: 'Tenant not found' });
    return;
  }

  const existingUser = await UserModel.findOne({ email }).lean();
  if (existingUser) {
    res.status(409).json({ detail: 'Email already exists' });
    return;
  }

  const createdUser = await UserModel.create({
    tenantId: targetTenantId,
    name,
    email,
    role,
    locationIds,
    passwordHash: await hashPassword(password),
    active,
  });

  res.status(201).json({
    user_id: String(createdUser._id),
    tenant_id: createdUser.tenantId,
    name: createdUser.name,
    email: createdUser.email,
    role: createdUser.role,
    location_ids: createdUser.locationIds,
    active: createdUser.active,
  });
});

authRouter.post('/users/password', requireAuth, async (req, res) => {
  if (!req.auth || !canManageTenantUsers(req.auth.role)) {
    res.status(403).json({ detail: 'Not allowed to update user credentials' });
    return;
  }

  const payload = req.body as {
    tenant_id?: string;
    email?: string;
    password?: string;
  };

  const requestedTenantId = (payload.tenant_id ?? '').trim().toLowerCase();
  const targetTenantId =
    req.auth.role === 'platform_admin'
      ? requestedTenantId || req.auth.tenantId
      : req.auth.tenantId;
  const email = (payload.email ?? '').trim().toLowerCase();
  const password = payload.password ?? '';

  if (!targetTenantId || !email || !password) {
    res.status(422).json({ detail: 'Tenant id, email and password are required' });
    return;
  }

  const user = await UserModel.findOne({ tenantId: targetTenantId, email });
  if (!user) {
    res.status(404).json({ detail: 'User not found' });
    return;
  }

  user.passwordHash = await hashPassword(password);
  await user.save();

  res.json({
    user_id: String(user._id),
    tenant_id: user.tenantId,
    email: user.email,
    password_updated: true,
  });
});

authRouter.get('/platform/stores', requireAuth, requirePlatformAdmin, async (_req, res) => {
  const stores = await TenantModel.find({ tenantId: { $ne: settings.platformTenantId } })
    .sort({ createdAt: -1 })
    .lean();

  res.json(
    stores.map((store) => ({
      tenant_id: store.tenantId,
      store_name: store.storeName,
      owner_email: store.ownerEmail,
      activation_code: activationCodeForTenant(store.tenantId),
      trial_starts_at: store.trialStartsAt,
      trial_ends_at: store.trialEndsAt,
      trial_active: store.trialActive,
      max_locations: store.maxLocations,
      max_users: store.maxUsers ?? 15,
      max_products: store.maxProducts ?? 500,
    }))
  );
});

authRouter.post('/platform/stores/:tenantId/trial/reactivate', requireAuth, requirePlatformAdmin, async (req, res) => {
  const normalizedTenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const daysRaw = Number(req.body?.days ?? 7);
  const days = Math.min(90, Math.max(1, Number.isNaN(daysRaw) ? 7 : daysRaw));
  const trialEndsRaw = req.body?.trialEndsAt ?? null;

  const store = await TenantModel.findOne({ tenantId: normalizedTenantId });
  if (!store || store.tenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  const now = new Date();
  let nextTrialEndsAt: Date;
  if (trialEndsRaw) {
    const parsed = new Date(String(trialEndsRaw));
    if (isNaN(parsed.getTime())) {
      res.status(422).json({ detail: 'Invalid trialEndsAt' });
      return;
    }
    if (parsed <= now) {
      res.status(422).json({ detail: 'trialEndsAt must be a future date' });
      return;
    }
    nextTrialEndsAt = parsed;
  } else {
    nextTrialEndsAt = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
  }

  store.trialStartsAt = now;
  store.trialEndsAt = nextTrialEndsAt;
  store.trialActive = true;
  // clear deactivation metadata when reactivating
  store.deactivatedAt = null as any;
  store.deactivatedBy = null as any;
  await store.save();

  res.json({
    tenant_id: store.tenantId,
    store_name: store.storeName,
    owner_email: store.ownerEmail,
    trial_starts_at: store.trialStartsAt,
    trial_ends_at: store.trialEndsAt,
    trial_active: store.trialActive,
    max_locations: store.maxLocations,
  });
});

authRouter.post('/platform/stores/:tenantId/deactivate', requireAuth, requirePlatformAdmin, async (req, res) => {
  const normalizedTenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  if (!normalizedTenantId || normalizedTenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  const store = await TenantModel.findOne({ tenantId: normalizedTenantId });
  if (!store) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  store.trialActive = false;
  store.deactivatedAt = new Date();
  // record who deactivated when available from auth
  try {
    // req.auth is set by requireAuth middleware
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const authAny = (req as any).auth;
    if (authAny && authAny.userId) store.deactivatedBy = String(authAny.userId);
  } catch (_) {}

  await store.save();

  res.json({
    tenant_id: store.tenantId,
    store_name: store.storeName,
    owner_email: store.ownerEmail,
    trial_starts_at: store.trialStartsAt,
    trial_ends_at: store.trialEndsAt,
    trial_active: store.trialActive,
    deactivated_at: store.deactivatedAt,
    deactivated_by: store.deactivatedBy,
    max_locations: store.maxLocations,
  });
});

authRouter.patch('/platform/stores/:tenantId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const normalizedTenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  const payload = req.body as {
    store_name?: string;
    owner_email?: string;
    owner_name?: string;
    max_locations?: number;
    max_users?: number;
    max_products?: number;
  };

  if (!normalizedTenantId || normalizedTenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  const store = await TenantModel.findOne({ tenantId: normalizedTenantId });
  if (!store) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  const nextStoreName = String(payload.store_name ?? '').trim();
  const nextOwnerEmail = String(payload.owner_email ?? '').trim().toLowerCase();
  const nextOwnerName = String(payload.owner_name ?? '').trim();
  const nextMaxLocations = payload.max_locations;
  const nextMaxUsers = payload.max_users;
  const nextMaxProducts = payload.max_products;

  if (nextStoreName) {
    store.storeName = nextStoreName;
  }

  if (nextOwnerEmail && nextOwnerEmail !== store.ownerEmail.toLowerCase()) {
    const existingEmailUser = await UserModel.findOne({ email: nextOwnerEmail }).lean();
    if (existingEmailUser && existingEmailUser.tenantId !== normalizedTenantId) {
      res.status(409).json({ detail: 'Email already exists' });
      return;
    }

    const ownerUser = await UserModel.findOne({ tenantId: normalizedTenantId, role: 'owner' });
    if (ownerUser) {
      ownerUser.email = nextOwnerEmail;
      if (nextOwnerName) {
        ownerUser.name = nextOwnerName;
      }
      await ownerUser.save();
    }
    store.ownerEmail = nextOwnerEmail;
  } else if (nextOwnerName) {
    const ownerUser = await UserModel.findOne({ tenantId: normalizedTenantId, role: 'owner' });
    if (ownerUser) {
      ownerUser.name = nextOwnerName;
      await ownerUser.save();
    }
  }

  if (nextMaxLocations !== undefined && nextMaxLocations > 0) {
    store.maxLocations = nextMaxLocations;
  }
  if (nextMaxUsers !== undefined && nextMaxUsers > 0) {
    store.maxUsers = nextMaxUsers;
  }
  if (nextMaxProducts !== undefined && nextMaxProducts > 0) {
    store.maxProducts = nextMaxProducts;
  }

  await store.save();

  res.json({
    tenant_id: store.tenantId,
    store_name: store.storeName,
    owner_email: store.ownerEmail,
    activation_code: activationCodeForTenant(store.tenantId),
    trial_starts_at: store.trialStartsAt,
    trial_ends_at: store.trialEndsAt,
    trial_active: store.trialActive,
    max_locations: store.maxLocations,
    max_users: store.maxUsers,
    max_products: store.maxProducts,
  });
});

authRouter.delete('/platform/stores/:tenantId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const normalizedTenantId = String(req.params.tenantId ?? '').trim().toLowerCase();
  if (!normalizedTenantId || normalizedTenantId === settings.platformTenantId) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  const store = await TenantModel.findOne({ tenantId: normalizedTenantId }).lean();
  if (!store) {
    res.status(404).json({ detail: 'Store not found' });
    return;
  }

  await Promise.all([
    UserModel.deleteMany({ tenantId: normalizedTenantId }),
    DeviceSessionModel.deleteMany({ tenantId: normalizedTenantId }),
    TenantModel.deleteOne({ tenantId: normalizedTenantId }),
  ]);

  res.status(204).send();
});

authRouter.post('/validate-offline-key', async (req, res) => {
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

export { authRouter };
