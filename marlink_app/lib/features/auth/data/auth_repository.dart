import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? SecureStorageService();

  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user']);

    await _storageService.saveAuthToken(token);
    await _storageService.saveUserId(user.id);

    return user;
  }

  Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'login': login,
        'password': password,
        'device_name': 'MarLink Mobile Client',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user']);

    await _storageService.saveAuthToken(token);
    await _storageService.saveUserId(user.id);

    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Continue clearing local tokens even if remote logout fails
    } finally {
      await _storageService.clearAll();
    }
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(
      ApiEndpoints.me,
      fromJsonT: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      ApiEndpoints.updateProfile,
      data: updates,
      fromJsonT: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<UserModel> uploadAvatar(dynamic imageFile) async {
    final String path = imageFile is String ? imageFile : imageFile.path;
    final fileName = path.split('/').last.split(r'\').last;

    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(path, filename: fileName),
    });

    final response = await _apiClient.post(
      ApiEndpoints.uploadAvatar,
      data: formData,
      fromJsonT: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<bool> hasValidToken() async {
    final token = await _storageService.getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
