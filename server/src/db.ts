import dns from 'dns';
import mongoose from 'mongoose';

import { settings } from './config';

// Ensure Windows local Node DNS resolves MongoDB Atlas SRV reliably without breaking Vercel/Linux serverless
if (process.platform === 'win32' && process.env.VERCEL !== '1') {
  try {
    dns.setServers(['8.8.8.8', '1.1.1.1', '8.8.4.4']);
  } catch {
    // Ignore if custom DNS cannot be configured in this environment
  }
}

export const connectDb = async (): Promise<void> => {
  if (mongoose.connection.readyState >= 1) return;

  try {
    await mongoose.connect(settings.mongoUri, {
      serverSelectionTimeoutMS: 10000,
    });
    console.log(`[Database] Connected successfully to MongoDB (${settings.mongoUri})`);
  } catch (primaryErr) {
    // Cloud Atlas fallback
    const cloudUri = 'mongodb+srv://anuradha:anuradha@anuradha.av9fjk8.mongodb.net/storebuddy_sync?retryWrites=true&w=majority';
    if (settings.mongoUri !== cloudUri) {
      try {
        console.warn(`[Database] Primary MongoDB (${settings.mongoUri}) failed. Attempting cloud MongoDB Atlas fallback...`);
        await mongoose.connect(cloudUri, {
          serverSelectionTimeoutMS: 5000,
        });
        console.log('[Database] Connected successfully to Cloud MongoDB Atlas');
        return;
      } catch (fallbackErr) {
        console.error('[Database] Could not connect to fallback cloud MongoDB:', (fallbackErr as Error).message);
      }
    }
    throw primaryErr;
  }
};
