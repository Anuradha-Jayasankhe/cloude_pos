import { Router } from 'express';
import { requireAuth, requirePlatformAdmin } from '../middleware/auth';
import { PlanModel } from '../models/Plan';
import { logActivity } from '../models/ActivityLog';

const plansRouter = Router();

// GET /api/v1/admin/plans — list all plans
plansRouter.get('/', requireAuth, requirePlatformAdmin, async (_req, res) => {
  const plans = await PlanModel.find().sort({ priceMonthly: 1 }).lean();
  res.json(plans.map(p => ({
    plan_id: p.planId,
    name: p.name,
    type: p.type,
    description: p.description,
    price_monthly: p.priceMonthly,
    price_yearly: p.priceYearly,
    duration_days: p.durationDays,
    trial_days: p.trialDays,
    max_users: p.maxUsers,
    max_products: p.maxProducts,
    max_locations: p.maxLocations,
    sync_enabled: p.syncEnabled,
    features: p.features,
    is_public: p.isPublic,
    is_active: p.isActive,
    created_at: p.createdAt,
  })));
});

// POST /api/v1/admin/plans — create plan
plansRouter.post('/', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, unknown>;
  const planId = String(body.plan_id ?? '').trim().toLowerCase().replace(/\s+/g, '-');
  if (!planId || !body.name) {
    res.status(422).json({ detail: 'plan_id and name are required' });
    return;
  }

  const existing = await PlanModel.findOne({ planId }).lean();
  if (existing) {
    res.status(409).json({ detail: 'Plan ID already exists' });
    return;
  }

  const plan = await PlanModel.create({
    planId,
    name: String(body.name ?? ''),
    type: String(body.type ?? 'MONTHLY').toUpperCase(),
    description: String(body.description ?? ''),
    priceMonthly: Number(body.price_monthly ?? 0),
    priceYearly: Number(body.price_yearly ?? 0),
    durationDays: Number(body.duration_days ?? 30),
    trialDays: Number(body.trial_days ?? 0),
    maxUsers: Number(body.max_users ?? 5),
    maxProducts: Number(body.max_products ?? 500),
    maxLocations: Number(body.max_locations ?? 1),
    syncEnabled: Boolean(body.sync_enabled ?? true),
    features: Array.isArray(body.features) ? body.features.map(String) : [],
    isPublic: Boolean(body.is_public ?? true),
    isActive: Boolean(body.is_active ?? true),
  });

  await logActivity({
    tenantId: req.auth!.tenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'CREATE_PLAN',
    resource: 'plans',
    resourceId: planId,
    details: `Created plan: ${plan.name}`,
  });

  res.status(201).json({ plan_id: plan.planId, name: plan.name });
});

// PATCH /api/v1/admin/plans/:planId — edit plan
plansRouter.patch('/:planId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const planId = String(req.params.planId ?? '').trim().toLowerCase();
  const plan = await PlanModel.findOne({ planId });
  if (!plan) {
    res.status(404).json({ detail: 'Plan not found' });
    return;
  }

  const body = req.body as Record<string, unknown>;
  if (body.name !== undefined) plan.name = String(body.name);
  if (body.type !== undefined) plan.type = String(body.type).toUpperCase() as any;
  if (body.description !== undefined) plan.description = String(body.description);
  if (body.price_monthly !== undefined) plan.priceMonthly = Number(body.price_monthly);
  if (body.price_yearly !== undefined) plan.priceYearly = Number(body.price_yearly);
  if (body.duration_days !== undefined) plan.durationDays = Number(body.duration_days);
  if (body.trial_days !== undefined) plan.trialDays = Number(body.trial_days);
  if (body.max_users !== undefined) plan.maxUsers = Number(body.max_users);
  if (body.max_products !== undefined) plan.maxProducts = Number(body.max_products);
  if (body.max_locations !== undefined) plan.maxLocations = Number(body.max_locations);
  if (body.sync_enabled !== undefined) plan.syncEnabled = Boolean(body.sync_enabled);
  if (body.is_public !== undefined) plan.isPublic = Boolean(body.is_public);
  if (body.is_active !== undefined) plan.isActive = Boolean(body.is_active);
  if (Array.isArray(body.features)) plan.features = body.features.map(String);

  await plan.save();

  await logActivity({
    tenantId: req.auth!.tenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'UPDATE_PLAN',
    resource: 'plans',
    resourceId: planId,
    details: `Updated plan: ${plan.name}`,
  });

  res.json({ plan_id: plan.planId, name: plan.name, updated: true });
});

// DELETE /api/v1/admin/plans/:planId — soft-delete (deactivate)
plansRouter.delete('/:planId', requireAuth, requirePlatformAdmin, async (req, res) => {
  const planId = String(req.params.planId ?? '').trim().toLowerCase();
  const protectedPlans = ['free', 'trial', 'offline'];
  if (protectedPlans.includes(planId)) {
    res.status(403).json({ detail: 'Cannot delete built-in plans' });
    return;
  }

  const plan = await PlanModel.findOne({ planId });
  if (!plan) {
    res.status(404).json({ detail: 'Plan not found' });
    return;
  }

  plan.isActive = false;
  await plan.save();

  await logActivity({
    tenantId: req.auth!.tenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'DELETE_PLAN',
    resource: 'plans',
    resourceId: planId,
    details: `Deactivated plan: ${plan.name}`,
  });

  res.json({ plan_id: plan.planId, deactivated: true });
});

export { plansRouter };
