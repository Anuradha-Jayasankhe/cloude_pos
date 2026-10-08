import { Schema, model } from 'mongoose';

export interface PlanDocument {
  planId: string;
  name: string;
  type: 'FREE' | 'TRIAL' | 'MONTHLY' | 'BIANNUAL' | 'ANNUAL' | 'CUSTOM' | 'OFFLINE';
  description: string;
  priceMonthly: number;
  priceYearly: number;
  durationDays: number; // 0 = no auto-expire / custom
  trialDays: number;
  maxUsers: number;
  maxProducts: number;
  maxLocations: number;
  syncEnabled: boolean;
  features: string[];
  isPublic: boolean;
  isActive: boolean;
  createdAt: Date;
}

const planSchema = new Schema<PlanDocument>(
  {
    planId: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true },
    type: {
      type: String,
      required: true,
      enum: ['FREE', 'TRIAL', 'MONTHLY', 'BIANNUAL', 'ANNUAL', 'CUSTOM', 'OFFLINE'],
      default: 'MONTHLY',
    },
    description: { type: String, required: false, default: '' },
    priceMonthly: { type: Number, required: true, default: 0 },
    priceYearly: { type: Number, required: true, default: 0 },
    durationDays: { type: Number, required: true, default: 30 },
    trialDays: { type: Number, required: true, default: 0 },
    maxUsers: { type: Number, required: true, default: 5 },
    maxProducts: { type: Number, required: true, default: 500 },
    maxLocations: { type: Number, required: true, default: 1 },
    syncEnabled: { type: Boolean, required: true, default: true },
    features: { type: [String], required: true, default: [] },
    isPublic: { type: Boolean, required: true, default: true },
    isActive: { type: Boolean, required: true, default: true },
    createdAt: { type: Date, required: true, default: Date.now },
  },
  { versionKey: false }
);

export const PlanModel = model<PlanDocument>('Plan', planSchema);
