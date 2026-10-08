import { Schema, model } from 'mongoose';

export interface PlatformSettingDocument {
  key: string;
  value: any;
  updatedAt: Date;
}

const platformSettingSchema = new Schema<PlatformSettingDocument>(
  {
    key: { type: String, required: true, unique: true, index: true },
    value: { type: Schema.Types.Mixed, required: true },
    updatedAt: { type: Date, required: true, default: Date.now },
  },
  { versionKey: false }
);

export const PlatformSettingModel = model<PlatformSettingDocument>('PlatformSetting', platformSettingSchema);
