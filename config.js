// Supabase connection for the dashboard.
//
// Both values are designed to be public: Supabase's "anon" (publishable) key only
// identifies the project. It cannot read any data on its own. Access is enforced
// in the database by row-level security (see supabase/schema.sql): only signed-in
// users whose email is in the allowed_users table can read the project data.
//
// Leave these empty and the dashboard runs on the sample data only.
// NEVER put the service_role (secret) key here.
window.DASHBOARD_CONFIG = {
  supabaseUrl: "",       // e.g. "https://abcdefghijkl.supabase.co"
  supabaseAnonKey: ""    // Project Settings → API Keys → anon / publishable key
};
