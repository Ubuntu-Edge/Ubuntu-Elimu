import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supply_api_service.dart';

class SupplyManagementScreen extends StatefulWidget {
  const SupplyManagementScreen({super.key});

  @override
  State<SupplyManagementScreen> createState() => _SupplyManagementScreenState();
}

class _SupplyManagementScreenState extends State<SupplyManagementScreen> 
    with SingleTickerProviderStateMixin {
  final SupplyApiService _supplyApi = SupplyApiService.instance;
  late TabController _tabController;
  List<SupplyItem> _supplies = [];
  List<SupplyRequest> _requests = [];
  List<SupplyCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Load inventory, requests, and categories in parallel
      final results = await Future.wait([
        _supplyApi.getInventory(perPage: 100),
        _supplyApi.getRequests(perPage: 100),
        _supplyApi.getCategories(),
      ]);
      
      final inventoryResponse = results[0] as SupplyListResponse;
      final requestsResponse = results[1] as SupplyRequestListResponse;
      final categories = results[2] as List<SupplyCategory>;
      
      // Add "All" category at the beginning
      final allCategories = [
        SupplyCategory(id: 'all', name: 'All', itemCount: inventoryResponse.data.length),
        ...categories,
      ];
      
      setState(() {
        _supplies = inventoryResponse.data;
        _requests = requestsResponse.data;
        _categories = allCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Provide fallback categories
        _categories = [
          SupplyCategory(id: 'all', name: 'All', itemCount: 0),
          SupplyCategory(id: '1', name: 'Medications', itemCount: 0),
          SupplyCategory(id: '2', name: 'Test Kits', itemCount: 0),
          SupplyCategory(id: '3', name: 'First Aid', itemCount: 0),
          SupplyCategory(id: '4', name: 'Equipment', itemCount: 0),
          SupplyCategory(id: '5', name: 'PPE', itemCount: 0),
        ];
      });
      debugPrint('Error loading supply data: $e');
    }
  }

  List<SupplyItem> get _filteredSupplies {
    if (_selectedCategory == 'All') return _supplies;
    return _supplies.where((s) => s.category == _selectedCategory).toList();
  }

  int get _lowStockCount => _supplies.where((s) => s.isLowStock).length;
  int get _outOfStockCount => _supplies.where((s) => s.currentStock == 0).length;
  int get _pendingRequestsCount => _requests.where((r) => r.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInventoryTab(),
                            _buildRequestsTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestSupplyDialog,
        backgroundColor: AppColors.primary,
        icon: FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 18),
        label: Text(l10n.translate('requestSupply') ?? 'Request Supply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
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
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
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
                        l10n.supplies,
                        style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.translate('trackAndRequestSupplies') ?? 'Track and request supplies',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                _buildStatChip(l10n.translate('lowStock') ?? 'Low Stock', '$_lowStockCount', AppColors.warning),
                SizedBox(width: AppTheme.spacingSm),
                _buildStatChip(l10n.translate('outOfStock') ?? 'Out of Stock', '$_outOfStockCount', AppColors.error),
                SizedBox(width: AppTheme.spacingSm),
                _buildStatChip(l10n.translate('pending') ?? 'Pending', '$_pendingRequestsCount', AppColors.info),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: l10n.translate('inventory') ?? 'Inventory'),
                Tab(text: l10n.translate('requests') ?? 'Requests'),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.headingSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(label, style: AppTheme.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation, color: AppColors.error, size: 48),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.translate('errorLoadingData') ?? 'Error Loading Data',
              style: AppTheme.headingMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
              label: Text(l10n.translate('retry') ?? 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 40,
          margin: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category.name == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category.name),
                child: Container(
                  margin: EdgeInsets.only(right: AppTheme.spacingSm),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category.name,
                    style: AppTheme.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Supply List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              itemCount: _filteredSupplies.length,
              itemBuilder: (context, index) {
                return _buildSupplyCard(_filteredSupplies[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyCard(SupplyItem supply) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: supply.isLowStock ? Border.all(color: supply.stockColor.withValues(alpha: 0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: supply.stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  _getCategoryIcon(supply.category),
                  color: supply.stockColor,
                  size: 18,
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supply.name, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text(supply.category, style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${supply.currentStock}',
                    style: AppTheme.headingSmall.copyWith(
                      color: supply.stockColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(supply.unit, style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          // Stock Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: supply.stockPercentage,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(supply.stockColor),
              minHeight: 6,
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (supply.isLowStock)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: supply.stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.triangleExclamation, color: supply.stockColor, size: 10),
                      SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            supply.currentStock == 0 
                              ? (l10n.translate('outOfStock') ?? 'Out of Stock')
                              : (l10n.translate('lowStock') ?? 'Low Stock'),
                            style: AppTheme.labelSmall.copyWith(color: supply.stockColor, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (supply.isExpiringSoon)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.clock, color: AppColors.warning, size: 10),
                      SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n.translate('expiringSoon') ?? 'Expiring Soon',
                            style: AppTheme.labelSmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              Spacer(),
              GestureDetector(
                onTap: () => _showRequestSupplyDialog(preselectedItem: supply),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n.translate('request') ?? 'Request',
                        style: AppTheme.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    final l10n = AppLocalizations.of(context);
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.boxOpen, color: AppColors.textLight, size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(l10n.translate('noSupplyRequests') ?? 'No supply requests', style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(_requests[index]);
      },
    );
  }

  Widget _buildRequestCard(SupplyRequest request) {
    Color statusColor;
    IconData statusIcon;
    switch (request.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = FontAwesomeIcons.circleCheck;
        break;
      case 'delivered':
        statusColor = AppColors.info;
        statusIcon = FontAwesomeIcons.truck;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = FontAwesomeIcons.clock;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(statusIcon, color: statusColor, size: 18),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.itemName, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('Qty: ${request.quantity}', style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
                if (request.notes != null)
                  Text(request.notes!, style: AppTheme.labelSmall.copyWith(color: AppColors.textLight, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.status.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Medications':
        return FontAwesomeIcons.pills;
      case 'Test Kits':
        return FontAwesomeIcons.vial;
      case 'First Aid':
        return FontAwesomeIcons.kitMedical;
      case 'Equipment':
        return FontAwesomeIcons.stethoscope;
      case 'PPE':
        return FontAwesomeIcons.shieldHalved;
      default:
        return FontAwesomeIcons.box;
    }
  }

  void _showRequestSupplyDialog({SupplyItem? preselectedItem}) {
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    SupplyItem? selectedItem = preselectedItem;
    String? manualItemName;
    bool useManualEntry = _supplies.isEmpty;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Request Supply', style: AppTheme.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Item', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                if (_supplies.isNotEmpty && !useManualEntry)
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SupplyItem>(
                            value: selectedItem,
                            isExpanded: true,
                            hint: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Select a supply item'),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            borderRadius: BorderRadius.circular(12),
                            items: _supplies.map((s) => DropdownMenuItem<SupplyItem>(
                              value: s,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (value) => setDialogState(() => selectedItem = value),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setDialogState(() => useManualEntry = true),
                        child: Text('Item not in list? Enter manually'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextField(
                        onChanged: (value) => manualItemName = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Enter item name',
                          labelText: 'Item Name',
                        ),
                      ),
                      if (_supplies.isNotEmpty)
                        TextButton(
                          onPressed: () => setDialogState(() => useManualEntry = false),
                          child: Text('Select from list instead'),
                        ),
                    ],
                  ),
                SizedBox(height: AppTheme.spacingMd),
                Text('Quantity', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Enter quantity',
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text('Notes (Optional)', style: AppTheme.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Add any notes...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final hasValidItem = useManualEntry 
                    ? (manualItemName != null && manualItemName!.isNotEmpty)
                    : (selectedItem != null);
                
                if (hasValidItem && quantityController.text.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    if (useManualEntry) {
                      // For manual entry, create a local request record
                      setState(() {
                        _requests.insert(0, SupplyRequest(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          itemId: 'manual',
                          itemName: manualItemName!,
                          quantity: int.parse(quantityController.text),
                          status: 'pending',
                          notes: notesController.text.isEmpty ? 'Manual request - awaiting supervisor' : notesController.text,
                          chwId: '',
                          requestedAt: DateTime.now(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ));
                      });
                    } else {
                      final request = await _supplyApi.createRequest(
                        itemId: selectedItem!.id,
                        quantity: int.parse(quantityController.text),
                        notes: notesController.text.isEmpty ? null : notesController.text,
                      );
                      setState(() {
                        _requests.insert(0, request);
                      });
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Supply request submitted'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit request: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select an item and enter quantity'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Submit Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
