import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/patient_card.dart';
import '../../models/patient.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'patient_detail_screen.dart';
import 'patient_registration_screen.dart';

class PatientListScreen extends StatefulWidget {
  final bool showHighRiskOnly;

  const PatientListScreen({
    super.key,
    this.showHighRiskOnly = false,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _filteredPatients = [];
  bool _isSearching = false;
  int _selectedFilterIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadPatients() {
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    setState(() {
      _filteredPatients = widget.showHighRiskOnly
          ? patientProvider.highRiskPatients
          : patientProvider.patients;
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _loadPatients();
      });
      return;
    }

    setState(() => _isSearching = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);

    final results = await patientProvider.searchPatients(
      authProvider.currentCHW!.id,
      query,
    );

    setState(() {
      _filteredPatients = widget.showHighRiskOnly
          ? results
              .where(
                  (p) => p.isHighRisk || (p.isPregnant ?? false) || (p.hasChronicCondition ?? false))
              .toList()
          : results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(patientProvider),
            
            // Search Bar
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSearchBar(),
            ),

            // Filter Chips
            if (!widget.showHighRiskOnly)
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFilterSection(patientProvider),
              ),

            SizedBox(height: AppTheme.spacingSm),

            // Patient List
            Expanded(
              child: _isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(AppLocalizations.of(context).translate('searching') ?? 'Searching...', style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : _filteredPatients.isEmpty
                      ? _buildEmptyState(context)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            final authProvider =
                                Provider.of<AuthProvider>(context, listen: false);
                            await patientProvider.loadPatients(
                              authProvider.currentCHW!.id,
                            );
                            _loadPatients();
                          },
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                            itemCount: _filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = _filteredPatients[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: PatientCard(
                                  patient: patient,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PatientDetailScreen(
                                          patientId: patient.id,
                                        ),
                                      ),
                                    ).then((_) => _loadPatients());
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
          ).then((_) => _loadPatients());
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 16),
        label: Text(AppLocalizations.of(context).translate('addPatient') ?? 'Add Patient', style: AppTheme.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
  
  Widget _buildHeader(PatientProvider patientProvider) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.showHighRiskOnly ? (l10n.translate('highRiskPatients') ?? 'High Risk Patients') : (l10n.translate('myPatients') ?? 'My Patients'),
                      style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      l10n.patientsCount(_filteredPatients.length),
                      style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              if (widget.showHighRiskOnly)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(l10n.highRisk, style: AppTheme.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _handleSearch,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: l10n.translate('searchPlaceholder') ?? 'Search by name, village, or notes...',
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
            prefixIcon: Padding(
              padding: EdgeInsets.all(12),
              child: FaIcon(FontAwesomeIcons.magnifyingGlass, color: AppColors.primary, size: 18),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: FaIcon(FontAwesomeIcons.xmark, color: AppColors.textSecondary, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      _handleSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterSection(PatientProvider patientProvider) {
    final l10n = AppLocalizations.of(context);
    final filters = [
      {'label': l10n.translate('all') ?? 'All', 'count': patientProvider.patients.length, 'icon': FontAwesomeIcons.users, 'color': AppColors.primary},
      {'label': l10n.highRisk, 'count': patientProvider.highRiskPatients.length, 'icon': FontAwesomeIcons.triangleExclamation, 'color': AppColors.error},
      {'label': l10n.translate('pregnant') ?? 'Pregnant', 'count': patientProvider.patients.where((p) => p.isPregnant ?? false).length, 'icon': FontAwesomeIcons.personPregnant, 'color': AppColors.secondary},
      {'label': l10n.translate('chronic') ?? 'Chronic', 'count': patientProvider.patients.where((p) => p.hasChronicCondition ?? false).length, 'icon': FontAwesomeIcons.heartPulse, 'color': AppColors.warning},
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = _selectedFilterIndex == index;
          final color = filter['color'] as Color;
          
          return Padding(
            padding: EdgeInsets.only(right: AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                  switch (index) {
                    case 0:
                      _filteredPatients = patientProvider.patients;
                      break;
                    case 1:
                      _filteredPatients = patientProvider.highRiskPatients;
                      break;
                    case 2:
                      _filteredPatients = patientProvider.patients.where((p) => p.isPregnant ?? false).toList();
                      break;
                    case 3:
                      _filteredPatients = patientProvider.patients.where((p) => p.hasChronicCondition ?? false).toList();
                      break;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      filter['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 14,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${filter['label']} (${filter['count']})',
                      style: AppTheme.labelMedium.copyWith(
                        color: isSelected ? Colors.white : color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool isSearch = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (widget.showHighRiskOnly ? AppColors.warning : AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                widget.showHighRiskOnly 
                    ? FontAwesomeIcons.triangleExclamation 
                    : isSearch 
                        ? FontAwesomeIcons.magnifyingGlass
                        : FontAwesomeIcons.users,
                size: 48,
                color: widget.showHighRiskOnly ? AppColors.warning : AppColors.primary,
              ),
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              widget.showHighRiskOnly
                  ? (l10n.translate('noHighRiskPatients') ?? 'No high-risk patients')
                  : isSearch
                      ? (l10n.translate('noPatientsFound') ?? 'No patients found')
                      : (l10n.translate('noPatientsYet') ?? 'No patients yet'),
              style: AppTheme.headingSmall.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              widget.showHighRiskOnly
                  ? (l10n.translate('allPatientsDoingWell') ?? 'Great news! All your patients are doing well.')
                  : isSearch
                      ? (l10n.translate('tryDifferentSearch') ?? 'Try a different search term or adjust filters')
                      : (l10n.translate('registerFirstPatient') ?? 'Register your first patient to get started'),
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!widget.showHighRiskOnly && !isSearch) ...[
              SizedBox(height: AppTheme.spacingXl),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientRegistrationScreen(),
                    ),
                  ).then((_) => _loadPatients());
                },
                icon: FaIcon(FontAwesomeIcons.plus, size: 16),
                label: Text(l10n.registerPatient, style: AppTheme.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
