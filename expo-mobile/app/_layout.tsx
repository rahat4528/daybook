import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Colors } from '../shared/theme/tokens';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="light" backgroundColor="#000000" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: Colors.surface1 },
          headerTintColor: Colors.textPrimary,
          contentStyle: { backgroundColor: Colors.bg },
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="(modals)/share-capture"
          options={{
            presentation: 'modal',
            title: 'Save Link to DayBook',
            headerStyle: { backgroundColor: Colors.surface1 },
          }}
        />
      </Stack>
    </>
  );
}
