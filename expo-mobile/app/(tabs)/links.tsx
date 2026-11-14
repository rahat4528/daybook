import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, TouchableOpacity } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { getAllLinks, saveSharedLink, SavedLinkRow } from '../../modules/links/links-db';

export default function LinksTabScreen() {
  const [links, setLinks] = useState<SavedLinkRow[]>([]);
  const [url, setUrl] = useState('');
  const [title, setTitle] = useState('');

  const loadData = async () => {
    try {
      const data = await getAllLinks();
      setLinks(data);
    } catch {
      // Fallback
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSave = async () => {
    if (!url) return;
    await saveSharedLink(url, title || undefined);
    setUrl('');
    setTitle('');
    await loadData();
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.headerTitle}>LINK SAVER & READING LIST</Text>
      <Text style={styles.headerSubtitle}>Native Share Sheet Intent & expo-sqlite</Text>

      {/* Manual / Share Simulator Input */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>CAPTURE SHARED INTENT</Text>
        <TextInput
          style={styles.input}
          value={url}
          onChangeText={setUrl}
          placeholder="https://example.com/article"
          placeholderTextColor={Colors.textSecondary}
        />
        <TextInput
          style={[styles.input, { marginTop: 8 }]}
          value={title}
          onChangeText={setTitle}
          placeholder="Custom title (Optional)"
          placeholderTextColor={Colors.textSecondary}
        />
        <TouchableOpacity style={styles.btn} onPress={handleSave}>
          <Text style={styles.btnText}>SAVE TO READING LIST</Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.sectionTitle}>SAVED ARTICLES & BOOKMARKS ({links.length})</Text>
      {links.map(l => (
        <View key={l.id} style={styles.linkCard}>
          <Text style={styles.domainChip}>{l.domain}</Text>
          <Text style={styles.linkTitle}>{l.title}</Text>
          <Text style={styles.linkUrl} numberOfLines={1}>{l.canonical_url}</Text>
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
  card: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: Spacing.lg,
  },
  cardTitle: { color: Colors.accentLime, fontSize: 11, fontWeight: 'bold', marginBottom: 10 },
  input: {
    backgroundColor: Colors.surface2,
    borderRadius: Radius.button,
    padding: 10,
    color: Colors.textPrimary,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  btn: {
    backgroundColor: Colors.accentLime,
    borderRadius: Radius.button,
    padding: 12,
    alignItems: 'center',
    marginTop: 10,
  },
  btnText: { color: '#000000', fontWeight: 'bold', fontSize: 12 },
  sectionTitle: { fontSize: 12, fontWeight: 'bold', color: Colors.textSecondary, marginBottom: 8 },
  linkCard: {
    backgroundColor: Colors.surface1,
    borderRadius: Radius.card,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: 10,
  },
  domainChip: { color: Colors.accentLime, fontSize: 10, fontWeight: 'bold', marginBottom: 4 },
  linkTitle: { color: Colors.textPrimary, fontSize: 14, fontWeight: 'bold' },
  linkUrl: { color: Colors.textSecondary, fontSize: 11, marginTop: 4, fontFamily: 'monospace' },
});
