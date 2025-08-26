import '../../domain/entities/guardian.dart';
import '../../domain/entities/child.dart';
import '../../domain/repositories/guardian_repository.dart';
import '../datasources/remote/api_service.dart';
import '../datasources/local/database_helper.dart';
import '../models/guardian_model.dart';
import '../models/child_model.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class GuardianRepositoryImpl implements GuardianRepository {
  final ApiService _apiService;
  final DatabaseHelper _databaseHelper;

  GuardianRepositoryImpl({
    required ApiService apiService,
    required DatabaseHelper databaseHelper,
  })  : _apiService = apiService,
        _databaseHelper = databaseHelper;

  @override
  Future<Guardian?> getGuardianByQrCode(String qrCode) async {
    try {
      // Try API first
      final response = await _apiService.getGuardianByQrCode(qrCode);

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardianData = response.data['data']['guardian'];
        if (guardianData != null) {
          final guardianModel = GuardianModel.fromJson(guardianData);
          return guardianModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian by QR code: $e');
      return null;
    }
  }

  @override
  Future<Guardian?> getGuardianByRfidTag(String rfidTag) async {
    try {
      // Try API first
      final response = await _apiService.getGuardianByRfidTag(rfidTag);

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardianData = response.data['data']['guardian'];
        if (guardianData != null) {
          final guardianModel = GuardianModel.fromJson(guardianData);
          return guardianModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian by RFID tag: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getGuardianWithChildren(
      String guardianId) async {
    try {
      final response = await _apiService.getGuardianWithChildren(guardianId);

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        final guardianData = data['guardian'];
        final childrenData = data['children'] as List<dynamic>?;

        if (guardianData != null) {
          final guardian = GuardianModel.fromJson(guardianData).toEntity();
          final children = childrenData?.map((childJson) {
                return ChildModel.fromJson(childJson).toEntity();
              }).toList() ??
              [];

          return {
            'guardian': guardian,
            'children': children,
          };
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian with children: $e');
      return null;
    }
  }

  @override
  Future<Guardian?> getGuardianById(String guardianId) async {
    try {
      final response = await _apiService.getGuardianById(guardianId);

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardianData = response.data['data']['guardian'];
        if (guardianData != null) {
          final guardianModel = GuardianModel.fromJson(guardianData);
          return guardianModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      print('Error getting guardian by ID: $e');
      return null;
    }
  }

  @override
  Future<bool> linkChildToGuardian(String guardianId, String childId) async {
    try {
      final response =
          await _apiService.linkChildToGuardian(guardianId, childId);
      return response.data['success'] == true;
    } catch (e) {
      print('Error linking child to guardian: $e');
      return false;
    }
  }

  @override
  Future<bool> unlinkChildFromGuardian(
      String guardianId, String childId) async {
    try {
      final response =
          await _apiService.unlinkChildFromGuardian(guardianId, childId);
      return response.data['success'] == true;
    } catch (e) {
      print('Error unlinking child from guardian: $e');
      return false;
    }
  }

  @override
  Future<Guardian?> createGuardian(Guardian guardian) async {
    try {
      final response = await _apiService.createGuardian(guardian);

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardianData = response.data['data']['guardian'];
        if (guardianData != null) {
          final guardianModel = GuardianModel.fromJson(guardianData);
          return guardianModel.toEntity();
        }
      }

      return null;
    } catch (e) {
      print('Error creating guardian: $e');
      return null;
    }
  }

  @override
  Future<bool> updateGuardian(Guardian guardian) async {
    try {
      final response = await _apiService.updateGuardian(guardian);
      return response.data['success'] == true;
    } catch (e) {
      print('Error updating guardian: $e');
      return false;
    }
  }

  @override
  Future<List<Guardian>> getAllGuardians() async {
    try {
      final response = await _apiService.getAllGuardians();

      if (response.data['success'] == true && response.data['data'] != null) {
        final guardiansData =
            response.data['data']['guardians'] as List<dynamic>?;
        if (guardiansData != null) {
          return guardiansData.map((guardianJson) {
            return GuardianModel.fromJson(guardianJson).toEntity();
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error getting all guardians: $e');
      return [];
    }
  }
}
