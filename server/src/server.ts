import cors from 'cors';
import express from 'express';
import fs from 'fs';
import path from 'path';

import { bootstrapPlatform } from './bootstrap';
import { settings } from './config';
import { connectDb } from './db';
import { adminRouter } from './routes/admin';
import { authRouter } from './routes/auth';
import { healthRouter } from './routes/health';
import { plansRouter } from './routes/plans';
import { releasesRouter, publicReleasesRouter } from './routes/releases';
import { syncRouter } from './routes/sync';
import { whatsappRouter } from './routes/whatsapp';

// Server instance configuration
const app = express();

app.use(express.json({ limit: '2mb' }));
app.use(
  cors({
    origin: settings.corsAllowOrigins,
    credentials: true,
  })
);

// ── 1. Static File Serving (Always accessible, zero database dependency) ──

// Serve the admin panel SPA static files from /admin with no-cache for instant live development
const adminDir = path.join(__dirname, '../admin');
app.use('/admin', express.static(adminDir, {
  etag: false,
  maxAge: 0,
  setHeaders: (res) => {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }
}));
// Fallback for SPA navigation in admin panel
app.get('/admin/*', (_req, res) => {
  const adminIndex = path.join(adminDir, 'index.html');
  if (fs.existsSync(adminIndex)) {
    return res.sendFile(adminIndex);
  }
  res.status(404).json({ detail: 'Admin UI not bundled in this deployment' });
});

// Serve the product showcase & downloads website from root /
const websiteDir = path.join(__dirname, '../../website');
app.use(express.static(websiteDir));

// Root route serves the product showcase landing page if present, or API status
app.get('/', (_req, res) => {
  const websiteIndex = path.join(websiteDir, 'index.html');
  if (fs.existsSync(websiteIndex)) {
    return res.sendFile(websiteIndex);
  }
  res.json({
    status: 'ok',
    app: settings.appName,
    api: settings.apiPrefix,
    documentation: `${settings.apiPrefix}/releases`,
  });
});

// ── 2. Health Check ──
app.use(healthRouter);
app.use(`${settings.apiPrefix}`, healthRouter);

// ── 3. Database connection & bootstrap middleware for API endpoints ──
let isBootstrapped = false;
app.use(settings.apiPrefix, async (req, res, next) => {
  try {
    await connectDb();
    if (!isBootstrapped) {
      await bootstrapPlatform();
      isBootstrapped = true;
    }
    next();
  } catch (error) {
    console.error('Database connection or bootstrap failed for API request:', (error as Error).message);
    // If it's a public read endpoint like releases, publicReleasesRouter handles fallbacks gracefully
    if (req.path.startsWith('/releases')) {
      return next();
    }
    res.status(503).json({ detail: 'Database connecting or unavailable. Please try again in a moment.' });
  }
});

// ── 4. API Routes ──
app.use(`${settings.apiPrefix}/releases`, publicReleasesRouter);
app.use(`${settings.apiPrefix}/auth`, authRouter);
app.use(`${settings.apiPrefix}/sync`, syncRouter);
app.use(`${settings.apiPrefix}/admin/plans`, plansRouter);
app.use(`${settings.apiPrefix}/admin/releases`, releasesRouter);
app.use(`${settings.apiPrefix}/admin`, adminRouter);
app.use(`${settings.apiPrefix}/whatsapp`, whatsappRouter);
app.use('/api/whatsapp', whatsappRouter);

// ── 5. Server Startup ──
const start = async (): Promise<void> => {
  // Always start HTTP listener first so web routes are immediately responsive
  const server = app.listen(settings.port, '0.0.0.0', () => {
    console.log(`=================================================`);
    console.log(`  ${settings.appName}`);
    console.log(`  Website:     http://localhost:${settings.port}/`);
    console.log(`  Admin Panel: http://localhost:${settings.port}/admin`);
    console.log(`  API Prefix:  http://localhost:${settings.port}${settings.apiPrefix}`);
    console.log(`=================================================`);
  });

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`[Server] Port ${settings.port} is already in use by another process.`);
    } else {
      console.error('[Server] HTTP listener error:', err.message);
    }
  });

  // Asynchronously connect to database and bootstrap platform data
  try {
    await connectDb();
    await bootstrapPlatform();
    isBootstrapped = true;
  } catch (error) {
    console.warn('[Server] Warning: Database connection or bootstrap failed on startup:', (error as Error).message);
    console.warn('[Server] The website and admin panel static UI are active. API will reconnect when database becomes available.');
  }
};

if (process.env.VERCEL !== '1') {
  start().catch((error) => {
    console.error('[Server] Unexpected startup failure:', error);
  });
}

export { app };
export default app;
