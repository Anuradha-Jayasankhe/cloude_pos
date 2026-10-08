import { Schema, model } from 'mongoose';

export interface UserDocument {
  tenantId: string;
  name: string;
  email: string;
  role: string;
  locationIds: string[];
  passwordHash: string;
  active: boolean;
  createdAt: Date;
}

const userSchema = new Schema<UserDocument>(
  {
    tenantId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    role: { type: String, required: true, default: 'manager', index: true },
    locationIds: { type: [String], required: true, default: [] },
    passwordHash: { type: String, required: true },
    active: { type: Boolean, required: true, default: true },
    createdAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

userSchema.index({ tenantId: 1, email: 1 }, { unique: true });

export const UserModel = model<UserDocument>('User', userSchema);
