import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/services/api_service.dart';
import 'package:globetrotter_flutter/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Destination>> destinationsFuture;
  String _username = 'Traveler';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    destinationsFuture = ApiService.getDestinations();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final savedUsername = await AuthService.getUsername();
    if (!mounted) return;
    setState(() {
      _username =
          savedUsername?.isNotEmpty == true ? savedUsername! : 'Traveler';
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildListView(List<Destination> destinations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: Text(destination.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destination.description),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: destination.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            trailing: Text('\$${destination.avgCostPerDay}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _buildExploreHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $_username',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover Yaoundé’s best destinations and local flavors.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMap(List<Destination> destinations) {
    final markers = destinations
        .map(
          (destination) => Marker(
            width: 40,
            height: 40,
            point: LatLng(destination.latitude, destination.longitude),
            builder: (context) =>
                const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        )
        .toList();

    final firstPoint = destinations.isNotEmpty
        ? LatLng(destinations[0].latitude, destinations[0].longitude)
        : LatLng(3.8480, 11.5021);

    return FlutterMap(
      options: MapOptions(
        center: firstPoint,
        zoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.globetrotter_flutter',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Destination>>(
      future: destinationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }
        final destinations = snapshot.data ?? [];
        return Scaffold(
          appBar: AppBar(
            title: Text('Hello, $_username'),
            actions: [
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: _selectedIndex == 0
              ? Column(
                  children: [
                    _buildExploreHeader(),
                    Expanded(child: _buildListView(destinations)),
                  ],
                )
              : Stack(
                  children: [
                    _buildMap(destinations),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.place, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Yaoundé map view',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabChanged,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.explore), label: 'Explore'),
              NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
            ],
          ),
        );
      },
    );
  }
}
