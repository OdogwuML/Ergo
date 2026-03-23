import 'package:flutter/material.dart';
import '../../app_theme.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  int _selectedIndex = 0;

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
      body: SingleChildScrollView(
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
              children: const [
                _StatCard(title: 'Total Buildings', value: '12', trend: '+2%'),
                _StatCard(title: 'Total Units', value: '48', trend: '+5%'),
                _StatCard(title: 'Total Tenants', value: '42', trend: 'Stable', trendColor: AppTheme.primary),
                _StatCard(title: 'Rent Collected', value: '₦4.2M', trend: '↑12%'),
              ],
            ),
            const SizedBox(height: 12),
            const _StatCard(title: 'Total Outstanding', value: '₦850k', trend: '↓3%', valueColor: Colors.redAccent, trendColor: Colors.redAccent, isFullWidth: true),
            
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
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _PropertyItem(name: 'Eko Atlantic Towers', location: 'Victoria Island, Lagos', occupancy: '95%'),
                  Divider(height: 1),
                  _PropertyItem(name: 'Lekki Gardens Phase 3', location: 'Lekki, Lagos', occupancy: '88%'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Recent Payments
            const Text('Recent Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _PaymentItem(tenant: 'Chidi Okafor', property: 'Eko Towers', amount: '₦450,000', status: 'Success', statusColor: Colors.green),
                  Divider(height: 1),
                  _PaymentItem(tenant: 'Oluwaseun Ade', property: 'Maitama Villa', amount: '₦850,000', status: 'Pending', statusColor: Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
        onPressed: () {},
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
