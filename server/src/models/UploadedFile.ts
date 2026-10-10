import { Schema, model } from 'mongoose';

export interface UploadedFileDocument {
  filename: string;
  folder: string;
  mimeType: string;
  data: Buffer;
  size: number;
  createdAt: Date;
}

const uploadedFileSchema = new Schema<UploadedFileDocument>(
  {
    filename: { type: String, required: true, unique: true, index: true },
    folder: { type: String, required: true, default: 'products', index: true },
    mimeType: { type: String, required: true, default: 'image/png' },
    data: { type: Buffer, required: true },
    size: { type: Number, required: true },
    createdAt: { type: Date, required: true, default: Date.now },
  },
  { versionKey: false }
);

export const UploadedFileModel = model<UploadedFileDocument>('UploadedFile', uploadedFileSchema);
