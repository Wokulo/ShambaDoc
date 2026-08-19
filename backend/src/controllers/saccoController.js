const pool = require('../services/db');

const saccoController = {
  async listSaccos(req, res) {
    try {
      const { county, verified } = req.query;
      const conditions = ['is_active = true'];
      const params = [];
      let idx = 1;

      if (county) {
        conditions.push(`county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }
      if (verified !== undefined) {
        conditions.push(`verification_status = $${idx}`);
        params.push(verified ? 'verified' : 'pending');
        idx++;
      }

      const query = `SELECT * FROM saccos WHERE ${conditions.join(' AND ')} ORDER BY name ASC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, saccos: result.rows });
    } catch (error) {
      console.error('List SACCOs error:', error);
      res.status(500).json({ error: 'Failed to fetch SACCOs' });
    }
  },

  async getNearby(req, res) {
    try {
      const { lat, lng, radius = 50 } = req.query;

      if (!lat || !lng) {
        return res.status(400).json({ error: 'Latitude and longitude are required' });
      }

      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const searchRadius = parseFloat(radius);

      const query = `
        SELECT * FROM (
          SELECT
            id,
            name,
            county,
            phone,
            email,
            physical_address,
            verification_status,
            (
              6371 * acos(
                LEAST(1, GREATEST(-1,
                  cos(radians($1)) * cos(radians(latitude)) *
                  cos(radians(longitude) - radians($2)) +
                  sin(radians($1)) * sin(radians(latitude))
                ))
              )
            ) AS distance_km
          FROM saccos
          WHERE is_active = true AND verification_status = 'verified'
        ) AS saccos_with_distance
        WHERE distance_km <= $3
        ORDER BY distance_km ASC
        LIMIT 50;
      `;

      const result = await pool.query(query, [latitude, longitude, searchRadius]);
      res.json({ success: true, count: result.rows.length, saccos: result.rows });
    } catch (error) {
      console.error('Get nearby SACCOs error:', error);
      res.status(500).json({ error: 'Failed to fetch nearby SACCOs' });
    }
  },

  async getSacco(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query(
        'SELECT * FROM saccos WHERE id = $1 AND is_active = true',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'SACCO not found' });
      }

      res.json({ success: true, sacco: result.rows[0] });
    } catch (error) {
      console.error('Get SACCO error:', error);
      res.status(500).json({ error: 'Failed to fetch SACCO' });
    }
  },

  async getFinancialProducts(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query(
        'SELECT * FROM financial_products WHERE sacco_id = $1 AND is_active = true ORDER BY product_type, name',
        [id]
      );

      res.json({ success: true, count: result.rows.length, products: result.rows });
    } catch (error) {
      console.error('Get financial products error:', error);
      res.status(500).json({ error: 'Failed to fetch financial products' });
    }
  },

  async submitInquiry(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const { message, product_id } = req.body;

      const result = await pool.query(
        `INSERT INTO consultations (farmer_id, consultation_type, status, farmer_message, created_at)
         VALUES ($1, 'sacco_inquiry', 'pending', $2, NOW())
         RETURNING *`,
        [userId, JSON.stringify({ sacco_id: id, product_id, message })]
      );

      res.status(201).json({ success: true, inquiry: result.rows[0] });
    } catch (error) {
      console.error('Submit inquiry error:', error);
      res.status(500).json({ error: 'Failed to submit inquiry' });
    }
  },
};

module.exports = saccoController;
