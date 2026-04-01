const Redis = require('ioredis');

let redis;

try {
  redis = new Redis(process.env.UPSTASH_REDIS_URL, {
    password: process.env.UPSTASH_REDIS_TOKEN,
    tls: {},
    maxRetriesPerRequest: 3,
    lazyConnect: true,
  });

  redis.on('connect', () => console.log('📦 Redis (Upstash) connected'));
  redis.on('error',   (err) => console.warn('⚠️  Redis error:', err.message));
} catch (err) {
  console.warn('⚠️  Redis not configured — zone maps will not be cached:', err.message);
  // Fallback: in-memory mock so the app works without Redis during local dev
  redis = {
    get:    async () => null,
    set:    async () => 'OK',
    del:    async () => 1,
    setex:  async () => 'OK',
    lpush:  async () => 1,
    lrange: async () => [],
  };
}

module.exports = redis;
