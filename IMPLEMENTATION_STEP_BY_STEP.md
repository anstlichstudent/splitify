# 🚀 Step-by-Step Implementation Guide

## Phase 1: Setup Foundation (1-2 jam)

### Step 1: Install Dependencies

```bash
# Core Riverpod
flutter pub add flutter_riverpod riverpod_annotation

# Code generation
flutter pub add -d riverpod_generator build_runner

# Freezed for immutable state classes
flutter pub add freezed_annotation
flutter pub add -d freezed

# Functional programming
flutter pub add dartz

# Equatable for value equality
flutter pub add equatable
```

### Step 2: Update main.dart

```dart
// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    const ProviderScope(  // 🔥 Wrap dengan ProviderScope
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {  // 🔥 Change to ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {  // 🔥 Add WidgetRef
    return MaterialApp(
      title: 'Splitify App',
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### Step 3: Create Folder Structure

```bash
mkdir -p lib/{core,data,domain,presentation,services}
mkdir -p lib/core/{constants,theme,utils,errors}
mkdir -p lib/data/{models,datasources,repositories}
mkdir -p lib/domain/{entities,repositories,usecases}
mkdir -p lib/presentation/{providers,controllers,screens,widgets,state}
```

---

## Phase 2: Create Core Layer (30 mins)

### core/constants/app_colors.dart

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color darkBlue = Color(0xFF000518);
  static const Color primaryColor = Color(0xFF3B5BFF);
  static const Color cardColor = Color(0xFF1A1F2E);
  static const Color dividerColor = Color(0xFF2A3142);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color warningColor = Color(0xFFFFC107);

  // Neutral colors
  static const Color textLight = Colors.white;
  static const Color textMedium = Color(0xFFB0BEC5);
  static const Color textDark = Color(0xFF455A64);

  // Opacity variants
  static Color primaryOpacity10 = primaryColor.withOpacity(0.1);
  static Color primaryOpacity20 = primaryColor.withOpacity(0.2);
  static Color primaryOpacity50 = primaryColor.withOpacity(0.5);
}
```

### core/constants/app_strings.dart

```dart
class AppStrings {
  // Common
  static const String appName = 'Splitify';
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';

  // Auth
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';

  // Activities
  static const String createActivity = 'Create Activity';
  static const String activities = 'Activities';
  static const String noActivities = 'No activities yet';

  // Friends
  static const String friends = 'Friends';
  static const String addFriend = 'Add Friend';
  static const String noFriends = 'No friends yet';
}
```

### core/theme/app_theme.dart

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBlue,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBlue,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
```

### core/errors/failures.dart

```dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class FirebaseFailure extends Failure {
  FirebaseFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) : super(message);
}

class UnknownFailure extends Failure {
  UnknownFailure(String message) : super(message);
}
```

---

## Phase 3: Create Domain Layer (1 jam)

### domain/entities/user.dart

```dart
class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### domain/repositories/auth_repository.dart

```dart
import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signUp(String email, String password, String displayName);
  Future<Either<Failure, void>> signOut();
  Stream<User?> authStateChanges();
}
```

### domain/usecases/auth/sign_in_usecase.dart

```dart
import 'package:dartz/dartz.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Either<Failure, User>> call(String email, String password) async {
    // Validasi input
    if (email.isEmpty || password.isEmpty) {
      return Left(ValidationFailure('Email dan password tidak boleh kosong'));
    }

    // Call repository
    return await repository.signIn(email, password);
  }
}
```

---

## Phase 4: Create Data Layer (1.5 jam)

### data/models/user_model.dart

```dart
import '../../domain/entities/user.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  // Dari Firebase map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
    );
  }

  // Ke map (untuk Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert ke Entity
  User toEntity() {
    return User(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: createdAt,
    );
  }
}
```

### data/datasources/firebase_auth_datasource.dart

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String displayName);
  Future<void> signOut();
  Stream<UserModel?> authStateChanges();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSourceImpl(this._firebaseAuth);

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('User is null');

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<UserModel> signUp(String email, String password, String displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('User is null');

      await user.updateDisplayName(displayName);

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
    });
  }
}
```

### data/repositories/auth_repository_impl.dart

```dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, User>> signIn(String email, String password) async {
    try {
      final userModel = await dataSource.signIn(email, password);
      return Right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Auth error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUp(String email, String password, String displayName) async {
    try {
      final userModel = await dataSource.signUp(email, password, displayName);
      return Right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Auth error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return dataSource.authStateChanges().map((userModel) {
      return userModel?.toEntity();
    });
  }
}
```

---

## Phase 5: Create Riverpod Providers (1 jam)

### presentation/providers/auth_provider.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user.dart' as domain_user;
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/sign_up_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import 'repository_providers.dart';

// 🔥 Use case providers
final signInUseCaseProvider = Provider((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

// 🔥 Auth state stream
final authStateProvider = StreamProvider<domain_user.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// 🔥 Current user provider
final currentUserProvider = Provider<domain_user.User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// 🔥 Auth notifier untuk manage sign in/sign up flow
class AuthNotifier extends StateNotifier<AsyncValue<domain_user.User?>> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;

  AuthNotifier(this._signInUseCase, this._signUpUseCase, this._signOutUseCase)
      : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    final result = await _signInUseCase(email, password);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();

    final result = await _signUpUseCase(email, password, displayName);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signOut() async {
    await _signOutUseCase();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<domain_user.User?>>((ref) {
  return AuthNotifier(
    ref.watch(signInUseCaseProvider),
    ref.watch(signUpUseCaseProvider),
    ref.watch(signOutUseCaseProvider),
  );
});
```

### presentation/providers/repository_providers.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// 🔥 Firebase instances
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

// 🔥 Data sources
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSourceImpl(ref.watch(firebaseAuthProvider));
});

// 🔥 Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDataSourceProvider));
});
```

---

## Phase 6: Migrate Login Screen (1 jam)

### presentation/screens/auth/login_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: authState.when(
        loading: () => const _LoadingWidget(),
        error: (error, stack) => _ErrorWidget(
          error: error.toString(),
          onRetry: () => ref.refresh(authNotifierProvider),
        ),
        data: (_) => _LoginForm(
          emailController: _emailController,
          passwordController: _passwordController,
          formKey: _formKey,
          onLogin: () {
            if (_formKey.currentState!.validate()) {
              ref.read(authNotifierProvider.notifier).signIn(
                _emailController.text.trim(),
                _passwordController.text,
              );
            }
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // Logo/Title
            Text(
              AppStrings.appName,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Email field
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: AppStrings.email,
                prefixIcon: const Icon(Icons.email),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Email required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: AppStrings.password,
                prefixIcon: const Icon(Icons.lock),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password required';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogin,
                child: const Text(AppStrings.login),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

---

## Next Steps

1. ✅ Complete remaining domain/data layers (Friends, Activities, Receipts)
2. ✅ Create providers untuk setiap feature
3. ✅ Migrate remaining screens ke ConsumerWidget
4. ✅ Run `dart run build_runner build` untuk generate code
5. ✅ Test all flows

Ready untuk continue? 🚀
