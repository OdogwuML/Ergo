import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/building_service.dart';
import 'add_unit_screen.dart';

class UnitListScreen extends StatefulWidget {
  final Map<String, dynamic> building;

  const UnitListScreen({super.key, required this.building});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  final _buildingService = BuildingService();
  late Future<List<dynamic>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _refreshUnits();
  }

  void _refreshUnits() {
    setState(() {
      _unitsFuture = _buildingService.getUnits(widget.building['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.building['name'], style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.building['address'], style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final units = snapshot.data ?? [];

          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.door_sliding_outlined, size: 64, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No units added yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Tap the + button to add units to this property.', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _navigateToAddUnit(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    child: const Text('Add First Unit'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final bool isOccupied = unit['status'] == 'occupied';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                borderOnForeground: true,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isOccupied ? AppTheme.primary.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    child: Icon(
                      Icons.meeting_room,
                      color: isOccupied ? AppTheme.primary : Colors.green,
                    ),
                  ),
                  title: Text(
                    unit['unit_number'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '₦${(unit['rent_amount'] / 100).toStringAsFixed(0)} / month',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOccupied ? AppTheme.primary.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOccupied ? 'OCCUPIED' : 'VACANT',
                      style: TextStyle(
                        color: isOccupied ? AppTheme.primary : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigate to Unit Details or Invite Tenant
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _navigateToAddUnit(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _navigateToAddUnit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUnitScreen(building: widget.building),
      ),
    );

    if (result == true) {
      _refreshUnits();
    }
  }
}
