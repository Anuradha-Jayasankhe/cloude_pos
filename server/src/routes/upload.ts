import { Router, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { UploadedFileModel } from '../models/UploadedFile';

export const uploadRouter = Router();

// Ensure upload directories exist if filesystem is writable
const dataUploadsDir = path.join(__dirname, '../../data/uploads');
const productsUploadsDir = path.join(dataUploadsDir, 'products');
const logosUploadsDir = path.join(dataUploadsDir, 'logos');

try {
  for (const dir of [dataUploadsDir, productsUploadsDir, logosUploadsDir]) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }
} catch (_) {
  // Read-only filesystem in serverless environments like Vercel
}

/**
 * POST /api/v1/upload
 * Accepts base64 encoded image or raw binary
 * Body: { image: string, filename?: string, folder?: 'products' | 'logos' }
 */
uploadRouter.post('/', async (req: Request, res: Response) => {
  try {
    const { image, filename: clientFilename, folder: clientFolder } = req.body;

    if (!image || typeof image !== 'string') {
      res.status(400).json({ detail: 'Image data (base64 string) is required.' });
      return;
    }

    // Determine target subfolder ('products' or 'logos' or 'general')
    const folder = clientFolder === 'logos' ? 'logos' : 'products';
    const targetDir = folder === 'logos' ? logosUploadsDir : productsUploadsDir;

    // Handle data URI format (e.g., data:image/jpeg;base64,....)
    let base64Data = image;
    let ext = 'png';

    const matches = image.match(/^data:image\/([a-zA-Z0-9+]+);base64,(.+)$/);
    if (matches && matches.length === 3) {
      ext = matches[1].toLowerCase();
      if (ext === 'jpeg') ext = 'jpg';
      base64Data = matches[2];
    } else if (clientFilename && clientFilename.includes('.')) {
      const parts = clientFilename.split('.');
      ext = parts[parts.length - 1].toLowerCase();
    }

    // Safe extension whitelist
    if (!['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg', 'ico'].includes(ext)) {
      ext = 'png';
    }

    const mimeMap: Record<string, string> = {
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      png: 'image/png',
      webp: 'image/webp',
      gif: 'image/gif',
      svg: 'image/svg+xml',
      ico: 'image/x-icon',
    };
    const mimeType = mimeMap[ext] || 'image/png';

    const buffer = Buffer.from(base64Data, 'base64');
    if (buffer.length === 0) {
      res.status(400).json({ detail: 'Invalid or empty image buffer.' });
      return;
    }

    // Generate a unique filename
    const uniqueSuffix = `${Date.now()}_${crypto.randomBytes(6).toString('hex')}`;
    const filename = `${folder}_${uniqueSuffix}.${ext}`;

    // 1. Always persist to MongoDB Atlas (works everywhere including Vercel serverless)
    try {
      await UploadedFileModel.findOneAndUpdate(
        { filename },
        {
          filename,
          folder,
          mimeType,
          data: buffer,
          size: buffer.length,
          createdAt: new Date(),
        },
        { upsert: true, new: true }
      );
    } catch (mongoErr) {
      console.error('[Upload] MongoDB save warning:', mongoErr);
    }

    // 2. Try writing to local disk cache if writable (local dev server or VPS)
    try {
      const filePath = path.join(targetDir, filename);
      await fs.promises.writeFile(filePath, buffer);
    } catch (_) {
      // Ignored if serverless / read-only environment
    }

    const relativeUrl = `/uploads/${folder}/${filename}`;

    res.json({
      success: true,
      url: relativeUrl,
      filename,
      size: buffer.length,
      folder,
    });
  } catch (error) {
    console.error('[Upload] Error uploading file:', error);
    res.status(500).json({ detail: 'Failed to save image', error: (error as Error).message });
  }
});
