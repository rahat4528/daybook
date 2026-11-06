import * as crypto from 'crypto';
import { Injectable } from '@nestjs/common';

export interface UserRecord {
  id: string;
  email: string;
  passwordHash: string;
  refreshTokenHash?: string;
  createdAt: string;
  updatedAt: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  private users: Map<string, UserRecord> = new Map(); // In-memory/Postgres store
  private readonly jwtSecret: string;
  private readonly jwtRefreshSecret: string;

  constructor(jwtSecret?: string, jwtRefreshSecret?: string) {
    this.jwtSecret = jwtSecret || process.env.JWT_SECRET || 'daybook_production_jwt_secret_key_32bytes';
    this.jwtRefreshSecret = jwtRefreshSecret || process.env.JWT_REFRESH_SECRET || 'daybook_refresh_token_secret_key_32bytes';
  }

  // SHA-256 password hash with salt (compatible without external C-bindings)
  public hashPassword(password: string): string {
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha256').toString('hex');
    return `${salt}:${hash}`;
  }

  public verifyPassword(password: string, storedHash: string): boolean {
    const [salt, hash] = storedHash.split(':');
    if (!salt || !hash) return false;
    const computed = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha256').toString('hex');
    return crypto.timingSafeEqual(Buffer.from(hash, 'hex'), Buffer.from(computed, 'hex'));
  }

  public hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  public register(email: string, password: string): { user: Omit<UserRecord, 'passwordHash' | 'refreshTokenHash'>; tokens: TokenPair } {
    const normalizedEmail = email.toLowerCase().trim();
    if (!normalizedEmail || !password || password.length < 8) {
      throw new Error('Invalid email or password (min length 8 characters)');
    }

    // Check if user already exists
    for (const u of this.users.values()) {
      if (u.email === normalizedEmail) {
        throw new Error('User already exists');
      }
    }

    const userId = 'usr_' + crypto.randomUUID();
    const passwordHash = this.hashPassword(password);
    const now = new Date().toISOString();

    const userRecord: UserRecord = {
      id: userId,
      email: normalizedEmail,
      passwordHash,
      createdAt: now,
      updatedAt: now,
    };

    const tokens = this.generateTokenPair(userId, normalizedEmail);
    userRecord.refreshTokenHash = this.hashToken(tokens.refreshToken);
    this.users.set(userId, userRecord);

    const { passwordHash: _, refreshTokenHash: __, ...safeUser } = userRecord;
    return { user: safeUser, tokens };
  }

  public login(email: string, password: string): { user: Omit<UserRecord, 'passwordHash' | 'refreshTokenHash'>; tokens: TokenPair } {
    const normalizedEmail = email.toLowerCase().trim();
    let targetUser: UserRecord | undefined;

    for (const u of this.users.values()) {
      if (u.email === normalizedEmail) {
        targetUser = u;
        break;
      }
    }

    if (!targetUser || !this.verifyPassword(password, targetUser.passwordHash)) {
      throw new Error('Invalid email or credentials');
    }

    const tokens = this.generateTokenPair(targetUser.id, targetUser.email);
    targetUser.refreshTokenHash = this.hashToken(tokens.refreshToken);
    targetUser.updatedAt = new Date().toISOString();

    const { passwordHash: _, refreshTokenHash: __, ...safeUser } = targetUser;
    return { user: safeUser, tokens };
  }

  public refresh(refreshToken: string): TokenPair {
    const payload = this.verifyToken(refreshToken, this.jwtRefreshSecret);
    if (!payload || !payload.sub) {
      throw new Error('Invalid or expired refresh token');
    }

    const user = this.users.get(payload.sub);
    if (!user || !user.refreshTokenHash) {
      throw new Error('User not found or refresh token revoked');
    }

    // Verify token hash
    const incomingHash = this.hashToken(refreshToken);
    if (incomingHash !== user.refreshTokenHash) {
      // Replay attack detected: revoke immediately
      user.refreshTokenHash = undefined;
      throw new Error('Security alert: Token reuse detected. Re-authentication required.');
    }

    // Generate new rotated token pair
    const newTokens = this.generateTokenPair(user.id, user.email);
    user.refreshTokenHash = this.hashToken(newTokens.refreshToken);
    user.updatedAt = new Date().toISOString();

    return newTokens;
  }

  public logout(userId: string): void {
    const user = this.users.get(userId);
    if (user) {
      user.refreshTokenHash = undefined;
      user.updatedAt = new Date().toISOString();
    }
  }

  public generateTokenPair(userId: string, email: string): TokenPair {
    const now = Math.floor(Date.now() / 1000);
    const accessExpires = now + (15 * 60); // 15 mins
    const refreshExpires = now + (7 * 24 * 60 * 60); // 7 days
    const jti = crypto.randomUUID();

    const accessPayload = { sub: userId, email, iat: now, exp: accessExpires, jti, type: 'access' };
    const refreshPayload = { sub: userId, iat: now, exp: refreshExpires, jti: crypto.randomUUID(), type: 'refresh' };

    const accessToken = this.signToken(accessPayload, this.jwtSecret);
    const refreshToken = this.signToken(refreshPayload, this.jwtRefreshSecret);

    return {
      accessToken,
      refreshToken,
      expiresIn: 15 * 60,
    };
  }

  public signToken(payload: object, secret: string): string {
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = crypto.createHmac('sha256', secret).update(`${header}.${body}`).digest('base64url');
    return `${header}.${body}.${signature}`;
  }

  public verifyToken(token: string, secret: string): any {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const [header, body, signature] = parts;
      const expectedSig = crypto.createHmac('sha256', secret).update(`${header}.${body}`).digest('base64url');
      if (signature !== expectedSig) return null;

      const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp && payload.exp < now) return null;

      return payload;
    } catch {
      return null;
    }
  }

  public verifyAccessToken(token: string): any {
    return this.verifyToken(token, this.jwtSecret);
  }
}
