import { Schema, model } from 'mongoose';

export interface DeviceSessionDocument {
  tenantId: string;
  userId: string;
  deviceId: string;
  deviceName: string;
  lastSeenAt: Date;
  lastPushAt?: Date;
  lastPullAt?: Date;
  lastSyncAt?: Date;
  lastAppliedSeq: number;
  lastSyncStatus: string;
  lastSyncError?: string;
}

const deviceSessionSchema = new Schema<DeviceSessionDocument>(
  {
    tenantId: { type: String, required: true, index: true },
    userId: { type: String, required: true, index: true },
    deviceId: { type: String, required: true, index: true },
    deviceName: { type: String, required: true, default: 'Unknown Device' },
    lastSeenAt: { type: Date, required: true, default: Date.now, index: true },
    lastPushAt: { type: Date, required: false, index: true },
    lastPullAt: { type: Date, required: false, index: true },
    lastSyncAt: { type: Date, required: false, index: true },
    lastAppliedSeq: { type: Number, required: true, default: 0, index: true },
    lastSyncStatus: { type: String, required: true, default: 'unknown', index: true },
    lastSyncError: { type: String, required: false, default: '' },
  },
  { versionKey: false }
);

deviceSessionSchema.index({ tenantId: 1, deviceId: 1 }, { unique: true });

export const DeviceSessionModel = model<DeviceSessionDocument>('DeviceSession', deviceSessionSchema);
