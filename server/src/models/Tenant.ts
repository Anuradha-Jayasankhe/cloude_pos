import { Schema, model } from 'mongoose';

export interface TenantDocument {
  tenantId: string;
  storeName: string;
  ownerEmail: string;
  ownerPhone: string;
  address: string;
  // Legacy trial fields (kept for backward compatibility)
  trialStartsAt: Date;
  trialEndsAt: Date;
  trialActive: boolean;
  deactivatedAt?: Date | null;
  deactivatedBy?: string | null;
  maxLocations: number;
  // Plan fields
  planId: string;
  planName: string;
  planExpiresAt?: Date | null;
  planAssignedAt?: Date | null;
  syncEnabled: boolean;
  status: 'ACTIVE' | 'TRIAL' | 'SUSPENDED' | 'OFFLINE' | 'EXPIRED';
  offlineLicenseKey?: string | null;
  maxUsers: number;
  maxProducts: number;
  createdAt: Date;
}

const tenantSchema = new Schema<TenantDocument>(
  {
    tenantId: { type: String, required: true, unique: true, index: true },
    storeName: { type: String, required: true },
    ownerEmail: { type: String, required: true, unique: true, index: true },
    ownerPhone: { type: String, required: false, default: '' },
    address: { type: String, required: false, default: '' },
    // Legacy
    trialStartsAt: { type: Date, required: true, index: true },
    trialEndsAt: { type: Date, required: true, index: true },
    trialActive: { type: Boolean, required: true, default: true, index: true },
    deactivatedAt: { type: Date, required: false, default: null },
    deactivatedBy: { type: String, required: false, default: null },
    maxLocations: { type: Number, required: true, default: 3 },
    // Plan
    planId: { type: String, required: false, default: 'trial', index: true },
    planName: { type: String, required: false, default: 'Trial' },
    planExpiresAt: { type: Date, required: false, default: null },
    planAssignedAt: { type: Date, required: false, default: null },
    syncEnabled: { type: Boolean, required: false, default: true },
    status: {
      type: String,
      required: false,
      default: 'TRIAL',
      enum: ['ACTIVE', 'TRIAL', 'SUSPENDED', 'OFFLINE', 'EXPIRED'],
      index: true,
    },
    offlineLicenseKey: { type: String, required: false, default: null },
    maxUsers: { type: Number, required: false, default: 15 },
    maxProducts: { type: Number, required: false, default: 500 },
    createdAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

export const TenantModel = model<TenantDocument>('Tenant', tenantSchema);
