import { Schema, model } from 'mongoose';

export interface SyncRecordDocument {
  tenantId: string;
  entity: string;
  entityId: string;
  payload: Record<string, unknown>;
  deleted: boolean;
  updatedAt: Date;
}

const syncRecordSchema = new Schema<SyncRecordDocument>(
  {
    tenantId: { type: String, required: true, index: true },
    entity: { type: String, required: true, index: true },
    entityId: { type: String, required: true, index: true },
    payload: { type: Schema.Types.Mixed, required: true, default: {} },
    deleted: { type: Boolean, required: true, default: false, index: true },
    updatedAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

syncRecordSchema.index({ tenantId: 1, entity: 1, entityId: 1 }, { unique: true });

export const SyncRecordModel = model<SyncRecordDocument>('SyncRecord', syncRecordSchema);
