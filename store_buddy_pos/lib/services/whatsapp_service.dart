import 'package:dio/dio.dart';
import 'api_client.dart';

class WhatsAppService {
  final ApiClient _apiClient;

  WhatsAppService(this._apiClient);

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _apiClient.get('/whatsapp/status');
      final map = _safeMap(response.data);
      if (map.isNotEmpty) {
        return map;
      }
      return {'success': false, 'status': 'DISCONNECTED'};
    } on DioException catch (e) {
      final errMap = _safeMap(e.response?.data);
      return {
        'success': false,
        'status': 'DISCONNECTED',
        'message': errMap['message'] ?? errMap['detail'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'status': 'DISCONNECTED', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> connect() async {
    try {
      final response = await _apiClient.post('/whatsapp/connect');
      final map = _safeMap(response.data);
      if (map.isNotEmpty) {
        return map;
      }
      return {'success': false, 'message': 'Unknown response'};
    } on DioException catch (e) {
      final errMap = _safeMap(e.response?.data);
      return {
        'success': false,
        'message': errMap['message'] ?? errMap['detail'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> disconnect() async {
    try {
      final response = await _apiClient.post('/whatsapp/disconnect');
      final map = _safeMap(response.data);
      if (map.isNotEmpty) {
        return map;
      }
      return {'success': false, 'message': 'Unknown response'};
    } on DioException catch (e) {
      final errMap = _safeMap(e.response?.data);
      return {
        'success': false,
        'message': errMap['message'] ?? errMap['detail'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendDeliveryNote({
    required String customerPhone,
    required String customerName,
    required String invoiceNumber,
    String? deliveryOtp,
    required double totalAmount,
    String? shippingAddress,
    String? assignedDriverName,
    String? storeName,
  }) async {
    try {
      final response = await _apiClient.post(
        '/whatsapp/send-delivery-note',
        data: {
          'customerPhone': customerPhone,
          'customerName': customerName,
          'invoiceNumber': invoiceNumber,
          'deliveryOtp': deliveryOtp,
          'totalAmount': totalAmount,
          'shippingAddress': shippingAddress,
          'assignedDriverName': assignedDriverName,
          'storeName': storeName,
        },
      );
      final map = _safeMap(response.data);
      if (map.isNotEmpty) {
        return map;
      }
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
