import { Schema, model } from 'mongoose';

export interface TutorialDocument {
  title: string;
  description: string;
  thumbnailUrl: string;
  videoUrl: string;
  audience: 'All Users' | 'Owners' | 'Staff';
  status: 'PUBLISHED' | 'DRAFT';
  createdAt: Date;
}

const tutorialSchema = new Schema<TutorialDocument>(
  {
    title: { type: String, required: true },
    description: { type: String, required: true },
    thumbnailUrl: { type: String, required: false, default: '' },
    videoUrl: { type: String, required: false, default: '' },
    audience: {
      type: String,
      required: true,
      enum: ['All Users', 'Owners', 'Staff'],
      default: 'All Users',
      index: true,
    },
    status: {
      type: String,
      required: true,
      enum: ['PUBLISHED', 'DRAFT'],
      default: 'PUBLISHED',
      index: true,
    },
    createdAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

export const TutorialModel = model<TutorialDocument>('Tutorial', tutorialSchema);
