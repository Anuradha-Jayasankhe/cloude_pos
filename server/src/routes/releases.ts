import { Router } from 'express';
import { requireAuth, requirePlatformAdmin } from '../middleware/auth';
import { ReleaseModel } from '../models/Release';
import { logActivity } from '../models/ActivityLog';

const releasesRouter = Router();
const publicReleasesRouter = Router();

// GET /api/v1/releases — public endpoint for showcase website to fetch published releases
publicReleasesRouter.get('/', async (req, res) => {
  const platform = String(req.query.platform ?? '').trim().toLowerCase();
  const channel = String(req.query.channel ?? '').trim().toLowerCase();

  const query: Record<string, unknown> = { published: true };
  if (platform) query.platform = platform;
  if (channel) query.channel = channel;

  const releases = await ReleaseModel.find(query).sort({ releaseDate: -1, createdAt: -1 }).lean();

  res.json(releases.map(r => ({
    id: String(r._id),
    version: r.version,
    platform: r.platform,
    channel: r.channel,
    download_url: r.downloadUrl,
    release_notes: r.releaseNotes,
    release_date: r.releaseDate,
    published: r.published,
    created_at: r.createdAt,
  })));
});

// GET /api/v1/releases/latest — public endpoint for POS and website to check latest version
publicReleasesRouter.get('/latest', async (req, res) => {
  const platform = String(req.query.platform ?? 'windows').trim().toLowerCase();
  const channel = String(req.query.channel ?? 'stable').trim().toLowerCase();

  const release = await ReleaseModel.findOne({ platform, channel, published: true })
    .sort({ releaseDate: -1 })
    .lean();

  if (!release) {
    res.status(404).json({ detail: 'No published release found' });
    return;
  }

  res.json({
    id: String(release._id),
    version: release.version,
    platform: release.platform,
    channel: release.channel,
    download_url: release.downloadUrl,
    release_notes: release.releaseNotes,
    release_date: release.releaseDate,
    published: release.published,
  });
});

// GET /api/v1/admin/releases
releasesRouter.get('/', requireAuth, requirePlatformAdmin, async (req, res) => {
  const platform = String(req.query.platform ?? '').trim().toLowerCase();
  const channel = String(req.query.channel ?? '').trim().toLowerCase();
  const publishedOnly = String(req.query.published ?? 'false').toLowerCase() === 'true';

  const query: Record<string, unknown> = {};
  if (platform) query.platform = platform;
  if (channel) query.channel = channel;
  if (publishedOnly) query.published = true;

  const releases = await ReleaseModel.find(query).sort({ releaseDate: -1, createdAt: -1 }).lean();

  res.json(releases.map(r => ({
    id: String(r._id),
    version: r.version,
    platform: r.platform,
    channel: r.channel,
    download_url: r.downloadUrl,
    release_notes: r.releaseNotes,
    release_date: r.releaseDate,
    published: r.published,
    created_at: r.createdAt,
  })));
});

// GET /api/v1/admin/releases/latest — public endpoint for POS to check for updates
releasesRouter.get('/latest', async (req, res) => {
  const platform = String(req.query.platform ?? 'windows').trim().toLowerCase();
  const channel = String(req.query.channel ?? 'stable').trim().toLowerCase();

  const release = await ReleaseModel.findOne({ platform, channel, published: true })
    .sort({ releaseDate: -1 })
    .lean();

  if (!release) {
    res.status(404).json({ detail: 'No published release found' });
    return;
  }

  res.json({
    version: release.version,
    platform: release.platform,
    channel: release.channel,
    download_url: release.downloadUrl,
    release_notes: release.releaseNotes,
    release_date: release.releaseDate,
  });
});

// POST /api/v1/admin/releases
releasesRouter.post('/', requireAuth, requirePlatformAdmin, async (req, res) => {
  const body = req.body as Record<string, unknown>;
  const version = String(body.version ?? '').trim();
  const platform = String(body.platform ?? '').trim().toLowerCase();
  const channel = String(body.channel ?? 'stable').trim().toLowerCase();

  if (!version || !platform) {
    res.status(422).json({ detail: 'version and platform are required' });
    return;
  }

  const existing = await ReleaseModel.findOne({ version, platform, channel }).lean();
  if (existing) {
    res.status(409).json({ detail: 'Release already exists for this version/platform/channel' });
    return;
  }

  const release = await ReleaseModel.create({
    version,
    platform,
    channel,
    downloadUrl: String(body.download_url ?? ''),
    releaseNotes: String(body.release_notes ?? ''),
    releaseDate: body.release_date ? new Date(String(body.release_date)) : new Date(),
    published: Boolean(body.published ?? false),
  });

  await logActivity({
    tenantId: req.auth!.tenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'CREATE_RELEASE',
    resource: 'releases',
    resourceId: String(release._id),
    details: `Created release v${version} for ${platform}/${channel}`,
  });

  res.status(201).json({ id: String(release._id), version: release.version, platform: release.platform });
});

// PATCH /api/v1/admin/releases/:id
releasesRouter.patch('/:id', requireAuth, requirePlatformAdmin, async (req, res) => {
  const { id } = req.params;
  const release = await ReleaseModel.findById(id);
  if (!release) {
    res.status(404).json({ detail: 'Release not found' });
    return;
  }

  const body = req.body as Record<string, unknown>;
  if (body.download_url !== undefined) release.downloadUrl = String(body.download_url);
  if (body.release_notes !== undefined) release.releaseNotes = String(body.release_notes);
  if (body.release_date !== undefined) release.releaseDate = new Date(String(body.release_date));
  if (body.published !== undefined) release.published = Boolean(body.published);
  if (body.channel !== undefined) release.channel = String(body.channel) as any;

  await release.save();

  await logActivity({
    tenantId: req.auth!.tenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'UPDATE_RELEASE',
    resource: 'releases',
    resourceId: id,
    details: `Updated release v${release.version}: published=${release.published}`,
  });

  res.json({ id, updated: true, published: release.published });
});

// DELETE /api/v1/admin/releases/:id
releasesRouter.delete('/:id', requireAuth, requirePlatformAdmin, async (req, res) => {
  const { id } = req.params;
  const release = await ReleaseModel.findByIdAndDelete(id).lean();
  if (!release) {
    res.status(404).json({ detail: 'Release not found' });
    return;
  }

  await logActivity({
    tenantId: req.auth!.tenantId,
    userId: req.auth!.userId,
    userName: 'Platform Admin',
    action: 'DELETE_RELEASE',
    resource: 'releases',
    resourceId: id,
    details: `Deleted release v${release.version} for ${release.platform}`,
  });

  res.status(204).send();
});

export { releasesRouter, publicReleasesRouter };
