// Link Saver Database & Open Graph Ingestion Subsystem (Page 02)
// Preserved Tools: Expo, TypeScript, expo-share-intent, Expo Router, expo-sqlite

import * as SQLite from 'expo-sqlite';

export interface SavedLinkRow {
  id: string;
  raw_url: string;
  canonical_url: string;
  title: string;
  description?: string;
  image_url?: string;
  domain: string;
  is_favorite: number;
  is_archived: number;
  created_at: number;
}

let dbInstance: SQLite.SQLiteDatabase | null = null;

export async function getLinksDb(): Promise<SQLite.SQLiteDatabase> {
  if (!dbInstance) {
    dbInstance = await SQLite.openDatabaseAsync('daybook_links.db');
    await dbInstance.execAsync(`
      PRAGMA journal_mode = WAL;
      CREATE TABLE IF NOT EXISTS links (
        id TEXT PRIMARY KEY NOT NULL,
        raw_url TEXT NOT NULL,
        canonical_url TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        domain TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_links_canonical ON links(canonical_url);
    `);
  }
  return dbInstance;
}

export function normalizeCanonicalUrl(url: string): string {
  try {
    const parsed = new URL(url.trim());
    parsed.searchParams.delete('utm_source');
    parsed.searchParams.delete('utm_medium');
    parsed.searchParams.delete('utm_campaign');
    parsed.searchParams.delete('ref');
    parsed.searchParams.delete('fbclid');
    parsed.searchParams.delete('si');
    return parsed.toString().replace(/\/+$/, '');
  } catch {
    return url.trim().toLowerCase();
  }
}

export function extractDomain(url: string): string {
  try {
    const host = new URL(url).hostname.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  } catch {
    return 'web';
  }
}

export async function saveSharedLink(rawUrl: string, title?: string, description?: string): Promise<SavedLinkRow> {
  const db = await getLinksDb();
  const canonical = normalizeCanonicalUrl(rawUrl);
  const domain = extractDomain(rawUrl);
  const id = `link_${Date.now()}`;
  const now = Date.now();
  const resolvedTitle = (title && title.trim().length > 0) ? title.trim() : `Saved Link (${domain})`;

  await db.runAsync(
    `INSERT OR REPLACE INTO links (id, raw_url, canonical_url, title, description, domain, is_favorite, is_archived, created_at)
     VALUES (?, ?, ?, ?, ?, ?, 0, 0, ?);`,
    [id, rawUrl, canonical, resolvedTitle, description || '', domain, now]
  );

  return {
    id,
    raw_url: rawUrl,
    canonical_url: canonical,
    title: resolvedTitle,
    description,
    domain,
    is_favorite: 0,
    is_archived: 0,
    created_at: now,
  };
}

export async function getAllLinks(): Promise<SavedLinkRow[]> {
  const db = await getLinksDb();
  return await db.getAllAsync<SavedLinkRow>('SELECT * FROM links WHERE is_archived = 0 ORDER BY created_at DESC;');
}
