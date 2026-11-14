// Trip Countdown Module Store (Page 01)
// Preserved Tools: Expo, TypeScript, MMKV, @bacons/apple-targets, SwiftUI

import { MMKV } from 'react-native-mmkv';

export const tripStorage = new MMKV({ id: 'daybook-trips' });

export interface TripRecord {
  id: string;
  originIata: string;
  destinationIata: string;
  destinationCity: string;
  flightNumber?: string;
  departureTimeUtc: string; // ISO 8601
  status: 'scheduled' | 'boarding' | 'in_air' | 'landed' | 'cancelled';
  notes?: string;
  isPinned: boolean;
}

export interface WidgetSnapshotPayload {
  tripId: string;
  route: string;
  destination: string;
  flightNum: string;
  targetTimestamp: number;
  statusText: string;
  countdownText: string;
}

const TRIPS_KEY = 'trips:list';

export function getAllTrips(): TripRecord[] {
  const raw = tripStorage.getString(TRIPS_KEY);
  if (!raw) {
    // Default seed
    const defaultTrip: TripRecord = {
      id: 'trip_seed_1',
      originIata: 'DAC',
      destinationIata: 'LHR',
      destinationCity: 'London',
      flightNumber: 'BG201',
      departureTimeUtc: new Date(Date.now() + 86400000 * 7).toISOString(),
      status: 'scheduled',
      isPinned: true,
      notes: 'Terminal 4, Seat 14A',
    };
    saveAllTrips([defaultTrip]);
    return [defaultTrip];
  }
  try {
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

export function saveAllTrips(trips: TripRecord[]): void {
  tripStorage.set(TRIPS_KEY, JSON.stringify(trips));
  syncWidgetSnapshot(trips);
}

export function getPinnedTrip(): TripRecord | null {
  const trips = getAllTrips();
  return trips.find(t => t.isPinned) || trips[0] || null;
}

export function syncWidgetSnapshot(trips: TripRecord[]): void {
  const pinned = trips.find(t => t.isPinned) || trips[0];
  if (!pinned) return;

  const depDate = new Date(pinned.departureTimeUtc);
  const now = new Date();
  const diffSec = Math.max(0, Math.floor((depDate.getTime() - now.getTime()) / 1000));
  const days = Math.floor(diffSec / 86400);
  const hours = Math.floor((diffSec % 86400) / 3600);
  const minutes = Math.floor((diffSec % 3600) / 60);

  const payload: WidgetSnapshotPayload = {
    tripId: pinned.id,
    route: `${pinned.originIata.toUpperCase()} ➔ ${pinned.destinationIata.toUpperCase()}`,
    destination: pinned.destinationCity,
    flightNum: pinned.flightNumber || '',
    targetTimestamp: Math.floor(depDate.getTime() / 1000),
    statusText: pinned.status.toUpperCase(),
    countdownText: `${days}d ${hours}h ${minutes}m`,
  };

  tripStorage.set('trip_widget_data', JSON.stringify(payload));
}
