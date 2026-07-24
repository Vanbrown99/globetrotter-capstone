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
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String _username = 'Traveler';
  String _email = '';
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    destinationsFuture = ApiService.getDestinations();
    _loadUsername();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final savedUsername = await AuthService.getUsername();
    final savedEmail = await AuthService.getEmail();
    if (!mounted) return;
    setState(() {
      _username =
          savedUsername?.isNotEmpty == true ? savedUsername! : 'Traveler';
      _email = savedEmail?.isNotEmpty == true ? savedEmail! : '';
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

  List<Destination> _filterDestinations(List<Destination> destinations) {
    if (_searchQuery.isEmpty) {
      return destinations;
    }
    final query = _searchQuery.toLowerCase();
    return destinations.where((destination) {
      final haystack = '${destination.name} ${destination.description} ${destination.country} ${destination.tags.join(' ')}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search destinations in Yaoundé',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCards(List<Destination> destinations) {
    final suggestions = destinations.take(4).toList();
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final destination = suggestions[index];
          return SizedBox(
            width: 180,
            child: Card(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (destination.imageUrl.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: Image.network(
                        destination.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image_not_supported)),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Destination> destinations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (destination.imageUrl.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: Image.network(
                    destination.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(destination.description),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${destination.avgCostPerDay}/day',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(destination.country,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          if (_email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Signed in as $_email',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Discover Yaoundé’s best destinations and local flavors.',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_email.isNotEmpty)
              Text(
                _email,
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile priorities', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: const [
                        Chip(label: Text('Food spots')),
                        Chip(label: Text('Nature')),
                        Chip(label: Text('Culture')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Saved spots'),
              subtitle: const Text('Your personal favorites'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Visit history'),
              subtitle: const Text('Places you explored recently'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<Destination> destinations) {
    final visibleDestinations = destinations.take(8).toList();
    final markers = visibleDestinations.asMap().entries.map((entry) {
      final isFavorite = entry.key < 3;
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(entry.value.latitude, entry.value.longitude),
        builder: (context) => Icon(
          Icons.location_on,
          color: isFavorite ? Colors.teal : Colors.orange,
          size: 40,
        ),
      );
    }).toList();

    final firstPoint = visibleDestinations.isNotEmpty
        ? LatLng(
            visibleDestinations.first.latitude,
            visibleDestinations.first.longitude,
          )
        : const LatLng(3.8480, 11.5021);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: firstPoint,
            zoom: 12,
            maxZoom: 18,
            minZoom: 8,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.globetrotter_flutter',
              maxZoom: 18,
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: 16,
          top: 16,
          child: Card(
            color: Theme.of(context).colorScheme.surface.withAlpha(230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.place, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Yaoundé map view',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom-in',
                onPressed: () {
                  final currentZoom = _mapController.zoom + 1;
                  _mapController.move(_mapController.center, currentZoom);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom-out',
                onPressed: () {
                  final currentZoom = _mapController.zoom - 1;
                  _mapController.move(_mapController.center, currentZoom);
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenter',
                onPressed: () => _mapController.move(firstPoint, 12),
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Destination>>(
      future: destinationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        final allDestinations = snapshot.data ?? [];
        final destinations = _filterDestinations(allDestinations);
        return Scaffold(
          appBar: AppBar(
            title: Text('Hello, $_username'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          drawer: _buildProfileDrawer(),
          body: _selectedIndex == 0
              ? Column(
                  children: [
                    _buildExploreHeader(),
                    _buildSearchBar(),
                    _buildSuggestionCards(destinations),
                    Expanded(
                      child: destinations.isEmpty
                          ? const Center(child: Text('No destinations match your search.'))
                          : _buildListView(destinations),
                    ),
                  ],
                )
              : _buildMap(allDestinations),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabChanged,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
              NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
            ],
          ),
        );
      },
    );
  }
}
