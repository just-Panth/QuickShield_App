const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn('⚠️  Supabase credentials missing — set SUPABASE_URL and SUPABASE_SERVICE_KEY in .env');
}

// Service-role client: bypasses Row Level Security for backend operations
const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { persistSession: false },
});

module.exports = supabase;
