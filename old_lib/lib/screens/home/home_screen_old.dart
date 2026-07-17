import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../patients/patient_list_screen.dart';
import '../patients/patient_registration_screen.dart';
import '../auth/login_screen.dart';
// ADDED IMPORT for the follow-up screen
import '../../followups/followup_dashboard_screen.dart';
import '../library/library_home_screen.dart'; // Import for Medical Library
import '../referrals/referrals_dashboard_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Delay _loadData until after first frame for safe context access
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final patientProvider = context.read<PatientProvider>();

    if (authProvider.currentCHW != null) {
      // Assuming you will need to load reminder/followup stats here too
      // context.read<FollowupProvider>().loadStatistics(authProvider.currentCHW!.id);
      await patientProvider.loadPatients(authProvider.currentCHW!.id);
    }
  }

  Future<void> _handleLogout() async {
    // Use mounted-safe context after async calls
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are! you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      await context.read<AuthProvider>().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final chw = authProvider.currentCHW;

    if (chw == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = patientProvider.statistics;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UbuntuHealth', style: TextStyle(fontSize: 20)),
            Text(
              'Welcome, ${chw.firstName}!',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(chw.fullName, chw.village),
            const SizedBox(height: 20),

            // --- Stats Section ---
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Patients',
                    '${stats['totalPatients'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Visits',
                    '${stats['totalVisits'] ?? 0}',
                    Icons.medical_services,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'High Risk',
                    '${stats['highRiskPatients'] ?? 0}',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Follow-ups Due',
                    '${stats['pendingFollowUps'] ?? 0}',
                    Icons.schedule,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Quick Actions ---
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Register New Patient',
              'Add a new patient to your registry',
              Icons.person_add,
              Colors.blue,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'View All Patients',
              'Browse and search your patient list',
              Icons.list,
              Colors.green,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientListScreen()),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'High Risk Patients',
              'View patients requiring special attention',
              Icons.priority_high,
              Colors.orange,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientListScreen(showHighRiskOnly: true),
                  ),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Pending Follow-ups',
              'Patients due for follow-up visits',
              Icons.calendar_today,
              Colors.red,
              // FIX: Navigate to the actual dashboard
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FollowupDashboardScreen()),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 12),
            // Medical Library Action Card
            _buildActionCard(
              'Medical Library',
              'Browse diseases, drugs, and calculators',
              Icons.local_hospital,
              Colors.purple,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LibraryHomeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Referrals',
              'Track patient referrals and outcomes',
              Icons.local_shipping,
              Colors.teal,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralsDashboardScreen()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Patient'),
      ),
    );
  }

  Widget _buildWelcomeCard(String name, String? village) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            // FIX: Use .withAlpha instead of .withOpacity on Color in BoxDecoration/LinearGradient for precision
            Theme.of(context).primaryColor.withAlpha((255 * 0.7).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good to see you!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (village != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  village,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // FIX: Use .withAlpha instead of .withOpacity on Color
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        // FIX: Use .withAlpha instead of .withOpacity on Color
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // FIX: Use .withAlpha instead of .withOpacity on Color
                  color: color.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}