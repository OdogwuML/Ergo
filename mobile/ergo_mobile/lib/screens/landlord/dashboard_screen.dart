import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/dashboard_service.dart';
import 'add_building_screen.dart';
import 'unit_list_screen.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  int _selectedIndex = 0;
  final _dashboardService = DashboardService();
  late Future<Map<String, dynamic>?> _dashboardData;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _dashboardData = _dashboardService.getLandlordDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ergo Portal',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text('TB', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Error loading dashboard'),
                  TextButton(onPressed: _refreshData, child: const Text('Retry')),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final buildings = data['active_buildings'] as List<dynamic>? ?? [];
          final recentPayments = data['recent_payments'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back, Chief', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                const Text('Overview of your property portfolio performance today.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(title: 'Total Buildings', value: '${data['total_buildings']}', trend: '+0%'),
                    _StatCard(title: 'Total Units', value: '${data['total_units']}', trend: '+0%'),
                    _StatCard(title: 'Occupied Units', value: '${data['occupied_units']}', trend: 'Stable', trendColor: AppTheme.primary),
                    _StatCard(title: 'Rent Collected', value: '₦${(data['total_collected'] / 100).toStringAsFixed(0)}', trend: '↑0%'),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(title: 'Total Pending', value: '₦${(data['total_pending'] / 100).toStringAsFixed(0)}', trend: '↓0%', valueColor: Colors.redAccent, trendColor: Colors.redAccent, isFullWidth: true),
                
                const SizedBox(height: 32),
                
                // Active Properties
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: (){}, child: const Text('View All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                if (buildings.isEmpty)
                  _EmptyState(title: 'No properties added yet', subtitle: 'Tap the + button to add your first building.'),
                if (buildings.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: buildings.length > 3 ? 3 : buildings.length,
                      itemBuilder: (context, index) {
                        final b = buildings[index];
                        return Column(
                          children: [
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UnitListScreen(building: b),
                                  ),
                                );
                                if (result == true) {
                                  _refreshData();
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: _PropertyItem(
                                name: b['name'], 
                                location: b['address'], 
                                occupancy: '${b['total_units']} units'
                              ),
                            ),
                            if (index < (buildings.length > 3 ? 2 : buildings.length - 1)) const Divider(height: 1),
                          ],
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Recent Payments
                const Text('Recent Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (recentPayments.isEmpty)
                  const _EmptyState(title: 'No recent payments', subtitle: 'Payments will appear here once tenants start paying.'),
                if (recentPayments.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentPayments.length,
                      itemBuilder: (context, index) {
                        final p = recentPayments[index];
                        return Column(
                          children: [
                            _PaymentItem(
                              tenant: p['users']?['full_name'] ?? 'Unknown Tenant',
                              property: p['buildings']?['name'] ?? 'Unknown Property',
                              amount: '₦${(p['amount'] / 100).toStringAsFixed(0)}',
                              status: p['status'],
                              statusColor: p['status'] == 'successful' ? Colors.green : Colors.orange,
                            ),
                            if (index < recentPayments.length - 1) const Divider(height: 1),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.black54,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Tenants'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Payments'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBuildingScreen()),
          );
          if (result == true) {
            _refreshData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final Color valueColor;
  final Color trendColor;
  final bool isFullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    this.valueColor = Colors.black87,
    this.trendColor = Colors.green,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(isFullWidth ? 20 : 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(trend, style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _PropertyItem extends StatelessWidget {
  final String name;
  final String location;
  final String occupancy;

  const _PropertyItem({required this.name, required this.location, required this.occupancy});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.apartment, color: Colors.black54),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(location, style: const TextStyle(fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(occupancy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Text('OCC.', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String tenant;
  final String property;
  final String amount;
  final String status;
  final Color statusColor;

  const _PaymentItem({required this.tenant, required this.property, required this.amount, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.black12,
        child: Text(tenant[0], style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tenant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(property, style: const TextStyle(fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.black12)
      ),
      child: Column(
        children: [
          const Icon(Icons.apartment_outlined, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}
