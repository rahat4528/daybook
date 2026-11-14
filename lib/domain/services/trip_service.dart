// Trip Service for DayBook
// Handles multi-trip management, countdown updates, and widget payload generation.

import 'dart:convert';
import '../models/trip_item.dart';
import '../../data/repositories/entries_repository.dart';

class TripService {
  final EntriesRepository? entriesRepo;
  final List<TripItem> _trips = [];

  TripService({this.entriesRepo}) {
    _seedDefaultTrips();
  }

  void _seedDefaultTrips() {
    final now = DateTime.now().toUtc();
    _trips.add(
      TripItem(
        id: 'trip_default_1',
        originIata: 'DAC',
        destinationIata: 'LHR',
        destinationCity: 'London',
        flightNumber: 'BG201',
        departureTimeUtc: now.add(const Duration(days: 8, hours: 4, minutes: 30)),
        status: 'scheduled',
        notes: 'Terminal 4, Seat 14A. Carry-on luggage only.',
        isPinnedForWidget: true,
      ),
    );
  }

  List<TripItem> get allTrips => List.unmodifiable(_trips);

  TripItem? get pinnedTrip {
    if (_trips.isEmpty) return null;
    return _trips.firstWhere(
      (t) => t.isPinnedForWidget && !t.isDeparted,
      orElse: () => _trips.first,
    );
  }

  void addTrip(TripItem trip) {
    if (trip.isPinnedForWidget) {
      // Unpin others
      for (var i = 0; i < _trips.length; i++) {
        _trips[i] = _trips[i].copyWith(isPinnedForWidget: false);
      }
    }
    _trips.insert(0, trip);
    _logTripToEntries(trip, 'trip_created');
  }

  void updateTrip(TripItem updated) {
    final index = _trips.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      if (updated.isPinnedForWidget) {
        for (var i = 0; i < _trips.length; i++) {
          if (i != index) {
            _trips[i] = _trips[i].copyWith(isPinnedForWidget: false);
          }
        }
      }
      _trips[index] = updated;
    }
  }

  void deleteTrip(String id) {
    _trips.removeWhere((t) => t.id == id);
  }

  void pinTripForWidget(String id) {
    for (var i = 0; i < _trips.length; i++) {
      _trips[i] = _trips[i].copyWith(isPinnedForWidget: _trips[i].id == id);
    }
  }

  Map<String, dynamic>? getWidgetPayloadSnapshot() {
    final pinned = pinnedTrip;
    if (pinned == null) return null;
    return pinned.toWidgetSnapshot();
  }

  String exportWidgetJson() {
    final snapshot = getWidgetPayloadSnapshot();
    if (snapshot == null) return '{}';
    return jsonEncode(snapshot);
  }

  void _logTripToEntries(TripItem trip, String action) {
    entriesRepo?.createManualEntry(
      type: 'trip_event',
      payload: {
        'action': action,
        'tripId': trip.id,
        'route': trip.routeFormatted,
        'departureUtc': trip.departureTimeUtc.toIso8601String(),
        'destination': trip.destinationCity,
      },
      source: 'trip_service',
    );
  }
}
