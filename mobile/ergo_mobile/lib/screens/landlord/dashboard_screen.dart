import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_theme.dart';
import '../../services/dashboard_service.dart';

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
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.surfaceContainerHigh,
            child: Icon(Icons.person, color: AppTheme.onSurfaceVariant, size: 20),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Ergo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.onSurfaceVariant),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            final errorMsg = snapshot.hasError ? snapshot.error.toString() : 'Dashboard data is missing';
            
            // Auto-redirect on session expiry
            if (errorMsg.contains('Session expired') || errorMsg.contains('Not authenticated')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/login');
                }
              });
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text(errorMsg, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _refreshData, child: const Text('Retry', style: TextStyle(color: AppTheme.primary))),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('auth_token');
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }, 
                      child: const Text('Clear Session & Log In')
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final buildings = data['active_buildings'] as List<dynamic>? ?? [];
          final recentPayments = data['recent_payments'] as List<dynamic>? ?? [];
          final landlordName = (data['landlord_name'] as String? ?? 'User').split(' ').first;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome greeting from Supabase
                Text(
                  'Welcome, $landlordName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Alert Banner — status pillar style with CTA
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 4, color: AppTheme.primary),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Finish your setup to start collecting rent',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Verification is needed to enable automated payouts and lease tracking.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Link Bank Account',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stat: Monthly Rent Revenue — gradient card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Rent Revenue',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₦${_formatAmount(data['total_collected'])}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row: Total Buildings + Occupied Units — horizontal
                Row(
                  children: [
                    Expanded(
                      child: _StatCardVertical(
                        title: 'Total Buildings',
                        value: '${data['total_buildings']}',
                        trend: '+0%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _OccupancyCard(
                        occupied: data['occupied_units'] ?? 0,
                        total: data['total_units'] ?? 0,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Pending & Recent Payments
                Text(
                  'Pending Payments', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 16),
                if (recentPayments.isEmpty)
                  const _EmptyState(title: 'No pending payments', subtitle: 'All units are up to date on rent.'),
                if (recentPayments.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentPayments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = recentPayments[index];
                      return _PaymentItem(
                        tenant: p['users']?['full_name'] ?? 'Unknown Tenant',
                        property: p['buildings']?['name'] ?? 'Unknown Property',
                        amount: '₦${(p['amount'] / 100).toStringAsFixed(0)}',
                        status: p['status'],
                        statusColor: p['status'] == 'successful' ? AppTheme.primary : Colors.orange,
                      );
                    },
                  ),
                const SizedBox(height: 32),

                // Recent Activity — dynamic from backend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _FilterChip(label: 'All', isSelected: true),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Payments', isSelected: false),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._buildActivityItems(context, data['recent_activity'] as List<dynamic>? ?? []),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceContainerLowest,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.maps_home_work_outlined), activeIcon: Icon(Icons.maps_home_work), label: 'Buildings'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        highlightElevation: 8,
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          // TODO: Navigate to add building or quick action
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildActivityItems(BuildContext context, List<dynamic> activities) {
    if (activities.isEmpty) {
      return [
        const _EmptyState(title: 'No recent activity', subtitle: 'Your activity feed will appear here.'),
      ];
    }

    final widgets = <Widget>[];
    for (int i = 0; i < activities.length; i++) {
      final a = activities[i] as Map<String, dynamic>;
      final type = a['type'] as String? ?? '';
      final title = a['title'] as String? ?? '';
      final subtitle = a['subtitle'] as String? ?? '';
      final amount = a['amount'];

      IconData icon;
      Color iconColor;
      String? trailing;

      switch (type) {
        case 'payment':
          icon = Icons.payment_outlined;
          iconColor = AppTheme.primary;
          if (amount != null && amount is int) {
            trailing = '₦${_formatAmount(amount)}';
          }
          break;
        case 'maintenance':
          final status = a['status'] as String? ?? '';
          icon = status == 'resolved' ? Icons.check_circle_outline : Icons.build_outlined;
          iconColor = status == 'resolved' ? Colors.green : Colors.orange;
          break;
        case 'invitation':
          final status = a['status'] as String? ?? '';
          icon = status == 'accepted' ? Icons.description_outlined : Icons.mail_outline;
          iconColor = status == 'accepted' ? AppTheme.primary : AppTheme.onSurfaceVariant;
          break;
        default:
          icon = Icons.info_outline;
          iconColor = AppTheme.onSurfaceVariant;
      }

      if (i > 0) widgets.add(const SizedBox(height: 12));
      widgets.add(_ActivityItem(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ));
    }
    return widgets;
  }
}

String _formatAmount(dynamic amountInKobo) {
  final amount = (amountInKobo is int ? amountInKobo : 0) / 100;
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)},${(amount % 1000).toStringAsFixed(0).padLeft(3, '0')}';
  }
  return amount.toStringAsFixed(0);
}

class _StatCardVertical extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final Color? trendColor;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const _StatCardVertical({
    required this.title,
    required this.value,
    this.trend,
    this.trendColor,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 20),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: trendColor ?? Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  final int occupied;
  final int total;

  const _OccupancyCard({required this.occupied, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? occupied / total : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Occupied Units',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
              children: [
                TextSpan(text: '$occupied'),
                TextSpan(
                  text: ' / $total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow, 
              borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.corporate_fare_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(occupancy, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
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
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: statusColor), // Status Pillar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.surfaceContainerLow,
                      child: Text(tenant[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenant, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('$property • ${status.toUpperCase()}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Text(amount, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_mosaic_outlined, size: 32, color: AppTheme.outlineVariant),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailing;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppTheme.outlineVariant, size: 20),
        ],
      ),
    );
  }
}
