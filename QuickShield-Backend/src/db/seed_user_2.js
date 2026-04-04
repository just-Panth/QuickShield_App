const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const supabase = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

async function seed() {
  const workerId = uuidv4();
  
  console.log('Seeding new worker (Amit)...');
  const { error: workerErr } = await supabase.from('workers').insert({
    id: workerId,
    email: 'amit.sharma@swiggy.com',
    phone: '+919988776655',
    full_name: 'Amit Sharma',
    worker_platform_id: 'GW-994433',
    platform: 'swiggy',
    city: 'Mumbai',
    zone_id: 'MUM-WEST',
    avg_daily_earnings_14d: 950,
  });

  if (workerErr) {
    console.error('Worker insert failed:', workerErr);
    return;
  }
  
  console.log('Seeding policy...');
  const policyId1 = uuidv4();
  
  await supabase.from('policies').insert([
    {
      id: policyId1,
      worker_id: workerId,
      plan_type: 'daily_income_shield',
      premium_inr: 125,
      risk_score: 55,
      duration_weeks: 1,
      status: 'active',
    }
  ]);

  console.log('Seeding claims...');
  await supabase.from('claims').insert([
    {
      worker_id: workerId,
      policy_id: policyId1,
      disruption_type: 'weather',
      status: 'paid',
      amount_inr: 850,
      gate_results: {
        "gate_1": { "status": "pass", "reason": "Heavy rainfall detected" },
        "gate_2": { "status": "pass", "reason": "Location verified" },
        "gate_3": { "status": "pass", "reason": "Approved" }
      },
      settled_at: new Date(Date.now() - 86400000 * 1).toISOString() // 1 day ago
    }
  ]);

  console.log('Seeding earnings ledger...');
  const ledger = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    ledger.push({
      worker_id: workerId,
      date: d.toISOString().split('T')[0],
      amount_inr: 700 + Math.floor(Math.random() * 400),
      platform: 'swiggy'
    });
  }
  await supabase.from('earnings_ledger').insert(ledger);

  console.log('-----------------------------------');
  console.log('✅ Seed successful! User Login Details:');
  console.log('Email: amit.sharma@swiggy.com');
  console.log('Password: (Passwordless/Any for demo)');
  console.log('-----------------------------------');
}

seed();
