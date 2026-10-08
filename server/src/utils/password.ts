import bcrypt from 'bcryptjs';

export const hashPassword = async (password: string): Promise<string> => {
  return bcrypt.hash(password, 10);
};

export const verifyPassword = async (plainPassword: string, passwordHash: string): Promise<boolean> => {
  return bcrypt.compare(plainPassword, passwordHash);
};
