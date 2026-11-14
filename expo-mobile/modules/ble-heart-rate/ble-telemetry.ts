// Bluetooth Low Energy Heart Rate Telemetry & GATT Subsystem (Page 05)
// Preserved Tools: Expo, TypeScript, react-native-ble-plx, Reanimated

import { BleManager, Device, Characteristic } from 'react-native-ble-plx';

export const HEART_RATE_SERVICE_UUID = '0000180d-0000-1000-8000-00805f9b34fb';
export const HEART_RATE_MEASUREMENT_UUID = '00002a37-0000-1000-8000-00805f9b34fb';

export const bleManager = new BleManager();

export enum TrainingZone {
  Z1 = 'Zone 1 (Recovery)',
  Z2 = 'Zone 2 (Aerobic Base)',
  Z3 = 'Zone 3 (Tempo)',
  Z4 = 'Zone 4 (Threshold)',
  Z5 = 'Zone 5 (Anaerobic Max)',
}

export function classifyTrainingZone(bpm: number, maxHr = 190): TrainingZone {
  const ratio = bpm / maxHr;
  if (ratio >= 0.90) return TrainingZone.Z5;
  if (ratio >= 0.80) return TrainingZone.Z4;
  if (ratio >= 0.70) return TrainingZone.Z3;
  if (ratio >= 0.60) return TrainingZone.Z2;
  return TrainingZone.Z1;
}

/**
 * Decodes standard Bluetooth SIG GATT Characteristic 0x2A37 Heart Rate Measurement
 */
export function decodeHeartRateMeasurement(base64Payload: string): number {
  if (typeof atob === 'function') {
    const raw = atob(base64Payload);
    const flags = raw.charCodeAt(0);
    const is16Bit = (flags & 0x01) !== 0;

    if (is16Bit && raw.length >= 3) {
      return raw.charCodeAt(1) | (raw.charCodeAt(2) << 8);
    } else if (raw.length >= 2) {
      return raw.charCodeAt(1);
    }
  }
  return 72; // Baseline fallback
}

export async function connectHeartRateSensor(
  device: Device,
  onBpmReceived: (bpm: number) => void
): Promise<void> {
  const connectedDevice = await device.connect();
  await connectedDevice.discoverAllServicesAndCharacteristics();

  connectedDevice.monitorCharacteristicForService(
    HEART_RATE_SERVICE_UUID,
    HEART_RATE_MEASUREMENT_UUID,
    (error, characteristic: Characteristic | null) => {
      if (error || !characteristic?.value) return;
      const bpm = decodeHeartRateMeasurement(characteristic.value);
      onBpmReceived(bpm);
    }
  );
}
