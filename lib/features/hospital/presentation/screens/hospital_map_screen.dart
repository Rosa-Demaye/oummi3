import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/features/hospital/presentation/providers/hospital_provider.dart';
import 'package:oummi3/shared/models/hospital_model.dart';
import 'package:oummi3/shared/models/booking_model.dart';
import 'package:intl/intl.dart';

class HospitalMapScreen extends ConsumerStatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  ConsumerState<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends ConsumerState<HospitalMapScreen> {
  late GoogleMapController mapController;
  static const LatLng _center = LatLng(12.1348, 15.0557);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);
    final activeBookingAsync = ref.watch(activeBookingStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilité en temps réel', 
          style: TextStyle(color: OumiColors.noirDoux, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: OumiColors.bleuSante),
            onPressed: () => ref.read(hospitalRepositoryProvider).seedMockHospitals(),
          )
        ],
      ),
      body: Stack(
        children: [
          hospitalsAsync.when(
            data: (hospitals) => GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _center,
                zoom: 12.0,
              ),
              markers: hospitals.map((h) => _buildMarker(context, h)).toSet(),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
          ),
          
          // Booking Status Overlay
          activeBookingAsync.when(
            data: (booking) => booking != null ? _BookingStatusOverlay(booking: booking) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: hospitalsAsync.when(
        data: (hospitals) => _LegendBar(),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Marker _buildMarker(BuildContext context, Hospital hospital) {
    final hue = _getStatusHue(hospital);
    return Marker(
      markerId: MarkerId(hospital.id),
      position: LatLng(hospital.latitude, hospital.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      onTap: () => _showHospitalDetails(context, hospital),
    );
  }

  double _getStatusHue(Hospital hospital) {
    if (hospital.status == HospitalStatus.emergencyOnly) return BitmapDescriptor.hueRed;
    if (hospital.status == HospitalStatus.crowded) return BitmapDescriptor.hueOrange;
    if (hospital.availableLaborRooms == 0) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueGreen;
  }

  void _showHospitalDetails(BuildContext context, Hospital hospital) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _HospitalDetailSheet(hospital: hospital),
    );
  }
}

class _HospitalDetailSheet extends ConsumerWidget {
  final Hospital hospital;
  const _HospitalDetailSheet({required this.hospital});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(hospital.name, 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: OumiColors.noirDoux)),
              ),
              _StatusChip(status: hospital.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(hospital.address, style: const TextStyle(color: OumiColors.grisTexte)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CapacityItem(
                icon: Icons.bed, 
                label: 'Lits Libres', 
                value: '${hospital.availableBeds}',
                color: OumiColors.bleuSante,
              ),
              _CapacityItem(
                icon: Icons.child_care, 
                label: 'Salles Travail', 
                value: '${hospital.availableLaborRooms}',
                color: OumiColors.oumiRose,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: hospital.availableLaborRooms > 0 
                    ? () => _handleBooking(context, ref)
                    : null,
                  style: OumiDecorations.primaryButton,
                  child: const Text('Réserver Salle de Travail'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Dernière mise à jour: ${DateFormat('HH:mm').format(hospital.lastUpdate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(hospitalRepositoryProvider).bookLaborRoom(hospital);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande de réservation envoyée à ${hospital.name}'),
          backgroundColor: OumiColors.vertSante,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: OumiColors.rougeUrgence),
      );
    }
  }
}

class _BookingStatusOverlay extends StatelessWidget {
  final LaborRoomBooking booking;
  const _BookingStatusOverlay({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: OumiColors.bleuSante,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Réservation en cours', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Hôpital: ${booking.hospitalName}', 
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text(booking.status.name.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final HospitalStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case HospitalStatus.open: color = OumiColors.vertSante; text = 'Disponible'; break;
      case HospitalStatus.crowded: color = OumiColors.orangeAlerte; text = 'Affluence'; break;
      case HospitalStatus.emergencyOnly: color = OumiColors.rougeUrgence; text = 'Urgences Uniq.'; break;
      case HospitalStatus.closed: color = Colors.grey; text = 'Fermé'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _CapacityItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _CapacityItem({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: OumiColors.grisTexte)),
      ],
    );
  }
}

class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(color: Colors.green, label: 'Libre'),
          _LegendItem(color: Colors.yellow, label: 'Travail Plein'),
          _LegendItem(color: Colors.orange, label: 'Affluence'),
          _LegendItem(color: Colors.red, label: 'Urgence'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: OumiColors.grisTexte)),
      ],
    );
  }
}
