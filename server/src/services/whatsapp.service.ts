import type { WASocket, ConnectionState } from '@whiskeysockets/baileys';
import QRCode from 'qrcode';
import fs from 'fs';
import os from 'os';
import path from 'path';
import pino from 'pino';

const loadBaileys = async () => {
  const dynamicImport = new Function('specifier', 'return import(specifier)');
  return dynamicImport('@whiskeysockets/baileys');
};

export type WhatsAppSessionStatus = 'DISCONNECTED' | 'SCAN_QR' | 'CONNECTING' | 'CONNECTED';

interface TenantSession {
  sock: WASocket | null;
  status: WhatsAppSessionStatus;
  qrCodeDataUrl: string | null;
  phoneNumber: string | null;
  lastConnectedAt: Date | null;
  isInitializing: boolean;
}

class WhatsAppService {
  private sessions = new Map<string, TenantSession>();
  private baseStorageDir: string;

  constructor() {
    const isServerless = process.env.VERCEL === '1' || Boolean(process.env.AWS_LAMBDA_FUNCTION_NAME);
    this.baseStorageDir = isServerless
      ? path.join(os.tmpdir(), 'data', 'whatsapp_sessions')
      : path.join(process.cwd(), 'data', 'whatsapp_sessions');

    try {
      if (!fs.existsSync(this.baseStorageDir)) {
        fs.mkdirSync(this.baseStorageDir, { recursive: true });
      }
    } catch (err) {
      console.warn('[WhatsAppService] Could not initialize storage directory:', (err as Error).message);
    }
  }

  private getSessionFolder(tenantId: string): string {
    const safeTenant = tenantId.replace(/[^a-zA-Z0-9_-]/g, '_');
    const folder = path.join(this.baseStorageDir, safeTenant);
    try {
      if (!fs.existsSync(folder)) {
        fs.mkdirSync(folder, { recursive: true });
      }
    } catch (err) {
      console.warn('[WhatsAppService] Could not initialize tenant folder:', (err as Error).message);
    }
    return folder;
  }

  public getStatus(tenantId: string): {
    status: WhatsAppSessionStatus;
    qrCodeDataUrl: string | null;
    phoneNumber: string | null;
    lastConnectedAt: Date | null;
  } {
    const session = this.sessions.get(tenantId);
    if (!session) {
      return {
        status: 'DISCONNECTED',
        qrCodeDataUrl: null,
        phoneNumber: null,
        lastConnectedAt: null,
      };
    }
    return {
      status: session.status,
      qrCodeDataUrl: session.qrCodeDataUrl,
      phoneNumber: session.phoneNumber,
      lastConnectedAt: session.lastConnectedAt,
    };
  }

  public async initSession(tenantId: string): Promise<TenantSession> {
    let session = this.sessions.get(tenantId);
    if (session && (session.status === 'CONNECTED' || session.isInitializing)) {
      return session;
    }

    if (!session) {
      session = {
        sock: null,
        status: 'CONNECTING',
        qrCodeDataUrl: null,
        phoneNumber: null,
        lastConnectedAt: null,
        isInitializing: true,
      };
      this.sessions.set(tenantId, session);
    } else {
      session.isInitializing = true;
      session.status = 'CONNECTING';
    }

    const sessionDir = this.getSessionFolder(tenantId);
    const baileys = await loadBaileys();
    const makeWASocket = baileys.default || baileys.makeWASocket || baileys;
    const { useMultiFileAuthState, fetchLatestBaileysVersion, DisconnectReason } = baileys;

    const { state, saveCreds } = await useMultiFileAuthState(sessionDir);
    const { version } = await fetchLatestBaileysVersion();

    const logger = pino({ level: 'silent' });

    const sock = (makeWASocket as any).default
      ? (makeWASocket as any).default({
          version,
          auth: state,
          logger,
          printQRInTerminal: false,
        })
      : (makeWASocket as any)({
          version,
          auth: state,
          logger,
          printQRInTerminal: false,
        });

    session.sock = sock;

    sock.ev.on('creds.update', saveCreds);

    return new Promise<TenantSession>((resolve) => {
      let isDone = false;
      const finish = () => {
        if (!isDone) {
          isDone = true;
          resolve(session!);
        }
      };

      // 5 second max wait for QR generation on connect
      const timer = setTimeout(finish, 5000);

      sock.ev.on('connection.update', async (update: Partial<ConnectionState>) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
          try {
            const qrDataUrl = await QRCode.toDataURL(qr, {
              errorCorrectionLevel: 'M',
              margin: 2,
              width: 320,
            });
            session!.qrCodeDataUrl = qrDataUrl;
            session!.status = 'SCAN_QR';
            session!.isInitializing = false;
            clearTimeout(timer);
            finish();
          } catch (err) {
            console.error('[WhatsAppService] Error generating QR code data URL:', err);
          }
        }

        if (connection === 'close') {
          session!.isInitializing = false;
          const statusCode = (lastDisconnect?.error as any)?.output?.statusCode;
          const loggedOutCode = DisconnectReason?.loggedOut ?? 401;
          const shouldReconnect = statusCode !== loggedOutCode;

          console.log(`[WhatsAppService] Connection closed for tenant ${tenantId}. StatusCode:`, statusCode, 'shouldReconnect:', shouldReconnect);

          if (statusCode === loggedOutCode) {
            session!.status = 'DISCONNECTED';
            session!.sock = null;
            session!.qrCodeDataUrl = null;
            session!.phoneNumber = null;
            try {
              fs.rmSync(sessionDir, { recursive: true, force: true });
            } catch (e) {
              // ignore
            }
          } else {
            session!.status = 'DISCONNECTED';
            session!.sock = null;
            // Auto reconnect after brief pause if not logged out
            setTimeout(() => {
              if (this.sessions.has(tenantId)) {
                this.initSession(tenantId).catch(console.error);
              }
            }, 4000);
          }
          clearTimeout(timer);
          finish();
        } else if (connection === 'open') {
          session!.isInitializing = false;
          session!.status = 'CONNECTED';
          session!.qrCodeDataUrl = null;
          session!.lastConnectedAt = new Date();
          const userJid = sock.user?.id || '';
          const phone = userJid.split(':')[0] || userJid.split('@')[0] || '';
          session!.phoneNumber = phone;
          console.log(`[WhatsAppService] WhatsApp connected for tenant ${tenantId}! Phone: ${phone}`);
          clearTimeout(timer);
          finish();
        }
      });
    });
  }

  public async disconnect(tenantId: string): Promise<void> {
    const session = this.sessions.get(tenantId);
    if (session) {
      try {
        if (session.sock) {
          await session.sock.logout();
        }
      } catch (err) {
        console.warn('[WhatsAppService] Error during logout:', err);
      }
      session.status = 'DISCONNECTED';
      session.sock = null;
      session.qrCodeDataUrl = null;
      session.phoneNumber = null;
      this.sessions.delete(tenantId);
    }
    const sessionDir = this.getSessionFolder(tenantId);
    try {
      fs.rmSync(sessionDir, { recursive: true, force: true });
    } catch (e) {
      // ignore
    }
  }

  public async sendDeliveryNote(args: {
    tenantId: string;
    customerPhone: string;
    customerName: string;
    invoiceNumber: string;
    deliveryOtp?: string;
    totalAmount: number;
    shippingAddress?: string;
    assignedDriverName?: string;
    storeName?: string;
  }): Promise<{ success: boolean; message?: string }> {
    const session = this.sessions.get(args.tenantId);
    if (!session || session.status !== 'CONNECTED' || !session.sock) {
      return { success: false, message: 'WhatsApp is not connected for this store. Please connect via QR code.' };
    }

    // Clean phone number
    let cleanPhone = args.customerPhone.replace(/[^0-9]/g, '');
    if (!cleanPhone) {
      return { success: false, message: 'Invalid customer phone number.' };
    }

    // Local Sri Lanka phone format converter (e.g. 0771234567 -> 94771234567)
    if (cleanPhone.startsWith('0') && cleanPhone.length === 10) {
      cleanPhone = '94' + cleanPhone.substring(1);
    } else if (cleanPhone.length === 9) {
      cleanPhone = '94' + cleanPhone;
    }

    const jid = `${cleanPhone}@s.whatsapp.net`;

    // Build friendly formatted delivery note message
    const lines: string[] = [];
    lines.push(`📦 *DELIVERY NOTE & ORDER CONFIRMATION*`);
    if (args.storeName) {
      lines.push(`🏪 *${args.storeName}*`);
    }
    lines.push(`━━━━━━━━━━━━━━━━━━━━━`);
    lines.push(`🧾 *Invoice:* ${args.invoiceNumber}`);
    lines.push(`👤 *Customer:* ${!args.customerName.trim() ? 'Valued Customer' : args.customerName}`);
    lines.push(`💰 *Cash to Pay (COD):* Rs. ${args.totalAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
    
    if (args.shippingAddress) {
      lines.push(`📍 *Delivery Address:* ${args.shippingAddress}`);
    }
    if (args.assignedDriverName) {
      lines.push(`🚚 *Delivery Driver:* ${args.assignedDriverName}`);
    }

    if (args.deliveryOtp) {
      lines.push(`━━━━━━━━━━━━━━━━━━━━━`);
      lines.push(`🔐 *YOUR DELIVERY OTP: ${args.deliveryOtp}*`);
      lines.push(`⚠️ *IMPORTANT:* Please share this OTP with your delivery driver upon receiving your package to confirm delivery.`);
    }

    lines.push(`━━━━━━━━━━━━━━━━━━━━━`);
    lines.push(`Thank you for choosing us! Have a great day.`);

    const messageText = lines.join('\n');

    try {
      await session.sock.sendMessage(jid, { text: messageText });
      return { success: true, message: 'Delivery note & OTP sent successfully via WhatsApp.' };
    } catch (err: any) {
      console.error('[WhatsAppService] Failed to send WhatsApp message:', err);
      return { success: false, message: `Failed to dispatch WhatsApp message: ${err.message || err}` };
    }
  }
}

export const whatsAppService = new WhatsAppService();
