import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { getPinnedTrip } from '../../modules/trips/trip-store';
import { useRouter } from 'expo-router';

export default function TodayHomeScreen() {
  const router = useRouter();
  const [pinnedTrip, setPinnedTrip] = useState(getPinnedTrip());

  useEffect(() => {
    setPinnedTrip(getPinnedTrip());
  }, []);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Dynamic Header */}
      <View style={styles.header}>
        <Text style={styles.title}>DAYBOOK</Text>
        <Text style={styles.subtitle}>OFFLINE-FIRST DAILY OPERATING SYSTEM</Text>
      </View>

      {/* Pinned Trip Countdown Card */}
      {pinnedTrip && (
        <TouchableOpacity
          style={styles.card}
          activeOpacity={0.8}
          onPress={() => router.push('/trips')}
        >
          <View style={styles.cardHeader}>
            <Text style={styles.badge}>✈️ LIVE TRIP COUNTDOWN</Text>
            <Text style={styles.flightNum}>{pinnedTrip.flightNumber || 'FLIGHT'}</Text>
          </View>
          <Text style={styles.routeText}>{pinnedTrip.originIata} ➔ {pinnedTrip.destinationIata}</Text>
          <Text style={styles.destinationCity}>{pinnedTrip.destinationCity}</Text>
          <View style={styles.countdownBox}>
            <Text style={styles.countdownValue}>Synced to Native Lock Screen Complication</Text>
          </View>
        </TouchableOpacity>
      )}

      {/* Quick Launch Hub for 5 Core Features */}
      <Text style={styles.sectionTitle}>CORE ARCHITECTURE MODULES</Text>
      <View style={styles.grid}>
        <TouchableOpacity style={styles.gridItem} onPress={() => router.push('/trips')}>
          <Text style={styles.gridIcon}>✈️</Text>
          <Text style={styles.gridLabel}>Trips</Text>
          <Text style={styles.gridSub}>SwiftUI Widgets</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.gridItem} onPress={() => router.push('/links')}>
          <Text style={styles.gridIcon}>🔖</Text>
          <Text style={styles.gridLabel}>Links</Text>
          <Text style={styles.gridSub}>Share Sheet Intent</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.gridItem} onPress={() => router.push('/habits')}>
          <Text style={styles.gridIcon}>⚡</Text>
          <Text style={styles.gridLabel}>Habits</Text>
          <Text style={styles.gridSub}>Actionable Notifs</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.gridItem} onPress={() => router.push('/nfc')}>
          <Text style={styles.gridIcon}>📡</Text>
          <Text style={styles.gridLabel}>NFC Tags</Text>
          <Text style={styles.gridSub}>Physical Routines</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.gridItem} onPress={() => router.push('/fitness')}>
          <Text style={styles.gridIcon}>❤️</Text>
          <Text style={styles.gridLabel}>Heart Rate</Text>
          <Text style={styles.gridSub}>BLE Telemetry</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md },
  header: { marginBottom: Spacing.lg },
  title: { fontSize: 26, fontWeight: '900', color: Colors.textPrimary, letterSpacing: 1.2 },
  subtitle: { fontSize: 11, fontWeight: '700', color: Colors.accentLime, letterSpacing: 0.8, marginTop: 4 },
  card: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1.5,
    borderColor: Colors.accentLimeBorder,
    marginBottom: Spacing.lg,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  badge: { color: Colors.accentLime, fontSize: 10, fontWeight: 'bold' },
  flightNum: { color: Colors.textSecondary, fontSize: 11, fontFamily: 'monospace' },
  routeText: { fontSize: 28, fontWeight: '900', color: Colors.textPrimary, marginVertical: 8 },
  destinationCity: { color: Colors.accentLime, fontSize: 13, fontWeight: 'bold' },
  countdownBox: {
    backgroundColor: Colors.bg,
    borderRadius: Radius.button,
    padding: 10,
    marginTop: 12,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  countdownValue: { color: Colors.accentLime, fontSize: 12, fontWeight: 'bold', textAlign: 'center' },
  sectionTitle: { fontSize: 12, fontWeight: 'bold', color: Colors.textSecondary, letterSpacing: 0.8, marginBottom: 10 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between' },
  gridItem: {
    width: '48%',
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: 12,
  },
  gridIcon: { fontSize: 24, marginBottom: 8 },
  gridLabel: { color: Colors.textPrimary, fontSize: 15, fontWeight: 'bold' },
  gridSub: { color: Colors.textSecondary, fontSize: 11, marginTop: 2 },
});
