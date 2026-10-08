import dotenv from 'dotenv';

dotenv.config();

const parseOrigins = (value: string): string[] => {
  const trimmed = value.trim();
  if (!trimmed || trimmed === '*') return ['*'];
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    try {
      const parsed = JSON.parse(trimmed);
      if (Array.isArray(parsed)) {
        return parsed.map((x) => String(x).trim()).filter(Boolean);
      }
    } catch {
      // Fall back to CSV parsing.
    }
  }
  return trimmed
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean);
};

export const settings = {
  appName: process.env.APP_NAME ?? 'StoreBuddy Sync Server (TypeScript)',
  apiPrefix: process.env.API_PREFIX ?? '/api/v1',
  port: Number(process.env.PORT ?? 5000),
  jwtSecret: process.env.JWT_SECRET ?? 'change-this-secret-in-production',
  jwtAlgorithm: process.env.JWT_ALGORITHM ?? 'HS256',
  accessTokenExpireMinutes: Number(process.env.ACCESS_TOKEN_EXPIRE_MINUTES ?? 1440),
  mongoUri: process.env.MONGODB_URI ?? 'mongodb+srv://anuradha:anuradha@anuradha.av9fjk8.mongodb.net/storebuddy_sync?retryWrites=true&w=majority',
  corsAllowOrigins: parseOrigins(process.env.CORS_ALLOW_ORIGINS ?? '*'),
  defaultTrialDays: Math.max(1, Number(process.env.DEFAULT_TRIAL_DAYS ?? 7)),
  platformTenantId: (process.env.PLATFORM_TENANT_ID ?? 'platform').trim().toLowerCase(),
  platformAdminName: process.env.PLATFORM_ADMIN_NAME ?? 'Platform Admin',
  platformAdminEmail: (process.env.PLATFORM_ADMIN_EMAIL ?? 'admin@storebuddy.com').trim().toLowerCase(),
  platformAdminPassword: process.env.PLATFORM_ADMIN_PASSWORD ?? 'admin123',
};
