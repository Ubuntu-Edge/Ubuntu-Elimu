/// Supply Management API Service
/// Handles medical supply inventory and requests
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'dart:ui' show Color;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Supply Item Model
class SupplyItem {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final String unit;
  final DateTime? lastRestocked;
  final DateTime? expiryDate;
  final String? chwId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplyItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.unit,
    this.lastRestocked,
    this.expiryDate,
    this.chwId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplyItem.fromJson(Map<String, dynamic> json) {
    return SupplyItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      currentStock: json['current_stock'] ?? 0,
      minStock: json['min_stock'] ?? 0,
      maxStock: json['max_stock'] ?? 100,
      unit: json['unit'] ?? 'units',
      lastRestocked: json['last_restocked'] != null
          ? DateTime.tryParse(json['last_restocked'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'])
          : null,
      chwId: json['chw_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isLowStock => currentStock <= minStock;
  bool get isOutOfStock => currentStock == 0;
  bool get isExpiringSoon =>
      expiryDate != null && expiryDate!.difference(DateTime.now()).inDays <= 30;
  double get stockPercentage =>
      maxStock > 0 ? (currentStock / maxStock).clamp(0.0, 1.0) : 0.0;

  /// Returns color based on stock level for UI display
  Color get stockColor {
    if (isOutOfStock) return const Color(0xFFE53935); // Red
    if (isLowStock) return const Color(0xFFFF9800); // Orange
    return const Color(0xFF4CAF50); // Green
  }
}

/// Supply Request Model
class SupplyRequest {
  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final String status; // pending, approved, delivered, rejected
  final String? notes;
  final String chwId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? deliveredAt;
  final DateTime requestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplyRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.status,
    this.notes,
    required this.chwId,
    this.approvedBy,
    this.approvedAt,
    this.deliveredAt,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplyRequest.fromJson(Map<String, dynamic> json) {
    return SupplyRequest(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? json['supply_item']?['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      chwId: json['chw_id'] ?? '',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      requestedAt:
          DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Supply Category Model
class SupplyCategory {
  final String id;
  final String name;
  final String? description;
  final int itemCount;

  SupplyCategory({
    required this.id,
    required this.name,
    this.description,
    required this.itemCount,
  });

  factory SupplyCategory.fromJson(Map<String, dynamic> json) {
    return SupplyCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      itemCount: json['item_count'] ?? 0,
    );
  }
}

/// Supply List Response
class SupplyListResponse {
  final bool success;
  final List<SupplyItem> data;
  final int totalCount;
  final int page;
  final int perPage;

  SupplyListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory SupplyListResponse.fromJson(Map<String, dynamic> json) {
    return SupplyListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SupplyItem.fromJson(item))
              .toList() ??
          [],
      totalCount: json['pagination']?['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? 20,
    );
  }
}

/// Supply Request List Response
class SupplyRequestListResponse {
  final bool success;
  final List<SupplyRequest> data;
  final int totalCount;
  final int page;
  final int perPage;

  SupplyRequestListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory SupplyRequestListResponse.fromJson(Map<String, dynamic> json) {
    return SupplyRequestListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SupplyRequest.fromJson(item))
              .toList() ??
          [],
      totalCount: json['pagination']?['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? 20,
    );
  }
}

/// Supply API Exception
class SupplyApiException implements Exception {
  final String message;
  final int? statusCode;

  SupplyApiException(this.message, {this.statusCode});

  @override
  String toString() => 'SupplyApiException: $message';
}

/// Supply API Service
class SupplyApiService {
  static final SupplyApiService instance = SupplyApiService._internal();
  SupplyApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ============ INVENTORY ============

  /// Get inventory list
  /// GET /supplies/inventory
  Future<SupplyListResponse> getInventory({
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }

      final uri = Uri.parse('$_baseUrl/supplies/inventory')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupplyListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to get inventory: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error getting inventory: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Add inventory item
  /// POST /supplies/inventory
  Future<SupplyItem> addInventoryItem({
    required String name,
    required String category,
    required int currentStock,
    required int minStock,
    required int maxStock,
    required String unit,
    DateTime? expiryDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'name': name,
        'category': category,
        'current_stock': currentStock,
        'min_stock': minStock,
        'max_stock': maxStock,
        'unit': unit,
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/supplies/inventory'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SupplyItem.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to add inventory item: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error adding inventory item: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Update inventory item
  /// PATCH /supplies/inventory/{item_id}
  Future<SupplyItem> updateInventoryItem(
    String itemId, {
    int? currentStock,
    int? minStock,
    int? maxStock,
    DateTime? expiryDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{};
      if (currentStock != null) body['current_stock'] = currentStock;
      if (minStock != null) body['min_stock'] = minStock;
      if (maxStock != null) body['max_stock'] = maxStock;
      if (expiryDate != null)
        body['expiry_date'] = expiryDate.toIso8601String();

      final response = await http.patch(
        Uri.parse('$_baseUrl/supplies/inventory/$itemId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupplyItem.fromJson(data);
      } else if (response.statusCode == 404) {
        throw SupplyApiException('Item not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to update inventory item: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error updating inventory item: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Delete inventory item
  /// DELETE /supplies/inventory/{item_id}
  Future<bool> deleteInventoryItem(String itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/supplies/inventory/$itemId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw SupplyApiException('Item not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to delete inventory item: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error deleting inventory item: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Get low stock items
  /// GET /supplies/low-stock
  Future<List<SupplyItem>> getLowStockItems() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/supplies/low-stock'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => SupplyItem.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to get low stock items: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error getting low stock items: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  // ============ REQUESTS ============

  /// Get supply requests
  /// GET /supplies/requests
  Future<SupplyRequestListResponse> getRequests({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse('$_baseUrl/supplies/requests')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupplyRequestListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to get requests: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error getting requests: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Create supply request
  /// POST /supplies/requests
  Future<SupplyRequest> createRequest({
    required String itemId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'item_id': itemId,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/supplies/requests'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SupplyRequest.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to create request: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error creating request: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Update request status (admin/supervisor only)
  /// PATCH /supplies/requests/{request_id}/status
  Future<SupplyRequest> updateRequestStatus(
      String requestId, String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/supplies/requests/$requestId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupplyRequest.fromJson(data);
      } else if (response.statusCode == 404) {
        throw SupplyApiException('Request not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to update request status: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error updating request status: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  // ============ CATEGORIES ============

  /// Get supply categories
  /// GET /supplies/categories
  Future<List<SupplyCategory>> getCategories() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/supplies/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => SupplyCategory.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw SupplyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SupplyApiException(
          'Failed to get categories: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SupplyApiException) rethrow;
      debugPrint('Error getting categories: $e');
      throw SupplyApiException('Network error: $e');
    }
  }

  /// Get supply statistics
  Future<Map<String, int>> getSupplyStats() async {
    try {
      final inventory = await getInventory(perPage: 100);
      final requests = await getRequests(status: 'pending', perPage: 1);

      final lowStock = inventory.data.where((s) => s.isLowStock).length;
      final outOfStock = inventory.data.where((s) => s.isOutOfStock).length;
      final expiringSoon = inventory.data.where((s) => s.isExpiringSoon).length;

      return {
        'total': inventory.totalCount,
        'lowStock': lowStock,
        'outOfStock': outOfStock,
        'expiringSoon': expiringSoon,
        'pendingRequests': requests.totalCount,
      };
    } catch (e) {
      debugPrint('Error getting supply stats: $e');
      return {
        'total': 0,
        'lowStock': 0,
        'outOfStock': 0,
        'expiringSoon': 0,
        'pendingRequests': 0,
      };
    }
  }
}
