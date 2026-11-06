import * as crypto from 'crypto';
import { Injectable } from '@nestjs/common';

export interface PairingCode {
  code: string;
  creatorUserId: string;
  expiresAt: number;
}

export interface BuddyCheckIn {
  userId: string;
  timestamp: number;
  type: 'wake_quest' | 'focus_done' | 'streak_freeze' | 'nightly_review';
  message: string;
}

export interface BuddyRelationship {
  userA: string;
  userB: string;
  pairedAt: number;
}

@Injectable()
export class BuddyService {
  private activeCodes: Map<string, PairingCode> = new Map(); // Keyed by code
  private relationships: Map<string, string> = new Map(); // Keyed by userId -> buddyUserId
  private checkIns: Map<string, BuddyCheckIn[]> = new Map(); // Keyed by userId -> recent check-ins

  /**
   * Generate a 6-character pairing code valid for 15 minutes.
   */
  public generatePairingCode(userId: string): string {
    // Generate clean alphanumeric code like DAY-9842
    const randomDigits = Math.floor(1000 + Math.random() * 9000);
    const code = `DAY-${randomDigits}`;
    const expiresAt = Date.now() + (15 * 60 * 1000);

    this.activeCodes.set(code, {
      code,
      creatorUserId: userId,
      expiresAt,
    });

    return code;
  }

  /**
   * Redeem a pairing code to link two accountability buddies.
   */
  public pairWithCode(redeemerUserId: string, code: string): { partnerId: string; pairedAt: number } {
    const entry = this.activeCodes.get(code.toUpperCase().trim());
    if (!entry) {
      throw new Error('Invalid or expired pairing code');
    }

    if (Date.now() > entry.expiresAt) {
      this.activeCodes.delete(code);
      throw new Error('Pairing code has expired. Please generate a new one.');
    }

    if (entry.creatorUserId === redeemerUserId) {
      throw new Error('Cannot pair with yourself');
    }

    const partnerId = entry.creatorUserId;
    const now = Date.now();

    // Establish mutual relationship
    this.relationships.set(redeemerUserId, partnerId);
    this.relationships.set(partnerId, redeemerUserId);

    // Invalidate code
    this.activeCodes.delete(code);

    return {
      partnerId,
      pairedAt: now,
    };
  }

  /**
   * Publish an accountability check-in (wake up, focus block, habit streak).
   */
  public publishCheckIn(
    userId: string,
    type: BuddyCheckIn['type'],
    message: string
  ): BuddyCheckIn {
    const checkIn: BuddyCheckIn = {
      userId,
      timestamp: Date.now(),
      type,
      message,
    };

    const list = this.checkIns.get(userId) || [];
    list.unshift(checkIn);
    if (list.length > 20) list.pop(); // Keep 20 most recent
    this.checkIns.set(userId, list);

    return checkIn;
  }

  /**
   * Get buddy profile and recent activity feed.
   */
  public getBuddyFeed(userId: string): { buddyId: string | null; feed: BuddyCheckIn[] } {
    const buddyId = this.relationships.get(userId) || null;
    if (!buddyId) {
      return { buddyId: null, feed: [] };
    }

    const feed = this.checkIns.get(buddyId) || [];
    return {
      buddyId,
      feed,
    };
  }

  /**
   * Dissolve pairing.
   */
  public unpair(userId: string): boolean {
    const buddyId = this.relationships.get(userId);
    if (!buddyId) return false;

    this.relationships.delete(userId);
    this.relationships.delete(buddyId);
    return true;
  }
}
