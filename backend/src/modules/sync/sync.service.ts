import { Injectable } from '@nestjs/common';

export interface SyncBlobDto {
  id: string;
  entityType: string;
  epoch: number;
  clientTimestamp: number;
  ivBase64: string;
  ciphertextBase64: string;
  macTagBase64: string;
  isTombstone: boolean;
  deviceId: string;
}

export interface StoredSyncBlob extends SyncBlobDto {
  userId: string;
  serverTimestamp: number;
}

export interface PushResult {
  acknowledgedIds: string[];
  conflictIds: string[];
  serverTimestamp: number;
}

export interface PullResult {
  blobs: SyncBlobDto[];
  serverCursor: number;
  hasMore: boolean;
}

@Injectable()
export class SyncService {
  // Keyed by `${userId}:${entityId}`
  private store: Map<string, StoredSyncBlob> = new Map();

  /**
   * Push encrypted blobs from a client device.
   * Enforces Last-Write-Wins (LWW) conflict resolution using (epoch, clientTimestamp).
   * Server NEVER sees plaintext — only blind encrypted envelopes.
   */
  public pushBlobs(userId: string, deviceId: string, incomingBlobs: SyncBlobDto[]): PushResult {
    const acknowledgedIds: string[] = [];
    const conflictIds: string[] = [];
    const now = Date.now();

    for (const blob of incomingBlobs) {
      if (!blob.id || !blob.ciphertextBase64 || !blob.ivBase64) {
        conflictIds.push(blob.id || 'unknown');
        continue;
      }

      const key = `${userId}:${blob.id}`;
      const existing = this.store.get(key);

      if (!existing) {
        // First time seeing this entity
        const stored: StoredSyncBlob = {
          ...blob,
          userId,
          deviceId,
          serverTimestamp: now,
        };
        this.store.set(key, stored);
        acknowledgedIds.push(blob.id);
      } else {
        // Last-Write-Wins (LWW) Conflict Resolution
        // Rule: Higher epoch wins. If epochs tie, higher clientTimestamp wins.
        const incomingWins =
          blob.epoch > existing.epoch ||
          (blob.epoch === existing.epoch && blob.clientTimestamp > existing.clientTimestamp);

        if (incomingWins) {
          const updated: StoredSyncBlob = {
            ...blob,
            userId,
            deviceId,
            serverTimestamp: now,
          };
          this.store.set(key, updated);
          acknowledgedIds.push(blob.id);
        } else {
          // Existing version on server is newer or concurrent conflict resolved in favor of server
          conflictIds.push(blob.id);
        }
      }
    }

    return {
      acknowledgedIds,
      conflictIds,
      serverTimestamp: now,
    };
  }

  /**
   * Pull encrypted blobs updated since the given server timestamp.
   * Returns encrypted envelopes for client-side local decryption.
   */
  public pullBlobs(
    userId: string,
    deviceId: string,
    sinceServerTimestamp: number = 0,
    limit: number = 100
  ): PullResult {
    const matching: StoredSyncBlob[] = [];

    for (const stored of this.store.values()) {
      if (stored.userId === userId && stored.serverTimestamp > sinceServerTimestamp) {
        matching.push(stored);
      }
    }

    // Sort chronologically by serverTimestamp
    matching.sort((a, b) => a.serverTimestamp - b.serverTimestamp);

    const paginated = matching.slice(0, limit);
    const hasMore = matching.length > limit;
    const maxTimestamp = paginated.reduce((max, b) => Math.max(max, b.serverTimestamp), sinceServerTimestamp);

    const safeBlobs: SyncBlobDto[] = paginated.map((b) => ({
      id: b.id,
      entityType: b.entityType,
      epoch: b.epoch,
      clientTimestamp: b.clientTimestamp,
      ivBase64: b.ivBase64,
      ciphertextBase64: b.ciphertextBase64,
      macTagBase64: b.macTagBase64,
      isTombstone: b.isTombstone,
      deviceId: b.deviceId,
    }));

    return {
      blobs: safeBlobs,
      serverCursor: maxTimestamp,
      hasMore,
    };
  }

  /**
   * Purge tombstones older than the retention threshold (e.g., 90 days).
   */
  public purgeExpiredTombstones(maxAgeMs: number = 90 * 24 * 60 * 60 * 1000): number {
    const cutoff = Date.now() - maxAgeMs;
    let purgedCount = 0;

    for (const [key, stored] of this.store.entries()) {
      if (stored.isTombstone && stored.serverTimestamp < cutoff) {
        this.store.delete(key);
        purgedCount++;
      }
    }

    return purgedCount;
  }

  public getBlobCount(userId: string): number {
    let count = 0;
    for (const stored of this.store.values()) {
      if (stored.userId === userId) count++;
    }
    return count;
  }
}
