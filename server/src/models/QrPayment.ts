import { Schema, model } from 'mongoose';

export interface QrPaymentDocument {
  tenantId: string;
  storeName: string;
  amount: number;
  paymentMethod: string;
  status: 'PAID' | 'PENDING' | 'FAILED' | 'EXPIRED' | 'CANCELLED';
  orderId: string;
  customerType: string;
  reference: string;
  qrReference: string;
  saleId: string;
  method: string;
  statusMsg: string;
  createdAt: Date;
}

const qrPaymentSchema = new Schema<QrPaymentDocument>(
  {
    tenantId: { type: String, required: true, index: true },
    storeName: { type: String, required: true },
    amount: { type: Number, required: true },
    paymentMethod: { type: String, required: true, default: 'HELAPAY' },
    status: {
      type: String,
      required: true,
      enum: ['PAID', 'PENDING', 'FAILED', 'EXPIRED', 'CANCELLED'],
      default: 'PENDING',
      index: true,
    },
    orderId: { type: String, required: true },
    customerType: { type: String, required: true, default: 'Walk-In Customer' },
    reference: { type: String, required: true },
    qrReference: { type: String, required: true },
    saleId: { type: String, required: true, default: 'Pending' },
    method: { type: String, required: true, default: 'Unknown' },
    statusMsg: { type: String, required: true, default: 'Success' },
    createdAt: { type: Date, required: true, default: Date.now, index: true },
  },
  { versionKey: false }
);

export const QrPaymentModel = model<QrPaymentDocument>('QrPayment', qrPaymentSchema);
