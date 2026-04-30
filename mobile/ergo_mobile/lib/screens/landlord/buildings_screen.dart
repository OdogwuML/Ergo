import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'unit_list_screen.dart';
import 'add_building_screen.dart';

class BuildingsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const BuildingsScreen({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final buildings = data['active_buildings'] as List<dynamic>? ?? [];
    final totalUnits = data['total_units'] as int? ?? 0;
    final occupiedUnits = data['occupied_units'] as int? ?? 0;
    final vacantUnits = totalUnits - occupiedUnits;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buildings & Units',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your residential properties',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Portfolio Occupancy Stats
          Text(
            'Property Occupancy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OccupancySummaryCard(
                  label: 'Active Leases',
                  count: occupiedUnits,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OccupancySummaryCard(
                  label: 'Vacant',
                  count: vacantUnits,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Maintenance Alert (Summary)
          _MaintenanceSummary(data: data),
          const SizedBox(height: 32),

          // Buildings List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Properties',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${buildings.length} total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (buildings.isEmpty)
            _EmptyBuildingsState(onAdd: () => _navigateToAddBuilding(context))
          else
            ...buildings.map((b) => _BuildingCard(
                  building: b as Map<String, dynamic>,
                  onTap: () => _navigateToUnits(context, b),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _navigateToUnits(BuildContext context, Map<String, dynamic> building) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitListScreen(building: building),
      ),
    ).then((_) => onRefresh());
  }

  void _navigateToAddBuilding(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBuildingScreen(),
      ),
    ).then((_) => onRefresh());
  }
}

class _OccupancySummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _OccupancySummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSummary extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MaintenanceSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    // For now, we'll use generic text or pull if available in future
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.build_circle_outlined, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Review pending requests across your portfolio.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final Map<String, dynamic> building;
  final VoidCallback onTap;

  const _BuildingCard({required this.building, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: building['photo_url'] != null && building['photo_url'].toString().isNotEmpty
                    ? Image.network(
                        building['photo_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.domain, color: AppTheme.primary),
                      )
                    : const Icon(Icons.domain, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building['name'] ?? 'Unnamed building',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      building['address'] ?? 'No address provided',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBuildingsState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBuildingsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.domain_disabled, size: 64, color: AppTheme.surfaceContainerHigh),
          const SizedBox(height: 16),
          const Text('No buildings found', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add your first property to start managing units.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Property'),
          ),
        ],
      ),
    );
  }
}
