import { Tabs } from 'expo-router';
import { Colors } from '../../shared/theme/tokens';
import { Text } from 'react-native';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarStyle: {
          backgroundColor: Colors.surface1,
          borderTopColor: Colors.border,
          height: 60,
          paddingBottom: 8,
        },
        tabBarActiveTintColor: Colors.accentLime,
        tabBarInactiveTintColor: Colors.textSecondary,
        headerStyle: { backgroundColor: Colors.surface1 },
        headerTintColor: Colors.textPrimary,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Today',
          tabBarIcon: () => <Text style={{ fontSize: 18 }}>☀️</Text>,
        }}
      />
      <Tabs.Screen
        name="trips"
        options={{
          title: 'Trips',
          tabBarIcon: () => <Text style={{ fontSize: 18 }}>✈️</Text>,
        }}
      />
      <Tabs.Screen
        name="links"
        options={{
          title: 'Links',
          tabBarIcon: () => <Text style={{ fontSize: 18 }}>🔖</Text>,
        }}
      />
      <Tabs.Screen
        name="habits"
        options={{
          title: 'Habits',
          tabBarIcon: () => <Text style={{ fontSize: 18 }}>⚡</Text>,
        }}
      />
      <Tabs.Screen
        name="nfc"
        options={{
          title: 'NFC',
          tabBarIcon: () => <Text style={{ fontSize: 18 }}>📡</Text>,
        }}
      />
      <Tabs.Screen
        name="fitness"
        options={{
          title: 'BPM',
          tabBarIcon: () => <Text style={{ fontSize: 18 }}>❤️</Text>,
        }}
      />
    </Tabs>
  );
}
