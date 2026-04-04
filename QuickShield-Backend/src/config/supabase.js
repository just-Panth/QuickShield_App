// supabaseClient.js

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// Hardcode fallback (safe for dev)
const supabaseUrl =
  process.env.SUPABASE_URL || "https://skkamagoofsbhxmqystc.supabase.co";

const supabaseKey =
  process.env.SUPABASE_SERVICE_KEY ||
  process.env.SUPABASE_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNra2FtYWdvb2ZzYmh4bXF5c3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxNTA1NjEsImV4cCI6MjA5MDcyNjU2MX0.Jk57WPB1xXL04w33JenObiLFrevxRkQmI5m2vGE1dfI";

// Debug logs (remove in production)
console.log("Supabase URL:", supabaseUrl);
console.log("Supabase Key loaded:", !!supabaseKey);

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { persistSession: false },
});

module.exports = supabase;