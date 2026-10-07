// CTLRS — Supabase connection config
// Fill these in with YOUR project's values (Supabase → Project Settings → API).
// The anon/public key is safe to expose in client-side code — it only grants
// access allowed by your Row Level Security (RLS) policies.
window.CTLRS_CONFIG = {
  SUPABASE_URL: "https://magynxmxsuzugihqgroi.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hZ3lueG14c3V6dWdpaHFncm9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzODU1OTIsImV4cCI6MjEwNjk2MTU5Mn0.r8uJ8zfVryvR7Gz3YRFz8wKIrD8r3kZdGJC-pHCmeOY",
  // ROOM lets several independent demo instances share one Supabase table.
  // Leave as "main" unless you need multiple separate datasets.
  ROOM: "main"
};
