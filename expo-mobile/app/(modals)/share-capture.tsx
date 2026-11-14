import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity } from 'react-native';
import { Colors, Spacing, Radius } from '../../shared/theme/tokens';
import { saveSharedLink } from '../../modules/links/links-db';
import { useRouter, useLocalSearchParams } from 'expo-router';

export default function ShareCaptureModal() {
  const router = useRouter();
  const params = useLocalSearchParams<{ url?: string; title?: string }>();
  const [url, setUrl] = useState(params.url || '');
  const [title, setTitle] = useState(params.title || '');

  const handleSave = async () => {
    if (!url) return;
    await saveSharedLink(url, title || undefined);
    router.back();
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>CAPTURE SHARED INTENT</Text>
      <Text style={styles.subtitle}>Received via iOS Action Extension or Android SEND Intent</Text>

      <TextInput
        style={styles.input}
        value={url}
        onChangeText={setUrl}
        placeholder="Shared Web URL"
        placeholderTextColor={Colors.textSecondary}
      />
      <TextInput
        style={[styles.input, { marginTop: 10 }]}
        value={title}
        onChangeText={setTitle}
        placeholder="Page Title"
        placeholderTextColor={Colors.textSecondary}
      />

      <TouchableOpacity style={styles.btn} onPress={handleSave}>
        <Text style={styles.btnText}>COMMIT TO DAYBOOK (SQLITE)</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.surface1, padding: Spacing.lg },
  title: { fontSize: 16, fontWeight: 'bold', color: Colors.accentLime, letterSpacing: 0.8 },
  subtitle: { fontSize: 11, color: Colors.textSecondary, marginBottom: Spacing.lg, marginTop: 4 },
  input: {
    backgroundColor: Colors.surface2,
    borderRadius: Radius.button,
    padding: 12,
    color: Colors.textPrimary,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  btn: {
    backgroundColor: Colors.accentLime,
    borderRadius: Radius.button,
    padding: 14,
    alignItems: 'center',
    marginTop: 20,
  },
  btnText: { color: '#000000', fontWeight: 'bold', fontSize: 13 },
});
