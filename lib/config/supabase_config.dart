/// Supabase project credentials — see SUPABASE_SETUP.md to generate these.
///
/// The anon key is safe to ship in client code: Supabase enforces access
/// per-user through the Row Level Security policies in
/// `supabase/schema.sql`, not by keeping this key secret.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://kasdhoehubpnxlaoksms.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imthc2Rob2VodWJwbnhsYW9rc21zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1MTIyNDUsImV4cCI6MjEwNjA4ODI0NX0.SG9RtFWHk7ClcybMH4KzeSUjF-c82pq0Uw2II1rrgZw';
}
