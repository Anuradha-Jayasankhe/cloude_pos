import { Schema, model } from 'mongoose';

export interface SyncEventDocument {
  seq: number;
  tenantId: string;
  entity: string;
  entityId: string;
  action: string;
  payload: Record<string, unknown>;
  serverTs: Date;
  sourceDeviceId?: string;
  sourceUserId?: string;
  clientOpId?: string;
}

const syncEventSchema = new Schema<SyncEventDocument>(
  {
    seq: { type: Number, required: true, unique: true, index: true },
    tenantId: { type: String, required: true, index: true },
    entity: { type: String, required: true, index: true },
    entityId: { type: String, required: true, index: true },
    action: { type: String, required: true, index: true },
    payload: { type: Schema.Types.Mixed, required: true, default: {} },
    serverTs: { type: Date, required: true, default: Date.now, index: true },
    sourceDeviceId: { type: String, required: false, index: true },
    sourceUserId: { type: String, required: false, index: true },
    clientOpId: { type: String, required: false, index: true },
  },
  { versionKey: false }
);

// Sparse compound index for deduplication of retried push operations.
// Sparse because clientOpId is optional (operations without a client_op_id
// are still accepted but not deduplication-checked).
syncEventSchema.index({ tenantId: 1, clientOpId: 1 }, { sparse: true });

export const SyncEventModel = model<SyncEventDocument>('SyncEvent', syncEventSchema);
