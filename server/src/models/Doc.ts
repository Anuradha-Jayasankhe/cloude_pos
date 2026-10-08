import { Schema, model } from 'mongoose';

export interface DocDocument {
  title: string;
  content: string;
  section: string;
  status: 'PUBLISHED' | 'DRAFT';
  audience: 'All Users' | 'Owners' | 'Staff';
  roles: string[];
  updatedAt: Date;
  createdAt: Date;
}

const docSchema = new Schema<DocDocument>(
  {
    title: { type: String, required: true },
    content: { type: String, required: true },
    section: { type: String, required: true, default: 'Getting Started', index: true },
    status: {
      type: String,
      required: true,
      enum: ['PUBLISHED', 'DRAFT'],
      default: 'PUBLISHED',
      index: true,
    },
    audience: {
      type: String,
      required: true,
      enum: ['All Users', 'Owners', 'Staff'],
      default: 'All Users',
      index: true,
    },
    roles: { type: [String], required: true, default: [] },
    updatedAt: { type: Date, required: true, default: Date.now },
    createdAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

export const DocModel = model<DocDocument>('Doc', docSchema);
