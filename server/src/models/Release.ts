import { Schema, model } from 'mongoose';

export interface ReleaseDocument {
  version: string;
  platform: 'windows' | 'mac' | 'linux' | 'android' | 'ios';
  channel: 'stable' | 'beta' | 'alpha';
  downloadUrl: string;
  releaseNotes: string;
  releaseDate: Date;
  published: boolean;
  createdAt: Date;
}

const releaseSchema = new Schema<ReleaseDocument>(
  {
    version: { type: String, required: true, index: true },
    platform: {
      type: String,
      required: true,
      enum: ['windows', 'mac', 'linux', 'android', 'ios'],
      index: true,
    },
    channel: {
      type: String,
      required: true,
      enum: ['stable', 'beta', 'alpha'],
      default: 'stable',
      index: true,
    },
    downloadUrl: { type: String, required: false, default: '' },
    releaseNotes: { type: String, required: false, default: '' },
    releaseDate: { type: Date, required: true, default: Date.now },
    published: { type: Boolean, required: true, default: false, index: true },
    createdAt: { type: Date, required: true, default: Date.now },
  },
  { versionKey: false }
);

releaseSchema.index({ platform: 1, channel: 1, version: 1 }, { unique: true });

export const ReleaseModel = model<ReleaseDocument>('Release', releaseSchema);
