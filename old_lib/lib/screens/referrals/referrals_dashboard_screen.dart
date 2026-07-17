import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/referral_provider.dart';
import 'referral_details_screen.dart';

class ReferralsDashboardScreen extends StatefulWidget {
  const ReferralsDashboardScreen({super.key});

  @override
  State<ReferralsDashboardScreen> createState() => _ReferralsDashboardScreenState();
}

class _ReferralsDashboardScreenState extends State<ReferralsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chwId = context.read<AuthProvider>().currentCHW?.id;
      if (chwId != null) {
        context.read<ReferralProvider>().fetchReferrals(chwId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Referrals'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final chwId = context.read<AuthProvider>().currentCHW?.id;
              if (chwId != null) {
                context.read<ReferralProvider>().fetchReferrals(chwId);
              }
            },
            tooltip: 'Refresh',
          ),
          // Overview button showing total count
          Consumer<ReferralProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: InkWell(
                    onTap: () => _showOverviewDialog(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Overview (${provider.referrals.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ReferralProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.referrals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No referrals found',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CHW ID: ${context.read<AuthProvider>().currentCHW?.id ?? "Not set"}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Referrals you create will appear here',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final chwId = context.read<AuthProvider>().currentCHW?.id;
                        if (chwId != null) {
                          context.read<ReferralProvider>().fetchReferrals(chwId);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate statistics
          final totalReferrals = provider.referrals.length;
          final pendingReferrals = provider.referrals.where((r) => r.outcome == null || r.outcome == 'Pending').length;
          final completedReferrals = provider.referrals.where((r) => r.outcome != null && r.outcome != 'Pending').length;

          return Column(
            children: [
              // Statistics bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Total', totalReferrals, Colors.blue),
                    _buildStatCard('Pending', pendingReferrals, Colors.orange),
                    _buildStatCard('Completed', completedReferrals, Colors.green),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.referrals.length,
                  itemBuilder: (context, index) {
                    final referral = provider.referrals[index];
                    final isPending = referral.outcome == null || referral.outcome == 'Pending';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPending ? Colors.orange : Colors.green,
                          child: Icon(
                            isPending ? Icons.pending_actions : Icons.check_circle,
                            color: Colors.white,
                          ),
                        ),
                        title: Text('Referred to: ${referral.referredTo}'),
                        subtitle: Text('Reason: ${referral.referralReason}'),
                        trailing: Text(
                          referral.outcome ?? 'Pending',
                          style: TextStyle(
                            color: isPending ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReferralDetailsScreen(referral: referral),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showOverviewDialog(BuildContext context, ReferralProvider provider) {
    final totalReferrals = provider.referrals.length;
    final pendingReferrals = provider.referrals.where((r) => r.outcome == null || r.outcome == 'Pending').length;
    final completedReferrals = provider.referrals.where((r) => r.outcome != null && r.outcome != 'Pending').length;
    
    // Group by facility
    final Map<String, int> facilityCounts = {};
    for (final referral in provider.referrals) {
      facilityCounts[referral.referredTo] = (facilityCounts[referral.referredTo] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Referrals Overview'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary Statistics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildOverviewRow('Total Referrals', totalReferrals, Colors.blue),
              _buildOverviewRow('Pending', pendingReferrals, Colors.orange),
              _buildOverviewRow('Completed', completedReferrals, Colors.green),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Referrals by Facility',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...facilityCounts.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
