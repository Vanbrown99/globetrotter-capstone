import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrotter_flutter/helpers/currency_formatter.dart';
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/services/api_service.dart';
import 'package:globetrotter_flutter/services/auth_service.dart';
import 'package:globetrotter_flutter/theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  late Future<List<Destination>> _destinationsFuture;
  Future<List<Destination>>? _recommendationsFuture;
  final MapController _mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  bool _showMap = false;
  bool _isLocating = false;
  LatLng? _userLocation;
  Destination? _selectedDestination;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _destinationsFuture = ApiService.getDestinations();
    _loadRecommendations();
    _startLocationWatch();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _startLocationWatch() async {
    setState(() => _isLocating = true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocating = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _isLocating = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _isLocating = false;
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final latest = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(latest.latitude, latest.longitude);
      });
    });
  }

  Future<void> _loadRecommendations() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    setState(() {
      _recommendationsFuture = ApiService.getRecommendations(token, limit: 5);
    });
  }

  /// Called externally (e.g. from the Globe tab's search shortcut) to focus
  /// this tab's search field.
  void focusSearch() {
    setState(() {}); // no-op placeholder for future focus-node wiring
  }

  List<Destination> _filter(List<Destination> destinations) {
    if (_searchQuery.isEmpty) return destinations;
    final q = _searchQuery.toLowerCase();
    return destinations.where((d) {
      final haystack =
          '${d.name} ${d.description} ${d.country} ${d.tags.join(' ')}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Destination>>(
      future: _destinationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final all = snapshot.data ?? [];
        final filtered = _filter(all);
        return Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            if (_searchQuery.isEmpty) _buildRecommendations(),
            Expanded(
              child: _showMap
                  ? _buildMap(all)
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('No destinations match your search.'))
                      : _buildList(filtered),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.navyDark,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Explore',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: () => setState(() => _showMap = !_showMap),
            icon: Icon(_showMap ? Icons.list : Icons.map, color: Colors.white),
            tooltip: _showMap ? 'List view' : 'Map view',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: TextField(
            controller: searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search destinations',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_recommendationsFuture == null) return const SizedBox.shrink();
    return FutureBuilder<List<Destination>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final recs = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Picked for you',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Chip(
                    label: Text(recs[i].name),
                    avatar: const Icon(Icons.star,
                        size: 16, color: AppColors.orangeDark),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<Destination> destinations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final d = destinations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.imageUrl.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: Image.network(
                    d.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      child: const Center(
                          child: Icon(Icons.broken_image, size: 40)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(d.description,
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: d.tags
                          .map((t) => Chip(
                                label: Text(t),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatCostInXaf(d.avgCostPerDay),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.orangeDark)),
                        Text(d.country,
                            style: const TextStyle(color: AppColors.textMuted)),
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

  Widget _buildMap(List<Destination> destinations) {
    final visible = destinations.take(12).toList();
    final markers = visible
        .map((d) => Marker(
              width: 40,
              height: 40,
              point: LatLng(d.latitude, d.longitude),
              builder: (_) => GestureDetector(
                onTap: () => setState(() => _selectedDestination = d),
                child: const Icon(Icons.location_on,
                    color: AppColors.orangeDark, size: 36),
              ),
            ))
        .toList();
    final center = _userLocation ??
        (visible.isNotEmpty
            ? LatLng(visible.first.latitude, visible.first.longitude)
            : LatLng(3.8480, 11.5021));

    final polylines = _selectedDestination == null || _userLocation == null
        ? <Polyline>[]
        : [
            Polyline(
              points: [
                _userLocation!,
                LatLng(_selectedDestination!.latitude,
                    _selectedDestination!.longitude)
              ],
              color: AppColors.navyDark,
              strokeWidth: 4,
            ),
          ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options:
              MapOptions(center: center, zoom: 12, maxZoom: 18, minZoom: 6),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.globetrotter_flutter',
              maxZoom: 18,
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: [
              if (_userLocation != null)
                Marker(
                  width: 44,
                  height: 44,
                  point: _userLocation!,
                  builder: (_) => const Icon(Icons.my_location,
                      color: AppColors.navyDark, size: 32),
                ),
              ...markers,
            ]),
          ],
        ),
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_isLocating)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.location_on,
                      color: AppColors.orangeDark, size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedDestination == null
                      ? 'Showing your area and nearby sites'
                      : 'Route to ${_selectedDestination!.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'explore-zoom-in',
                backgroundColor: AppColors.orange,
                onPressed: () => _mapController.move(
                    _mapController.center, _mapController.zoom + 1),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'explore-zoom-out',
                backgroundColor: AppColors.orange,
                onPressed: () => _mapController.move(
                    _mapController.center, _mapController.zoom - 1),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
