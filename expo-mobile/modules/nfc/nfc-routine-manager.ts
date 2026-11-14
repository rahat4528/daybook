// NFC Tags that Run Routines Hardware Subsystem (Page 04)
// Preserved Tools: Expo, TypeScript, react-native-nfc-manager, expo-sqlite

import * as SQLite from 'expo-sqlite';
import NfcManager, { NfcTech } from 'react-native-nfc-manager';

export interface NfcRoutine {
  id: string;
  name: string;
  category: 'plant' | 'keys' | 'vitamins' | 'coffee' | 'custom';
  tag_uid: string;
  total_completions: number;
}

let nfcDb: SQLite.SQLiteDatabase | null = null;
const lastScanTimes: Record<string, number> = {};

export async function getNfcDb(): Promise<SQLite.SQLiteDatabase> {
  if (!nfcDb) {
    nfcDb = await SQLite.openDatabaseAsync('daybook_nfc.db');
    await nfcDb.execAsync(`
      PRAGMA journal_mode = WAL;
      CREATE TABLE IF NOT EXISTS nfc_routines (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        tag_uid TEXT NOT NULL UNIQUE,
        total_completions INTEGER DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS nfc_events (
        id TEXT PRIMARY KEY NOT NULL,
        routine_id TEXT NOT NULL,
        tag_uid TEXT NOT NULL,
        occurred_at INTEGER NOT NULL
      );
    `);
  }
  return nfcDb;
}

export async function initNfcHardware(): Promise<boolean> {
  try {
    const isSupported = await NfcManager.isSupported();
    if (isSupported) {
      await NfcManager.start();
      return true;
    }
    return false;
  } catch {
    return false;
  }
}

export async function triggerNfcTag(tagUid: string): Promise<{ success: boolean; message: string }> {
  const now = Date.now();
  const lastScan = lastScanTimes[tagUid] || 0;

  // 60s duplicate anti-bounce debouncing
  if (now - lastScan < 60000) {
    return {
      success: false,
      message: 'Debounced: Tag was already tapped within the last 60 seconds.',
    };
  }

  const db = await getNfcDb();
  const routine = await db.getFirstAsync<NfcRoutine>(
    'SELECT * FROM nfc_routines WHERE tag_uid = ?;',
    [tagUid]
  );

  if (!routine) {
    return {
      success: false,
      message: `Unrecognized Tag (${tagUid}). Please pair it in settings.`,
    };
  }

  lastScanTimes[tagUid] = now;
  await db.runAsync(
    'UPDATE nfc_routines SET total_completions = total_completions + 1 WHERE id = ?;',
    [routine.id]
  );
  await db.runAsync(
    'INSERT INTO nfc_events (id, routine_id, tag_uid, occurred_at) VALUES (?, ?, ?, ?);',
    [`nfc_event_${now}`, routine.id, tagUid, now]
  );

  return {
    success: true,
    message: `✓ ${routine.name} successfully logged!`,
  };
}
