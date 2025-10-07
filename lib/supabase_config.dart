import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Credenciales de tu proyecto Supabase
  static const String supabaseUrl = 'https://weurjculqnxvtmbqltjo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndldXJqY3VscW54dnRtYnFsdGpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3ODQ2ODQsImV4cCI6MjA3NTM2MDY4NH0.bIhnyTLY4ICK0NYjaR0Pjs9LWz4nKVoXcCkUwBb2Ymo';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

// Cliente global de Supabase
final supabase = Supabase.instance.client;