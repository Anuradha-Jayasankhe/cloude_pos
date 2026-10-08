import jwt from 'jsonwebtoken';

import { settings } from '../config';

export interface AccessTokenPayload {
  sub: string;
  tenant_id: string;
  role: string;
  user_id: string;
  exp?: number;
  iat?: number;
}

export const createAccessToken = (args: {
  subject: string;
  tenantId: string;
  role: string;
  userId: string;
}): string => {
  const payload: AccessTokenPayload = {
    sub: args.subject,
    tenant_id: args.tenantId,
    role: args.role,
    user_id: args.userId,
  };

  return jwt.sign(payload, settings.jwtSecret, {
    algorithm: settings.jwtAlgorithm as jwt.Algorithm,
    expiresIn: `${settings.accessTokenExpireMinutes}m`,
  });
};

export const decodeToken = (token: string): AccessTokenPayload | null => {
  try {
    return jwt.verify(token, settings.jwtSecret, {
      algorithms: [settings.jwtAlgorithm as jwt.Algorithm],
    }) as AccessTokenPayload;
  } catch {
    return null;
  }
};
