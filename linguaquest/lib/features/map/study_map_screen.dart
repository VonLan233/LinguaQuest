import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/location_service.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fallback_back_button.dart';

class StudyMapScreen extends ConsumerStatefulWidget {
  const StudyMapScreen({super.key});

  @override
  ConsumerState<StudyMapScreen> createState() => _StudyMapScreenState();
}

class _StudyMapScreenState extends ConsumerState<StudyMapScreen> {
  final MapController _map = MapController();
  static const LatLng _fallbackCenter = LatLng(3.139, 101.6869); // KL

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).loadStudySpots();
    });
  }

  Future<void> _saveHere() async {
    final loc = await currentLatLng();
    if (!mounted) return;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location unavailable — long-press the map to pick a spot.',
          ),
        ),
      );
    }
    await _saveAt(loc ?? _map.camera.center);
  }

  Future<void> _saveAt(LatLng loc) async {
    if (!mounted) return;
    final name = await _askName();
    if (name == null || name.trim().isEmpty) return;
    await ref.read(appControllerProvider.notifier).recordStudyVisit(
          name: name.trim(),
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
    if (mounted) _map.move(loc, 15);
  }

  Future<String?> _askName() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Save study spot',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: AppTokens.s16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'e.g. Library'),
                ),
                const SizedBox(height: AppTokens.s16),
                AppPrimaryButton(
                  label: 'Save',
                  onPressed: () => Navigator.of(ctx).pop(controller.text),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots =
        ref.watch(appControllerProvider.select((s) => s.studySpots));
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('Study Map'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveHere,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Save here'),
      ),
      body: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: spots.isNotEmpty
              ? LatLng(spots.first.latitude, spots.first.longitude)
              : _fallbackCenter,
          initialZoom: 13,
          onLongPress: (TapPosition tapPosition, LatLng latlng) =>
              _saveAt(latlng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.linguaquest',
          ),
          CircleLayer(
            circles: [
              for (final s in spots)
                CircleMarker(
                  point: LatLng(s.latitude, s.longitude),
                  radius: (12 + s.visitCount * 6).clamp(12, 48).toDouble(),
                  color: Colors.deepOrange.withValues(
                    alpha: (0.15 + s.visitCount * 0.12).clamp(0.15, 0.6),
                  ),
                  borderStrokeWidth: 0,
                ),
            ],
          ),
          MarkerLayer(
            markers: [
              for (final s in spots)
                Marker(
                  point: LatLng(s.latitude, s.longitude),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.place, color: Colors.red, size: 36),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
