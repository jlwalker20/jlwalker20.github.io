/* Supabase connection for the campaign app (the game companions don't need it).
   Find both values in the Supabase dashboard: Project Settings -> API.
   The anon key is meant to be public; the database functions guard every change. */
window.GAMING_CONFIG = {
  supabaseUrl: "",      // e.g. "https://abcdefghijkl.supabase.co"
  supabaseAnonKey: ""   // the long "anon public" key
};
