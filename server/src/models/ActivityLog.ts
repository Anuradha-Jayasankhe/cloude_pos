import { Schema, model } from 'mongoose';

export interface ActivityLogDocument {
  tenantId: string;
  userId: string;
  userName: string;
  action: string;
  resource: string;
  resourceId: string;
  details: string;
  ipAddress: string;
  createdAt: Date;
}

const activityLogSchema = new Schema<ActivityLogDocument>(
  {
    tenantId: { type: String, required: true, index: true },
    userId: { type: String, required: true, index: true },
    userName: { type: String, required: true, default: '' },
    action: { type: String, required: true, index: true },
    resource: { type: String, required: true, index: true },
    resourceId: { type: String, required: false, default: '' },
    details: { type: String, required: false, default: '' },
    ipAddress: { type: String, required: false, default: '' },
    createdAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

activityLogSchema.index({ tenantId: 1, createdAt: -1 });
activityLogSchema.index({ createdAt: -1 });

export const ActivityLogModel = model<ActivityLogDocument>('ActivityLog', activityLogSchema);

export const logActivity = async (args: {
  tenantId: string;
  userId: string;
  userName: string;
  action: string;
  resource: string;
  resourceId?: string;
  details?: string;
  ipAddress?: string;
}): Promise<void> => {
  try {
    await ActivityLogModel.create({
      tenantId: args.tenantId,
      userId: args.userId,
      userName: args.userName,
      action: args.action,
      resource: args.resource,
      resourceId: args.resourceId ?? '',
      details: args.details ?? '',
      ipAddress: args.ipAddress ?? '',
    });
  } catch {
    // Non-critical — never crash the request if logging fails
  }
};
