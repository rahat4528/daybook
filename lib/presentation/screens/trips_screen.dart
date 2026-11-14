// Trip Countdown with Live Widgets Screen (Page 01)
// Clean OLED Black (#000000) & Lime (#B6FF00) interface for travel countdowns and widget preview.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/trip_item.dart';
import '../../domain/services/trip_service.dart';

class TripsScreen extends StatefulWidget {
  final TripService tripService;
  final bool isBangla;

  const TripsScreen({
    super.key,
    required this.tripService,
    this.isBangla = false,
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 1-second countdown refresh ticker
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openAddTripDialog() {
    final originCtrl = TextEditingController(text: 'DAC');
    final destCtrl = TextEditingController(text: 'JFK');
    final cityCtrl = TextEditingController(text: 'New York');
    final flightCtrl = TextEditingController(text: 'EK202');
    final notesCtrl = TextEditingController();
    DateTime departureDate = DateTime.now().add(const Duration(days: 14, hours: 6));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBangla ? 'নতুন ট্রিপ যুক্ত করুন' : 'ADD UPCOMING TRIP',
                style: const TextStyle(
                  color: AppColors.accentLime,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: originCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Origin IATA',
                        hintText: 'DAC',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, color: AppColors.accentLime),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: destCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Dest IATA',
                        hintText: 'JFK',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination City',
                  hintText: 'New York',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: flightCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Flight #',
                        hintText: 'EK202',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: departureDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            departureDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              departureDate.hour,
                              departureDate.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.accentLime),
                      label: Text(
                        '${departureDate.day}/${departureDate.month}/${departureDate.year}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes & Terminal',
                  hintText: 'Terminal 1, Seat 12K',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  onPressed: () {
                    final origin = originCtrl.text.trim().toUpperCase();
                    final dest = destCtrl.text.trim().toUpperCase();
                    final city = cityCtrl.text.trim();
                    if (origin.isEmpty || dest.isEmpty || city.isEmpty) return;

                    final newTrip = TripItem(
                      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
                      originIata: origin,
                      destinationIata: dest,
                      destinationCity: city,
                      flightNumber: flightCtrl.text.trim().isEmpty ? null : flightCtrl.text.trim().toUpperCase(),
                      departureTimeUtc: departureDate.toUtc(),
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      isPinnedForWidget: true,
                    );

                    widget.tripService.addTrip(newTrip);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: Text(
                    widget.isBangla ? 'ট্রিপ নিশ্চিত করুন' : 'SAVE TRIP & SYNC WIDGET',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = widget.tripService.allTrips;
    final pinned = widget.tripService.pinnedTrip;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.isBangla ? 'ট্রিপ কাউন্টডাউন ও উইজেট' : 'TRIP COUNTDOWN',
          style: AppTypography.screenTitle,
        ),
        backgroundColor: AppColors.surface1,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets_outlined, color: AppColors.accentLime),
            tooltip: 'Widget Snapshot JSON',
            onPressed: () {
              final jsonStr = widget.tripService.exportWidgetJson();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface2,
                  title: const Text('WidgetKit JSON Payload', style: TextStyle(color: AppColors.accentLime)),
                  content: SelectableText(jsonStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close', style: TextStyle(color: AppColors.accentLime)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Active Trip Showcase
            if (pinned != null) ...[
              Text(
                widget.isBangla ? 'সক্রিয় পিনযুক্ত ট্রিপ' : 'ACTIVE PINNED TRIP',
                style: AppTypography.sectionHeader,
              ),
              const SizedBox(height: 8),
              _buildPinnedTripHero(pinned),
              const SizedBox(height: 16),

              // Live Widget Simulation Preview Card
              Text(
                widget.isBangla ? 'হোম ও লক স্ক্রিন উইজেট প্রিভিউ' : 'LIVE WIDGET ARCHITECTURE PREVIEW',
                style: AppTypography.sectionHeader,
              ),
              const SizedBox(height: 8),
              _buildWidgetSimulationPreview(pinned),
              const SizedBox(height: 24),
            ],

            // All Itineraries List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isBangla ? 'সকল ভ্রমণ সূচি' : 'ALL ITINERARIES',
                  style: AppTypography.sectionHeader,
                ),
                Text(
                  '${trips.length} Total',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (trips.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.flight_takeoff, color: AppColors.textSecondary, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      widget.isBangla ? 'কোন আসন্ন ট্রিপ নেই' : 'No upcoming trips planned.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...trips.map((t) => _buildTripListItem(t)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentLime,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(
          widget.isBangla ? 'ট্রিপ যোগ করুন' : 'New Trip',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _openAddTripDialog,
      ),
    );
  }

  Widget _buildPinnedTripHero(TripItem trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentLime, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentLime.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'PINNED FOR WIDGETS',
                  style: TextStyle(
                    color: AppColors.accentLime,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (trip.flightNumber != null)
                Text(
                  trip.flightNumber!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.originIata, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const Text('Origin', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.flight, color: AppColors.accentLime, size: 28),
                  Text(
                    trip.destinationCity,
                    style: const TextStyle(color: AppColors.accentLime, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(trip.destinationIata, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const Text('Destination', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.accentLime, size: 20),
                const SizedBox(width: 8),
                Text(
                  trip.countdownFormatted,
                  style: const TextStyle(
                    color: AppColors.accentLime,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (trip.notes != null) ...[
            const SizedBox(height: 10),
            Text(
              trip.notes!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWidgetSimulationPreview(TripItem trip) {
    return Row(
      children: [
        // Small Square Home Screen Widget Simulation
        Expanded(
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.flight, color: AppColors.accentLime, size: 16),
                    Text(trip.routeFormatted, style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  trip.countdownFormatted,
                  style: const TextStyle(color: AppColors.accentLime, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(trip.destinationCity, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Lock Screen Accessory Rectangular Complication
        Expanded(
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('LOCK SCREEN COMPLICATION', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(trip.routeFormatted, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  trip.countdownFormatted,
                  style: const TextStyle(color: AppColors.accentLime, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripListItem(TripItem trip) {
    final isPinned = trip.isPinnedForWidget;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isPinned ? AppColors.accentLime.withValues(alpha: 0.6) : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.routeFormatted} • ${trip.destinationCity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.countdownFormatted} (Flight: ${trip.flightNumber ?? "N/A"})',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? AppColors.accentLime : AppColors.textSecondary,
            ),
            tooltip: 'Pin to Widget',
            onPressed: () {
              widget.tripService.pinTripForWidget(trip.id);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: () {
              widget.tripService.deleteTrip(trip.id);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
