import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Conductor feature
import '../../features/conductor/data/datasources/conductor_remote_datasource.dart';
import '../../features/conductor/data/datasources/conductor_remote_datasource_impl.dart';
import '../../features/conductor/data/repositories/conductor_repository_impl.dart';
import '../../features/conductor/domain/repositories/conductor_repository.dart';
import '../../features/conductor/domain/usecases/get_conductor_profile.dart';
import '../../features/conductor/domain/usecases/update_conductor_profile.dart';
import '../../features/conductor/domain/usecases/update_driver_license.dart';
import '../../features/conductor/domain/usecases/update_vehicle.dart';
import '../../features/conductor/domain/usecases/submit_profile_for_approval.dart';
import '../../features/conductor/domain/usecases/get_conductor_statistics.dart';
import '../../features/conductor/domain/usecases/get_conductor_earnings.dart';
import '../../features/conductor/domain/usecases/get_trip_history.dart';
import '../../features/conductor/domain/usecases/get_active_trips.dart';
import '../../features/conductor/domain/usecases/update_conductor_availability.dart';
import '../../features/conductor/domain/usecases/update_conductor_location.dart';
import '../../features/conductor/presentation/providers/conductor_profile_provider_refactored.dart';

// User microservice
import '../../features/user/data/datasources/user_remote_datasource.dart';
import '../../features/user/data/datasources/user_remote_datasource_impl.dart';
import '../../features/user/data/datasources/user_local_datasource.dart';
import '../../features/user/data/datasources/user_local_datasource_impl.dart';
import '../../features/user/data/repositories/user_repository_impl.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/domain/usecases/register_user.dart';
import '../../features/user/domain/usecases/login_user.dart';
import '../../features/user/domain/usecases/logout_user.dart';
import '../../features/user/domain/usecases/get_user_profile.dart';
import '../../features/user/domain/usecases/update_user_profile.dart';
import '../../features/user/domain/usecases/update_user_location.dart';
import '../../features/user/domain/usecases/get_saved_session.dart';
import '../../features/user/presentation/providers/user_provider.dart';

// Trips microservice
import '../../features/trips/data/datasources/trip_remote_datasource.dart';
import '../../features/trips/data/repositories/trip_repository_impl.dart';
import '../../features/trips/domain/repositories/trip_repository.dart';
import '../../features/trips/domain/usecases/create_trip.dart';
import '../../features/trips/domain/usecases/accept_trip.dart';
import '../../features/trips/domain/usecases/start_trip.dart';
import '../../features/trips/domain/usecases/complete_trip.dart';
import '../../features/trips/domain/usecases/cancel_trip.dart';
import '../../features/trips/domain/usecases/get_active_trips.dart' as trip_usecases;
import '../../features/trips/domain/usecases/get_trip_history.dart' as trip_usecases;
import '../../features/trips/domain/usecases/rate_conductor.dart';
import '../../features/trips/presentation/providers/trip_provider.dart';

// Maps microservice
import '../../features/maps/data/datasources/map_remote_datasource.dart';
import '../../features/maps/data/repositories/map_repository_impl.dart';
import '../../features/maps/domain/repositories/map_repository.dart';
import '../../features/maps/domain/usecases/geocode_address.dart';
import '../../features/maps/domain/usecases/calculate_route.dart';
import '../../features/maps/presentation/providers/map_provider.dart';

// Admin microservice
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/get_system_stats.dart';
import '../../features/admin/domain/usecases/approve_driver.dart';
import '../../features/admin/domain/usecases/reject_driver.dart';
import '../../features/admin/presentation/providers/admin_provider.dart';

/// Service Locator - Contenedor de InyecciÃ³n de Dependencias
/// 
/// Maneja la creaciÃ³n e inyecciÃ³n de todas las dependencias.
/// Usa el patrÃ³n Singleton para mantener instancias Ãºnicas.
/// 
/// VENTAJAS PARA MICROSERVICIOS:
/// - Centraliza la configuraciÃ³n de datasources (URLs de servicios)
/// - Facilita cambiar entre implementaciones (mock, real, diferentes endpoints)
/// - Permite testing con dependencias mockeadas
/// 
/// ALTERNATIVAS:
/// - get_it package (mÃ¡s robusto para proyectos grandes)
/// - Provider con MultiProvider (usado actualmente en main.dart)
/// - injectable + get_it (con generaciÃ³n de cÃ³digo)
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // HTTP Client compartido
  late final http.Client _httpClient;
  late final SharedPreferences _sharedPreferences;

  // Datasources - Conductor
  late final ConductorRemoteDataSource _conductorRemoteDataSource;

  // Datasources - User Microservice
  late final UserRemoteDataSource _userRemoteDataSource;
  late final UserLocalDataSource _userLocalDataSource;

  // Datasources - Trips Microservice
  late final TripRemoteDataSource _tripRemoteDataSource;

  // Datasources - Maps Microservice
  late final MapRemoteDataSource _mapRemoteDataSource;

  // Datasources - Admin Microservice
  late final AdminRemoteDataSource _adminRemoteDataSource;

  // Repositories
  late final ConductorRepository _conductorRepository;
  late final UserRepository _userRepository;
  late final TripRepository _tripRepository;
  late final MapRepository _mapRepository;
  late final AdminRepository _adminRepository;

  // Use Cases - Conductor
  late final GetConductorProfile _getConductorProfile;
  late final UpdateConductorProfile _updateConductorProfile;
  late final UpdateDriverLicense _updateDriverLicense;
  late final UpdateVehicle _updateVehicle;
  late final SubmitProfileForApproval _submitProfileForApproval;
  late final GetConductorStatistics _getConductorStatistics;
  late final GetConductorEarnings _getConductorEarnings;
  late final GetTripHistory _getTripHistory;
  late final GetActiveTrips _getActiveTrips;
  late final UpdateConductorAvailability _updateConductorAvailability;
  late final UpdateConductorLocation _updateConductorLocation;

  // Use Cases - User Microservice
  late final RegisterUser _registerUser;
  late final LoginUser _loginUser;
  late final LogoutUser _logoutUser;
  late final GetUserProfile _getUserProfile;
  late final UpdateUserProfile _updateUserProfile;
  late final UpdateUserLocation _updateUserLocation;
  late final GetSavedSession _getSavedSession;

  // Use Cases - Trips Microservice
  late final CreateTrip _createTrip;
  late final AcceptTrip _acceptTrip;
  late final StartTrip _startTrip;
  late final CompleteTrip _completeTrip;
  late final CancelTrip _cancelTrip;
  late final trip_usecases.GetActiveTrips _getTripActiveTrips;
  late final trip_usecases.GetTripHistory _getTripTripHistory;
  late final RateConductor _rateTripConductor;

  // Use Cases - Maps Microservice
  late final GeocodeAddress _geocodeAddress;
  late final CalculateRoute _calculateRoute;

  // Use Cases - Admin Microservice
  late final GetSystemStats _getSystemStats;
  late final ApproveDriver _approveDriver;
  late final RejectDriver _rejectDriver;

  bool _initialized = false;

  /// Inicializa todas las dependencias
  Future<void> init() async {
    if (_initialized) return;

    // HTTP Client
    _httpClient = http.Client();

    // SharedPreferences
    _sharedPreferences = await SharedPreferences.getInstance();

    // ========== USER MICROSERVICE ==========

    // Datasources
    _userRemoteDataSource = UserRemoteDataSourceImpl(client: _httpClient);
    _userLocalDataSource = UserLocalDataSourceImpl(
      sharedPreferences: _sharedPreferences,
    );

    // Repository
    _userRepository = UserRepositoryImpl(
      remoteDataSource: _userRemoteDataSource,
      localDataSource: _userLocalDataSource,
    );

    // Use Cases
    _registerUser = RegisterUser(_userRepository);
    _loginUser = LoginUser(_userRepository);
    _logoutUser = LogoutUser(_userRepository);
    _getUserProfile = GetUserProfile(_userRepository);
    _updateUserProfile = UpdateUserProfile(_userRepository);
    _updateUserLocation = UpdateUserLocation(_userRepository);
    _getSavedSession = GetSavedSession(_userRepository);

    // ========== CONDUCTOR FEATURE ==========

    // Datasources
    _conductorRemoteDataSource = ConductorRemoteDataSourceImpl(
      client: _httpClient,
    );

    // Repositories
    _conductorRepository = ConductorRepositoryImpl(
      remoteDataSource: _conductorRemoteDataSource,
    );

    // Use Cases
    _getConductorProfile = GetConductorProfile(_conductorRepository);
    _updateConductorProfile = UpdateConductorProfile(_conductorRepository);
    _updateDriverLicense = UpdateDriverLicense(_conductorRepository);
    _updateVehicle = UpdateVehicle(_conductorRepository);
    _submitProfileForApproval = SubmitProfileForApproval(_conductorRepository);
    _getConductorStatistics = GetConductorStatistics(_conductorRepository);
    _getConductorEarnings = GetConductorEarnings(_conductorRepository);
    _getTripHistory = GetTripHistory(_conductorRepository);
    _getActiveTrips = GetActiveTrips(_conductorRepository);
    _updateConductorAvailability = UpdateConductorAvailability(_conductorRepository);
    _updateConductorLocation = UpdateConductorLocation(_conductorRepository);

    // ========== TRIPS MICROSERVICE ==========

    // Datasources
    _tripRemoteDataSource = TripRemoteDataSourceImpl(client: _httpClient);

    // Repository
    _tripRepository = TripRepositoryImpl(remoteDataSource: _tripRemoteDataSource);

    // Use Cases
    _createTrip = CreateTrip(_tripRepository);
    _acceptTrip = AcceptTrip(_tripRepository);
    _startTrip = StartTrip(_tripRepository);
    _completeTrip = CompleteTrip(_tripRepository);
    _cancelTrip = CancelTrip(_tripRepository);
    _getTripActiveTrips = trip_usecases.GetActiveTrips(_tripRepository);
    _getTripTripHistory = trip_usecases.GetTripHistory(_tripRepository);
    _rateTripConductor = RateConductor(_tripRepository);

    // ========== MAPS MICROSERVICE ==========

    // Datasources
    _mapRemoteDataSource = MapRemoteDataSourceImpl(client: _httpClient);

    // Repository
    _mapRepository = MapRepositoryImpl(remoteDataSource: _mapRemoteDataSource);

    // Use Cases
    _geocodeAddress = GeocodeAddress(_mapRepository);
    _calculateRoute = CalculateRoute(_mapRepository);

    // ========== ADMIN MICROSERVICE ==========

    // Datasources
    _adminRemoteDataSource = AdminRemoteDataSourceImpl(client: _httpClient);

    // Repository
    _adminRepository = AdminRepositoryImpl(remoteDataSource: _adminRemoteDataSource);

    // Use Cases
    _getSystemStats = GetSystemStats(_adminRepository);
    _approveDriver = ApproveDriver(_adminRepository);
    _rejectDriver = RejectDriver(_adminRepository);

    _initialized = true;
  }

  // Getters para obtener dependencias

  http.Client get httpClient => _httpClient;
  SharedPreferences get sharedPreferences => _sharedPreferences;

  // User Microservice
  UserRemoteDataSource get userRemoteDataSource => _userRemoteDataSource;
  UserLocalDataSource get userLocalDataSource => _userLocalDataSource;
  UserRepository get userRepository => _userRepository;

  RegisterUser get registerUser => _registerUser;
  LoginUser get loginUser => _loginUser;
  LogoutUser get logoutUser => _logoutUser;
  GetUserProfile get getUserProfile => _getUserProfile;
  UpdateUserProfile get updateUserProfile => _updateUserProfile;
  UpdateUserLocation get updateUserLocation => _updateUserLocation;
  GetSavedSession get getSavedSession => _getSavedSession;

  // Conductor Feature
  ConductorRemoteDataSource get conductorRemoteDataSource =>
      _conductorRemoteDataSource;

  ConductorRepository get conductorRepository => _conductorRepository;

  GetConductorProfile get getConductorProfile => _getConductorProfile;
  UpdateConductorProfile get updateConductorProfile => _updateConductorProfile;
  UpdateDriverLicense get updateDriverLicense => _updateDriverLicense;
  UpdateVehicle get updateVehicle => _updateVehicle;
  SubmitProfileForApproval get submitProfileForApproval =>
      _submitProfileForApproval;
  GetConductorStatistics get getConductorStatistics => _getConductorStatistics;
  GetConductorEarnings get getConductorEarnings => _getConductorEarnings;
  GetTripHistory get getTripHistory => _getTripHistory;
  GetActiveTrips get getActiveTrips => _getActiveTrips;
  UpdateConductorAvailability get updateConductorAvailability =>
      _updateConductorAvailability;
  UpdateConductorLocation get updateConductorLocation =>
      _updateConductorLocation;

  // Trips Microservice
  TripRepository get tripRepository => _tripRepository;

  CreateTrip get createTrip => _createTrip;
  AcceptTrip get acceptTrip => _acceptTrip;
  StartTrip get startTrip => _startTrip;
  CompleteTrip get completeTrip => _completeTrip;
  CancelTrip get cancelTrip => _cancelTrip;
  trip_usecases.GetActiveTrips get getTripActiveTrips => _getTripActiveTrips;
  trip_usecases.GetTripHistory get getTripTripHistory => _getTripTripHistory;
  RateConductor get rateTripConductor => _rateTripConductor;

  // Maps Microservice
  MapRepository get mapRepository => _mapRepository;

  GeocodeAddress get geocodeAddress => _geocodeAddress;
  CalculateRoute get calculateRoute => _calculateRoute;

  // Admin Microservice
  AdminRepository get adminRepository => _adminRepository;

  GetSystemStats get getSystemStats => _getSystemStats;
  ApproveDriver get approveDriver => _approveDriver;
  RejectDriver get rejectDriver => _rejectDriver;

  /// Crea un provider de usuarios configurado con todas las dependencias
  UserProvider createUserProvider() {
    return UserProvider(
      registerUserUseCase: _registerUser,
      loginUserUseCase: _loginUser,
      logoutUserUseCase: _logoutUser,
      getUserProfileUseCase: _getUserProfile,
      updateUserProfileUseCase: _updateUserProfile,
      updateUserLocationUseCase: _updateUserLocation,
      getSavedSessionUseCase: _getSavedSession,
    );
  }

  /// Crea un provider de conductor configurado con todas las dependencias
  ConductorProfileProvider createConductorProfileProvider() {
    return ConductorProfileProvider(
      getConductorProfileUseCase: _getConductorProfile,
      updateProfileUseCase: _updateConductorProfile,
      updateLicenseUseCase: _updateDriverLicense,
      updateVehicleUseCase: _updateVehicle,
      submitForApprovalUseCase: _submitProfileForApproval,
    );
  }

  /// Crea un provider de viajes configurado con todas las dependencias
  TripProvider createTripProvider() {
    return TripProvider(
      createTripUseCase: _createTrip,
      acceptTripUseCase: _acceptTrip,
      startTripUseCase: _startTrip,
      completeTripUseCase: _completeTrip,
      cancelTripUseCase: _cancelTrip,
      getActiveTripsUseCase: _getTripActiveTrips,
      getTripHistoryUseCase: _getTripTripHistory,
      rateConductorUseCase: _rateTripConductor,
    );
  }

  /// Crea un provider de mapas configurado con todas las dependencias
  MapProvider createMapProvider() {
    return MapProvider(
      geocodeAddressUseCase: _geocodeAddress,
      calculateRouteUseCase: _calculateRoute,
    );
  }

  /// Crea un provider de administraciÃ³n configurado con todas las dependencias
  AdminProvider createAdminProvider() {
    return AdminProvider(
      getSystemStatsUseCase: _getSystemStats,
      approveDriverUseCase: _approveDriver,
      rejectDriverUseCase: _rejectDriver,
    );
  }

  /// Limpia recursos (opcional, para testing)
  void dispose() {
    _httpClient.close();
    _initialized = false;
  }
}
