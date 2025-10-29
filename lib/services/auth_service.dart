import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../supabase_config.dart';
import 'user_service.dart';

// SERVICIO DE AUTENTICACIÓN - FIREBASE AUTH + SUPABASE USERS
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final _client = supabase;
  
  // Usuario actual de Firebase
  static User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  // Stream de cambios de autenticación
  static Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // AUTENTICACIÓN CON FIREBASE + SINCRONIZACIÓN CON SUPABASE

  /// Inicializar servicio de auth
  static Future<void> initialize() async {
    try {
      // Configurar persistencia de sesión
      await _firebaseAuth.setPersistence(Persistence.LOCAL);
      
      // Escuchar cambios de auth para sincronizar con Supabase
      _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
      
      debugPrint('🔐 Auth service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing auth service: $e');
    }
  }

  /// Listener para cambios de autenticación
  static Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      // Usuario logueado - sincronizar con Supabase
      await _syncUserWithSupabase(user);
    } else {
      // Usuario deslogueado - limpiar cache
      UserService.clearUserCache();
    }
  }

  /// Sincronizar usuario de Firebase con Supabase
  static Future<void> _syncUserWithSupabase(User firebaseUser) async {
    try {
      debugPrint('🔄 Syncing Firebase user with Supabase...');
      
      // Extraer información del usuario de Firebase
      final name = firebaseUser.displayName ?? 'Usuario';
      final email = firebaseUser.email;
      final phone = firebaseUser.phoneNumber;
      
      // Si no tiene teléfono en Firebase, usar email como identificador
      final identifier = phone ?? email ?? firebaseUser.uid;
      
      // Validar o crear usuario en Supabase
      await UserService.validateOrCreateUser(
        name: name,
        phone: identifier,
        email: email,
      );
      
      debugPrint('✅ User synced successfully');
    } catch (e) {
      debugPrint('❌ Error syncing user: $e');
    }
  }

  // MÉTODOS DE AUTENTICACIÓN

  /// Login con Google
  static Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google sign in...');
      
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ Google sign in cancelled by user');
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      debugPrint('✅ Google sign in successful: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Error signing in with Google: $e');
      return null;
    }
  }

  /// Login con email y contraseña
  static Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Starting email sign in...');
      
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email sign in successful');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Error signing in with email: $e');
      return null;
    }
  }

  /// Registro con email y contraseña
  static Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      debugPrint('📝 Starting user registration...');
      
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar perfil con nombre
      await userCredential.user?.updateDisplayName(name);
      
      debugPrint('✅ User registration successful');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Error registering user: $e');
      return null;
    }
  }

  /// Login con teléfono (SMS)
  static Future<bool> signInWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      debugPrint('📱 Starting phone verification...');
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolución (Android)
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.message}');
          onError(e.message ?? 'Error en verificación');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📲 SMS code sent');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Code auto-retrieval timeout');
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ Error in phone sign in: $e');
      onError(e.toString());
      return false;
    }
  }

  /// Verificar código SMS
  static Future<User?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      debugPrint('🔍 Verifying SMS code...');
      
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      debugPrint('✅ Phone verification successful');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Error verifying phone code: $e');
      return null;
    }
  }

  /// Login anónimo (para usuarios temporales)
  static Future<User?> signInAnonymously() async {
    try {
      debugPrint('👤 Starting anonymous sign in...');
      
      final UserCredential userCredential = await _firebaseAuth.signInAnonymously();
      
      debugPrint('✅ Anonymous sign in successful');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Error signing in anonymously: $e');
      return null;
    }
  }

  // GESTIÓN DE SESIÓN

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      debugPrint('👋 Signing out...');
      
      // Cerrar sesión en Google si está activo
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Cerrar sesión en Firebase
      await _firebaseAuth.signOut();
      
      // Limpiar cache de usuario
      UserService.clearUserCache();
      
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }

  /// Verificar si el usuario está logueado
  static bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Verificar si el usuario está verificado
  static bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Enviar email de verificación
  static Future<bool> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('📧 Verification email sent');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      return false;
    }
  }

  /// Resetear contraseña
  static Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint('📧 Password reset email sent');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending password reset email: $e');
      return false;
    }
  }

  // GESTIÓN DE PERFIL

  /// Actualizar perfil del usuario
  static Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        
        // Recargar datos del usuario
        await user.reload();
        
        // Sincronizar cambios con Supabase
        await _syncUserWithSupabase(user);
        
        debugPrint('✅ Profile updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Obtener información del usuario actual
  static Map<String, dynamic>? getCurrentUserInfo() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      };
    }
    return null;
  }

  // INTEGRACIÓN CON SISTEMA DE RESERVAS

  /// Validar que el usuario puede hacer reservas
  static Future<bool> canUserMakeReservation() async {
    if (!isSignedIn) return false;
    
    // Verificar en Supabase si el usuario tiene buena reputación
    return UserService.canUserMakeReservation();
  }

  /// Obtener estadísticas del usuario para mostrar en perfil
  static Future<Map<String, dynamic>> getUserProfileStats() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return {};
    
    // Combinar info de Firebase con estadísticas de Supabase
    final firebaseInfo = getCurrentUserInfo();
    final supabaseUser = UserService.getCurrentUser();
    
    if (supabaseUser != null) {
      final stats = await UserService.getUserStats(supabaseUser['id']);
      return {
        ...firebaseInfo ?? {},
        ...stats,
      };
    }
    
    return firebaseInfo ?? {};
  }

  // MANEJO DE ERRORES

  /// Obtener mensaje de error legible
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Email inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error desconocido. Intenta nuevamente';
    }
  }

  // LISTENERS Y OBSERVADORES

  /// Suscribirse a cambios de autenticación
  static void listenToAuthChanges(Function(User?) onAuthChanged) {
    _firebaseAuth.authStateChanges().listen(onAuthChanged);
  }

  /// Verificar conexión y estado del servicio
  static Future<bool> isServiceHealthy() async {
    try {
      // Verificar que Firebase Auth esté funcionando
      final currentUser = _firebaseAuth.currentUser;
      
      // Verificar que Supabase esté funcionando
      final response = await _client.from('sodita_usuarios').select('count').limit(1);
      
      debugPrint('🏥 Auth service health check: OK');
      return true;
    } catch (e) {
      debugPrint('❌ Auth service health check failed: $e');
      return false;
    }
  }
}