require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('./services/db');

const SCHEMA_PATH = path.join(__dirname, '..', 'database', 'schema.sql');

// schema.sql is written to be idempotent end to end (CREATE TABLE / CREATE INDEX
// IF NOT EXISTS, ADD COLUMN IF NOT EXISTS, CREATE OR REPLACE FUNCTION, DROP
// TRIGGER IF EXISTS before CREATE TRIGGER, and ON CONFLICT DO NOTHING on the
// seed rows), so re-running it on every deploy is safe and needs no migration
// version table.
async function migrate() {
  const sql = fs.readFileSync(SCHEMA_PATH, 'utf8');
  const client = await pool.connect();
  try {
    await client.query(sql);
    console.log('Migration complete: schema.sql applied.');
  } finally {
    client.release();
  }
}

if (require.main === module) {
  migrate()
    .then(() => pool.end())
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Migration failed:', err.message);
      process.exit(1);
    });
}

module.exports = migrate;
