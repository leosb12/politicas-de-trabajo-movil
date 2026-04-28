import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_constants.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasource/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_current_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_view_model.dart';
import 'login_state.dart';
import 'password_recovery_state.dart';
import 'password_recovery_view_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: NetworkConstants.baseUrl);
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(sharedPreferencesProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(dio: ref.watch(dioProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    sessionStorage: ref.watch(sessionStorageProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentSessionUseCaseProvider = Provider<GetCurrentSessionUseCase>((
  ref,
) {
  return GetCurrentSessionUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, LoginState>((
  ref,
) {
  return AuthViewModel(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    getCurrentSessionUseCase: ref.watch(getCurrentSessionUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    changePasswordUseCase: ref.watch(changePasswordUseCaseProvider),
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
  );
});

final passwordRecoveryViewModelProvider = StateNotifierProvider<PasswordRecoveryViewModel, PasswordRecoveryState>((
  ref,
) {
  return PasswordRecoveryViewModel(
    authRepository: ref.watch(authRepositoryProvider),
  );
});
