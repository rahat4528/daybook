import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { getAllTrips, saveAllTrips, TripRecord, getPinnedTrip } from '../../modules/trips/trip-store';

export default function TripsTabScreen() {
  const [trips, setTrips] = useState<TripRecord[]>(getAllTrips());
  const [origin, setOrigin] = useState('DAC');
  const [dest, setDest] = useState('JFK');
  const [city, setCity] = useState('New York');

  const handleAddTrip = () => {
    if (!origin || !dest || !city) return;
    const newTrip: TripRecord = {
      id: `trip_${Date.now()}`,
      originIata: origin.toUpperCase(),
      destinationIata: dest.toUpperCase(),
      destinationCity: city,
      departureTimeUtc: new Date(Date.now() + 86400000 * 14).toISOString(),
      status: 'scheduled',
      isPinned: true,
    };
    const updated = [newTrip, ...trips.map(t => ({ ...t, isPinned: false }))];
    saveAllTrips(updated);
    setTrips(updated);
  };

  const pinned = getPinnedTrip();

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.headerTitle}>TRIP COUNTDOWN & WIDGETS</Text>
      <Text style={styles.headerSubtitle}>SwiftUI Native Target & MMKV Storage Bridge</Text>

      {pinned && (
        <View style={styles.heroCard}>
          <Text style={styles.heroBadge}>ACTIVE WIDGET TARGET</Text>
          <Text style={styles.heroRoute}>{pinned.originIata} ➔ {pinned.destinationIata}</Text>
          <Text style={styles.heroCity}>{pinned.destinationCity} (Flight {pinned.flightNumber || 'TBD'})</Text>
        </View>
      )}

      {/* Quick Add Form */}
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>PLAN NEW ITINERARY</Text>
        <View style={styles.inputRow}>
          <TextInput
            style={styles.input}
            value={origin}
            onChangeText={setOrigin}
            placeholder="Origin"
            placeholderTextColor={Colors.textSecondary}
          />
          <Text style={{ color: Colors.accentLime, fontSize: 18 }}>➔</Text>
          <TextInput
            style={styles.input}
            value={dest}
            onChangeText={setDest}
            placeholder="Destination"
            placeholderTextColor={Colors.textSecondary}
          />
        </View>
        <TextInput
          style={[styles.input, { marginTop: 8 }]}
          value={city}
          onChangeText={setCity}
          placeholder="Destination City"
          placeholderTextColor={Colors.textSecondary}
        />
        <TouchableOpacity style={styles.btn} onPress={handleAddTrip}>
          <Text style={styles.btnText}>SAVE & SYNC WIDGET</Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.sectionTitle}>ALL SCHEDULED TRIPS ({trips.length})</Text>
      {trips.map(t => (
        <View key={t.id} style={styles.tripRow}>
          <Text style={styles.tripRoute}>{t.originIata} ➔ {t.destinationIata}</Text>
          <Text style={styles.tripCity}>{t.destinationCity}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md },
  headerTitle: { fontSize: 20, fontWeight: '900', color: Colors.textPrimary },
  headerSubtitle: { fontSize: 11, color: Colors.accentLime, marginBottom: Spacing.md },
  heroCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1.5,
    borderColor: Colors.accentLime,
    marginBottom: Spacing.md,
  },
  heroBadge: { color: Colors.accentLime, fontSize: 10, fontWeight: 'bold' },
  heroRoute: { color: Colors.textPrimary, fontSize: 32, fontWeight: '900', marginVertical: 6 },
  heroCity: { color: Colors.textSecondary, fontSize: 13 },
  formCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: Spacing.lg,
  },
  formTitle: { color: Colors.accentLime, fontSize: 11, fontWeight: 'bold', marginBottom: 10 },
  inputRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  input: {
    flex: 1,
    backgroundColor: Colors.surface2,
    borderRadius: Radius.button,
    padding: 10,
    color: Colors.textPrimary,
    marginHorizontal: 4,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  btn: {
    backgroundColor: Colors.accentLime,
    borderRadius: Radius.button,
    padding: 12,
    alignItems: 'center',
    marginTop: 12,
  },
  btnText: { color: '#000000', fontWeight: 'bold', fontSize: 12 },
  sectionTitle: { fontSize: 12, fontWeight: 'bold', color: Colors.textSecondary, marginBottom: 8 },
  tripRow: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: 8,
  },
  tripRoute: { color: Colors.textPrimary, fontSize: 16, fontWeight: 'bold' },
  tripCity: { color: Colors.textSecondary, fontSize: 12, marginTop: 2 },
});
