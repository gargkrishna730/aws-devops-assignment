

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const mysql = require('mysql2/promise');
const redis = require('redis');

const app = express();
app.use(express.json());

// MySQL setup
const dbConfig = {
  host: process.env.MYSQL_HOST,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE,
  port: process.env.MYSQL_PORT || 3306
};

// Redis setup (Elasticache)
const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});
redisClient.connect().catch(console.error);

// Serve the UI
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Health endpoint
app.get('/health', (req, res) => {
  console.log(`[${new Date().toISOString()}] GET /health`);
  res.status(200).json({ ok: true });
});

// Trade place endpoint
app.post('/trade/place', async (req, res) => {
  const id = uuidv4();
  const status = 'accepted';
  const created_at = new Date().toISOString();
  console.log(`[${new Date().toISOString()}] POST /trade/place - Attempting to insert trade:`, { id, status, created_at });
  try {
    const conn = await mysql.createConnection(dbConfig);
    await conn.execute('INSERT INTO trades (id, status, created_at) VALUES (?, ?, ?)', [id, status, created_at]);
    await conn.end();
    console.log(`[${new Date().toISOString()}] Trade inserted into DB:`, { id, status, created_at });
    // Cache in Redis
    await redisClient.set(id, JSON.stringify({ id, status, created_at }), { EX: 60 });
    res.status(200).json({ status, id });
  } catch (err) {
    console.error(`[${new Date().toISOString()}] Error inserting trade:`, err);
    res.status(500).json({ error: 'DB error', details: err.message });
  }
});

// Get trade by id (cache first)
app.get('/trade/:id', async (req, res) => {
  const id = req.params.id;
  console.log(`[${new Date().toISOString()}] GET /trade/${id}`);
  try {
    const cached = await redisClient.get(id);
    if (cached) {
      console.log(`[${new Date().toISOString()}] Trade found in Redis cache:`, id);
      return res.status(200).json(JSON.parse(cached));
    }
    const conn = await mysql.createConnection(dbConfig);
    const [rows] = await conn.execute('SELECT * FROM trades WHERE id = ?', [id]);
    await conn.end();
    if (!rows.length) {
      console.log(`[${new Date().toISOString()}] Trade not found in DB:`, id);
      return res.status(404).json({ error: 'Trade not found' });
    }
    await redisClient.set(id, JSON.stringify(rows[0]), { EX: 60 });
    console.log(`[${new Date().toISOString()}] Trade found in DB and cached:`, id);
    res.status(200).json(rows[0]);
  } catch (err) {
    console.error(`[${new Date().toISOString()}] Error fetching trade:`, err);
    res.status(500).json({ error: 'DB error', details: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
