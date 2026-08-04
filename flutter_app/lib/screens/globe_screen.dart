import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/models/itinerary.dart';
import 'package:globetrotter_flutter/services/api_service.dart';
import 'package:globetrotter_flutter/services/auth_service.dart';
import 'package:globetrotter_flutter/theme/app_theme.dart';

/// The "Globe" tab: the dashboard-style landing page shown in the
/// reference design — greeting header, search shortcut, an "Explore Today"
/// rail, and an upcoming-trips summary pulled from real itineraries.
class GlobeScreen extends StatefulWidget {
  final VoidCallback onSearchTapped;
  final VoidCallback onSeeAllTrips;

  const GlobeScreen({
    super.key,
    required this.onSearchTapped,
    required this.onSeeAllTrips,
  });

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> {
  String _username = 'Traveler';
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_DashboardData> _load() async {
    final savedUsername = await AuthService.getUsername();
    if (savedUsername?.isNotEmpty == true) _username = savedUsername!;

    final destinations = await ApiService.getDestinations();

    List<Itinerary> itineraries = [];
    final token = await AuthService.getToken();
    if (token != null) {
      try {
        itineraries = await ApiService.getItineraries(token);
      } catch (_) {
        // Non-fatal: dashboard still works without itineraries.
      }
    }
    return _DashboardData(destinations: destinations, itineraries: itineraries);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _dataFuture = _load());
            await _dataFuture;
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(),
              _buildSearchShortcut(),
              const SizedBox(height: 8),
              _sectionTitle('Explore Today'),
              _buildExploreToday(data.destinations),
              const SizedBox(height: 16),
              _sectionTitle('Your Upcoming Trips',
                  onSeeAll: widget.onSeeAllTrips),
              _buildUpcomingTrips(data.itineraries),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Globe Trotter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back, $_username',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.public, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchShortcut() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 3,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onSearchTapped,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Text(
                    'Search places, itineraries...',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(color: AppColors.orangeDark)),
            ),
        ],
      ),
    );
  }

  Widget _buildExploreToday(List<Destination> destinations) {
    final picks = destinations.take(6).toList();
    if (picks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('No destinations available yet.'),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: picks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final d = picks[index];
          return _ExploreCard(destination: d);
        },
      ),
    );
  }

  Widget _buildUpcomingTrips(List<Itinerary> itineraries) {
    if (itineraries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.card_travel, color: AppColors.textMuted),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No trips planned yet. Head to the Itinerary tab to create one.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: itineraries.take(3).map((it) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flight_takeoff,
                    color: AppColors.orangeDark),
              ),
              title: Text(it.title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                it.destinations.isEmpty
                    ? 'No destinations added'
                    : it.destinations.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final Destination destination;
  const _ExploreCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: destination.imageUrl.isNotEmpty
                  ? Image.network(
                      destination.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      child: const Icon(Icons.landscape,
                          color: AppColors.textMuted),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.country,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<Destination> destinations;
  final List<Itinerary> itineraries;
  _DashboardData({required this.destinations, required this.itineraries});
}
