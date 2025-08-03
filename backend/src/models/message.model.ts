import mongoose, { Schema, Document } from 'mongoose';

export interface IMessage extends Document {
  from: string; // id do usuário remetente
  to: string;   // id do usuário destinatário
  content: string;
  type: 'text' | 'sticker';
  timestamp: Date;
}

const MessageSchema: Schema = new Schema({
  from: { type: String, required: true },
  to: { type: String, required: true },
  content: { type: String, required: true },
  type: { type: String, enum: ['text', 'sticker'], required: true },
  timestamp: { type: Date, default: Date.now }
});

const Message = mongoose.model<IMessage>('Message', MessageSchema);

export default Message;
