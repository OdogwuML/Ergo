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
    debugPrint('DEBUG: UnitListScreen building keys: ${widget.building.keys.toList()}');
    debugPrint('DEBUG: photo_url value: ${widget.building['photo_url']}');
    _refreshUnits();
  }

  void _refreshUnits() {
    debugPrint('DEBUG: Calling getUnits for building: ${widget.building['id']}');
    setState(() {
      _unitsFuture = _buildingService.getUnits(widget.building['id']).then((units) {
        debugPrint('DEBUG: Received ${units.length} units from API');
        return units;
      });
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
            return RefreshIndicator(
              onRefresh: () async {
                _refreshUnits();
                await _unitsFuture;
              },
              child: ListView(
                children: [
                   SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                   Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.door_sliding_outlined, size: 64, color: Colors.black12),
                        const SizedBox(height: 16),
                        const Text('No units added yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Pull down to refresh or add manually.', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _navigateToAddUnit(context),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                          child: const Text('Add First Unit'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshUnits();
              await _unitsFuture;
            },
            child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final bool isOccupied = unit['status'] == 'occupied';
              final String unitNumber = unit['unit_number'];
              final String rent = '₦${(unit['rent_amount'] / 100).toStringAsFixed(0)}';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isOccupied 
                                ? AppTheme.primary.withOpacity(0.08) 
                                : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: (widget.building['photo_url'] != null && widget.building['photo_url'].toString().isNotEmpty)
                                ? Image.network(
                                    widget.building['photo_url'],
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('DEBUG: Image load error: $error for URL: ${widget.building['photo_url']}');
                                      return Icon(
                                        isOccupied ? Icons.person_outline : Icons.door_front_door_outlined,
                                        color: isOccupied ? AppTheme.primary : const Color(0xFF2E7D32),
                                        size: 28,
                                      );
                                    },
                                  )
                                : Icon(
                                    isOccupied ? Icons.person_outline : Icons.door_front_door_outlined,
                                    color: isOccupied ? AppTheme.primary : const Color(0xFF2E7D32),
                                    size: 28,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      unitNumber,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOccupied 
                                          ? AppTheme.primary.withOpacity(0.08) 
                                          : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isOccupied ? 'OCCUPIED' : 'VACANT',
                                        style: TextStyle(
                                          color: isOccupied ? AppTheme.primary : const Color(0xFF2E7D32),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$rent / month',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isOccupied) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    unit['tenant']?['full_name'] ?? 'Occupied',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.mail_outline, size: 12, color: Colors.black38),
                                      const SizedBox(width: 4),
                                      Text(unit['tenant']?['email'] ?? 'No email', style: const TextStyle(color: Colors.black38, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.surfaceContainerHigh),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: isOccupied 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: View Tenant Details
                                },
                                icon: const Icon(Icons.info_outline, size: 18),
                                label: const Text('View Tenant Details'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.onSurfaceVariant,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitation flow coming soon!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Invite Tenant'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
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
