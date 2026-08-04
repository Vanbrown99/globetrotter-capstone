import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/models/itinerary.dart';
import 'package:globetrotter_flutter/services/api_service.dart';
import 'package:globetrotter_flutter/services/auth_service.dart';
import 'package:globetrotter_flutter/theme/app_theme.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  Future<List<Itinerary>>? _itinerariesFuture;
  List<Destination> _allDestinations = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _token = await AuthService.getToken();
    _allDestinations = await ApiService.getDestinations();
    if (_token != null) {
      setState(() {
        _itinerariesFuture = ApiService.getItineraries(_token!);
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _openCreateSheet() async {
    if (_token == null) return;
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final Set<String> selected = {};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New itinerary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: 'Trip title'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Destinations',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDestinations.map((d) {
                        final isSelected = selected.contains(d.name);
                        return FilterChip(
                          label: Text(d.name),
                          selected: isSelected,
                          onSelected: (v) => setSheetState(() {
                            v ? selected.add(d.name) : selected.remove(d.name);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration:
                          const InputDecoration(hintText: 'Notes (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        try {
                          await ApiService.createItinerary(
                            _token!,
                            title: titleController.text.trim(),
                            destinations: selected.toList(),
                            notes: notesController.text.trim(),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          _load();
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                      child: const Text('Save itinerary'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary Hub'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: _token == null
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.orange,
              onPressed: _openCreateSheet,
              child: const Icon(Icons.add),
            ),
      body: _token == null
          ? const Center(child: Text('Log in to manage itineraries.'))
          : FutureBuilder<List<Itinerary>>(
              future: _itinerariesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final itineraries = snapshot.data ?? [];
                if (itineraries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No trips yet. Tap + to plan your first itinerary.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itineraries.length,
                  itemBuilder: (context, index) {
                    final it = itineraries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ExpansionTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flight,
                              color: AppColors.orangeDark),
                        ),
                        title: Text(it.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          [it.startDate, it.endDate]
                              .where((s) => s.isNotEmpty)
                              .join(' – '),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (it.destinations.isNotEmpty) ...[
                                  const Text('Stops',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: it.destinations
                                        .map((name) => Chip(label: Text(name)))
                                        .toList(),
                                  ),
                                ],
                                if (it.notes.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(it.notes,
                                      style: const TextStyle(
                                          color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
