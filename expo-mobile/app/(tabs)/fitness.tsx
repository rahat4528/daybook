import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { classifyTrainingZone, TrainingZone } from '../../modules/ble-heart-rate/ble-telemetry';

export default function FitnessTabScreen() {
  const [bpm, setBpm] = useState(74);
  const [isConnected, setIsConnected] = useState(false);
  const [zone, setZone] = useState<TrainingZone>(classifyTrainingZone(74));

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isConnected) {
      interval = setInterval(() => {
        setBpm(prev => {
          const delta = Math.floor(Math.random() * 5) - 2;
          const next = Math.max(55, Math.min(185, prev + delta));
          setZone(classifyTrainingZone(next));
          return next;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isConnected]);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.headerTitle}>BLUETOOTH HEART RATE</Text>
      <Text style={styles.headerSubtitle}>react-native-ble-plx • Reanimated 60fps</Text>

      {/* Main HUD */}
      <View style={styles.hudCard}>
        <Text style={styles.heartIcon}>LIVE PULSE</Text>
        <Text style={styles.bpmValue}>{isConnected ? bpm : '--'}</Text>
        <Text style={styles.bpmLabel}>BEATS PER MINUTE</Text>

        <View style={styles.zoneChip}>
          <Text style={styles.zoneText}>{zone}</Text>
        </View>

        <TouchableOpacity
          style={[styles.toggleBtn, isConnected ? styles.btnDisconnect : styles.btnConnect]}
          onPress={() => setIsConnected(!isConnected)}
        >
          <Text style={styles.toggleBtnText}>
            {isConnected ? 'DISCONNECT STRAP' : 'CONNECT POLAR H10'}
          </Text>
        </TouchableOpacity>
      </View>

      <View style={styles.infoCard}>
        <Text style={styles.infoTitle}>GATT PROTOCOL ARCHITECTURE</Text>
        <Text style={styles.infoItem}>• Service UUID: 0x180D (Heart Rate)</Text>
        <Text style={styles.infoItem}>• Characteristic: 0x2A37 (Measurement Notify)</Text>
        <Text style={styles.infoItem}>• Low Energy 2.4 GHz RF Telemetry</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md },
  headerTitle: { fontSize: 20, fontWeight: '900', color: Colors.textPrimary },
  headerSubtitle: { fontSize: 11, color: Colors.accentLime, marginBottom: Spacing.md },
  hudCard: {
    backgroundColor: '#000000',
    borderRadius: 24,
    padding: Spacing.xl,
    borderWidth: 1.5,
    borderColor: Colors.accentLimeBorder,
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  heartIcon: { fontSize: 13, fontWeight: '800', color: Colors.accentLime, letterSpacing: 1.5, marginBottom: 8, fontFamily: 'monospace' },
  bpmValue: { fontSize: 68, fontWeight: '900', color: Colors.accentLime, fontFamily: 'monospace' },
  bpmLabel: { color: Colors.textSecondary, fontSize: 11, letterSpacing: 1, marginTop: 4 },
  zoneChip: {
    backgroundColor: Colors.surface2,
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    borderWidth: 1,
    borderColor: Colors.accentLime,
    marginTop: 16,
  },
  zoneText: { color: Colors.accentLime, fontSize: 11, fontWeight: 'bold' },
  toggleBtn: {
    marginTop: 20,
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: Radius.pill,
  },
  btnConnect: { backgroundColor: Colors.accentLime },
  btnDisconnect: { backgroundColor: Colors.surface2, borderWidth: 1, borderColor: Colors.border },
  toggleBtnText: { color: '#000000', fontWeight: 'bold', fontSize: 12 },
  infoCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  infoTitle: { color: Colors.textPrimary, fontSize: 12, fontWeight: 'bold', marginBottom: 8 },
  infoItem: { color: Colors.textSecondary, fontSize: 12, marginBottom: 4, fontFamily: 'monospace' },
});
