require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function migrate() {
  // Try calling a direct ALTER via rpc if available
  const queries = [
    "ALTER TABLE claims ADD COLUMN IF NOT EXISTS fraud_score INTEGER",
    "ALTER TABLE claims ADD COLUMN IF NOT EXISTS fraud_verdict TEXT",
    "ALTER TABLE claims ADD COLUMN IF NOT EXISTS fraud_explanation TEXT",
  ];

  let allOk = true;
  for (const sql of queries) {
    const result = await supabase.rpc('exec_sql', { sql });
    if (result.error) {
      allOk = false;
      console.log(`RPC unavailable: ${result.error.message}`);
      break;
    }
    console.log(`OK: ${sql}`);
  }

  if (!allOk) {
    console.log('\n⚠️  Auto-migration failed (Supabase RPC not exposed).');
    console.log('Run this SQL in your Supabase dashboard → SQL Editor:\n');
    console.log('ALTER TABLE claims ADD COLUMN IF NOT EXISTS fraud_score INTEGER;');
    console.log('ALTER TABLE claims ADD COLUMN IF NOT EXISTS fraud_verdict TEXT;');
    console.log('ALTER TABLE claims ADD COLUMN IF NOT EXISTS fraud_explanation TEXT;');
    console.log('\nThe app will still work — fraud data simply won\'t persist until columns exist.');
  } else {
    console.log('\n✅ Migration complete — fraud columns added to claims table.');
  }

  // Also confirm payout_ledger
  const lr = await supabase.from('payout_ledger').select('id').limit(1);
  if (lr.error) {
    console.log('\n⚠️  payout_ledger table missing. Run this SQL:');
    console.log(`CREATE TABLE IF NOT EXISTS payout_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id UUID REFERENCES claims(id),
  worker_id UUID REFERENCES workers(id),
  amount_inr INTEGER NOT NULL,
  upi_id TEXT,
  txn_id TEXT UNIQUE NOT NULL,
  gateway TEXT DEFAULT 'razorpay_mock',
  status TEXT DEFAULT 'success',
  paid_at TIMESTAMPTZ DEFAULT NOW(),
  error_msg TEXT
);`);
  } else {
    console.log('✅ payout_ledger table OK');
  }
}

migrate().catch(console.error);
