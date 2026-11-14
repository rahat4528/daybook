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
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 12, fontWeight: '700', color }}>TDY</Text>,
        }}
      />
      <Tabs.Screen
        name="trips"
        options={{
          title: 'Trips',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 12, fontWeight: '700', color }}>TRP</Text>,
        }}
      />
      <Tabs.Screen
        name="links"
        options={{
          title: 'Links',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 12, fontWeight: '700', color }}>LNK</Text>,
        }}
      />
      <Tabs.Screen
        name="habits"
        options={{
          title: 'Habits',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 12, fontWeight: '700', color }}>HBT</Text>,
        }}
      />
      <Tabs.Screen
        name="nfc"
        options={{
          title: 'NFC',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 12, fontWeight: '700', color }}>NFC</Text>,
        }}
      />
      <Tabs.Screen
        name="fitness"
        options={{
          title: 'BPM',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 12, fontWeight: '700', color }}>BPM</Text>,
        }}
      />
    </Tabs>
  );
}
