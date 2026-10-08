import { Router, type Request, type Response } from 'express';
import { requireAuth } from '../middleware/auth';
import { whatsAppService } from '../services/whatsapp.service';

export const whatsappRouter = Router();

// 1. Get WhatsApp Connection Status & QR Code (if in SCAN_QR state)
whatsappRouter.get('/status', requireAuth, async (req: Request, res: Response) => {
  const tenantId = req.auth?.tenantId || 'default';
  const statusInfo = whatsAppService.getStatus(tenantId);
  res.json({
    success: true,
    ...statusInfo,
  });
});

// 2. Start / Refresh QR Connection Session
whatsappRouter.post('/connect', requireAuth, async (req: Request, res: Response) => {
  const tenantId = req.auth?.tenantId || 'default';
  try {
    await whatsAppService.initSession(tenantId);
    const statusInfo = whatsAppService.getStatus(tenantId);
    res.json({
      success: true,
      message: 'WhatsApp session initialized. Please scan the QR code.',
      ...statusInfo,
    });
  } catch (err: any) {
    console.error('[WhatsAppRoute] Connect error:', err);
    res.status(500).json({
      success: false,
      message: `Failed to initialize WhatsApp session: ${err.message || err}`,
    });
  }
});

// 3. Disconnect / Logout WhatsApp Session
whatsappRouter.post('/disconnect', requireAuth, async (req: Request, res: Response) => {
  const tenantId = req.auth?.tenantId || 'default';
  try {
    await whatsAppService.disconnect(tenantId);
    res.json({
      success: true,
      message: 'WhatsApp session disconnected successfully.',
    });
  } catch (err: any) {
    console.error('[WhatsAppRoute] Disconnect error:', err);
    res.status(500).json({
      success: false,
      message: `Failed to disconnect WhatsApp session: ${err.message || err}`,
    });
  }
});

// 4. Send Delivery Note & OTP to Customer WhatsApp
whatsappRouter.post('/send-delivery-note', requireAuth, async (req: Request, res: Response) => {
  const tenantId = req.auth?.tenantId || 'default';
  const {
    customerPhone,
    customerName,
    invoiceNumber,
    deliveryOtp,
    totalAmount,
    shippingAddress,
    assignedDriverName,
    storeName,
  } = req.body;

  if (!customerPhone) {
    res.status(400).json({ success: false, message: 'Customer phone number is required.' });
    return;
  }

  const result = await whatsAppService.sendDeliveryNote({
    tenantId,
    customerPhone: String(customerPhone),
    customerName: String(customerName || 'Customer'),
    invoiceNumber: String(invoiceNumber || ''),
    deliveryOtp: deliveryOtp ? String(deliveryOtp) : undefined,
    totalAmount: Number(totalAmount) || 0,
    shippingAddress: shippingAddress ? String(shippingAddress) : undefined,
    assignedDriverName: assignedDriverName ? String(assignedDriverName) : undefined,
    storeName: storeName ? String(storeName) : undefined,
  });

  if (!result.success) {
    res.status(400).json(result);
    return;
  }

  res.json(result);
});
