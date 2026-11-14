import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { triggerNfcTag } from '../../modules/nfc/nfc-routine-manager';

export default function NfcTabScreen() {
  const [feedback, setFeedback] = useState<string | null>(null);

  const testTags = [
    { name: '🌱 Water Desk Plants', uid: '04:A2:8B:11:F2:60:80' },
    { name: '🔑 Keys Placed at Home', uid: '04:B3:9C:22:E3:71:81' },
    { name: '💊 Daily Vitamins Taken', uid: '04:C4:0D:33:D4:82:82' },
    { name: '☕ Morning Coffee Ritual', uid: '04:D5:1E:44:C5:93:83' },
  ];

  const handleSimulatedTap = async (uid: string) => {
    const res = await triggerNfcTag(uid);
    setFeedback(res.message);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.headerTitle}>NFC ROUTINE AUTOMATION</Text>
      <Text style={styles.headerSubtitle}>react-native-nfc-manager • expo-sqlite</Text>

      {/* Radar Card */}
      <View style={styles.radarCard}>
        <Text style={styles.radarIcon}>📡</Text>
        <Text style={styles.radarTitle}>HOLD PHONE TO NFC STICKER</Text>
        <Text style={styles.radarDesc}>13.56 MHz High-Frequency RF Sensor Active</Text>
        {feedback && (
          <View style={styles.feedbackBox}>
            <Text style={styles.feedbackText}>{feedback}</Text>
          </View>
        )}
      </View>

      <Text style={styles.sectionTitle}>SIMULATE PHYSICAL HARDWARE TAPS</Text>
      {testTags.map(tag => (
        <TouchableOpacity
          key={tag.uid}
          style={styles.tagCard}
          onPress={() => handleSimulatedTap(tag.uid)}
        >
          <View>
            <Text style={styles.tagName}>{tag.name}</Text>
            <Text style={styles.tagUid}>UID: {tag.uid}</Text>
          </View>
          <View style={styles.tagAction}>
            <Text style={styles.tagActionText}>Tap Tag</Text>
          </View>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md },
  headerTitle: { fontSize: 20, fontWeight: '900', color: Colors.textPrimary },
  headerSubtitle: { fontSize: 11, color: Colors.accentLime, marginBottom: Spacing.md },
  radarCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.lg,
    borderWidth: 1.5,
    borderColor: Colors.accentLimeBorder,
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  radarIcon: { fontSize: 40, marginBottom: 8 },
  radarTitle: { color: Colors.textPrimary, fontSize: 14, fontWeight: 'bold' },
  radarDesc: { color: Colors.textSecondary, fontSize: 11, marginTop: 4 },
  feedbackBox: {
    marginTop: 12,
    backgroundColor: Colors.bg,
    borderRadius: Radius.pill,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: Colors.accentLime,
  },
  feedbackText: { color: Colors.accentLime, fontSize: 12, fontWeight: 'bold' },
  sectionTitle: { fontSize: 12, fontWeight: 'bold', color: Colors.textSecondary, marginBottom: 8 },
  tagCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  tagName: { color: Colors.textPrimary, fontSize: 14, fontWeight: 'bold' },
  tagUid: { color: Colors.textSecondary, fontSize: 10, fontFamily: 'monospace', marginTop: 2 },
  tagAction: {
    backgroundColor: Colors.accentLime,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: Radius.pill,
  },
  tagActionText: { color: '#000000', fontSize: 11, fontWeight: 'bold' },
});
