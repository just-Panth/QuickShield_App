const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const supabase = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

async function seed() {
  const workerId = uuidv4();
  
  console.log('Seeding worker...');
  const { error: workerErr } = await supabase.from('workers').insert({
    id: workerId,
    email: 'raj.kumar@blinkit.com',
    phone: '+919876543210',
    full_name: 'Raj Kumar',
    worker_platform_id: 'GW-882291',
    platform: 'blinkit',
    city: 'Bangalore',
    zone_id: 'BLR-SOUTH',
    avg_daily_earnings_14d: 850,
  });

  if (workerErr) {
    console.error('Worker insert failed:', workerErr);
    return;
  }
  
  console.log('Seeding policy...');
  const policyId1 = uuidv4();
  const policyId2 = uuidv4();
  
  await supabase.from('policies').insert([
    {
      id: policyId1,
      worker_id: workerId,
      plan_type: 'daily_income_shield',
      premium_inr: 110,
      risk_score: 52,
      duration_weeks: 1,
      status: 'active',
    },
    {
      id: policyId2,
      worker_id: workerId,
      plan_type: 'monsoon_surge_cover',
      premium_inr: 145,
      risk_score: 65,
      duration_weeks: 4,
      status: 'expired',
    }
  ]);

  console.log('Seeding claims...');
  await supabase.from('claims').insert([
    {
      worker_id: workerId,
      policy_id: policyId1,
      disruption_type: 'weather',
      status: 'paid',
      amount_inr: 1200,
      gate_results: {
        "gate_1": { "status": "pass", "reason": "Severe waterlogging confirmed by local API" },
        "gate_2": { "status": "pass", "reason": "GPS matches disruption zone" },
        "gate_3": { "status": "pass", "reason": "Score: 92. Fraud unlikely." }
      },
      settled_at: new Date(Date.now() - 86400000 * 2).toISOString() // 2 days ago
    },
    {
      worker_id: workerId,
      policy_id: policyId2,
      disruption_type: 'traffic',
      status: 'rejected',
      amount_inr: 0,
      gate_results: {
        "gate_1": { "status": "fail", "reason": "No major traffic congestion detected at given time" },
        "gate_2": { "status": "pending", "reason": null },
        "gate_3": { "status": "pending", "reason": null }
      }
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
      amount_inr: 800 + Math.floor(Math.random() * 300) - 150, // Between 650 and 950
      platform: 'blinkit'
    });
  }
  await supabase.from('earnings_ledger').insert(ledger);

  console.log('-----------------------------------');
  console.log('✅ Seed successful! User Login Details:');
  console.log('Email: raj.kumar@blinkit.com');
  console.log('Password: (Passwordless/Any for demo)');
  console.log('-----------------------------------');
}

seed();
