import { Schema, model } from 'mongoose';

export interface CounterDocument {
  key: string;
  value: number;
}

const counterSchema = new Schema<CounterDocument>(
  {
    key: { type: String, required: true, unique: true, index: true },
    value: { type: Number, required: true, default: 0 },
  },
  { versionKey: false }
);

export const CounterModel = model<CounterDocument>('Counter', counterSchema);
