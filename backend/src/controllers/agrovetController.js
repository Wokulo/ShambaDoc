const pool = require('../services/db');

const agrovetController = {
  async listAgrovets(req, res) {
    try {
      const { county, verified, product_category } = req.query;
      const conditions = ['a.is_active = true'];
      const params = [];
      let idx = 1;

      if (county) {
        conditions.push(`a.county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }
      if (verified !== undefined) {
        conditions.push(`ag.verification_status = $${idx}`);
        params.push(verified ? 'verified' : 'pending');
        idx++;
      }
      if (product_category) {
        conditions.push(`$${idx} = ANY(a.products)`);
        params.push(product_category);
        idx++;
      }

      const query = `
        SELECT ag.*, a.name as dealer_name, a.phone as dealer_phone, a.address as dealer_address
        FROM agrovets ag
        JOIN agro_dealers a ON ag.dealer_id = a.id
        WHERE ${conditions.join(' AND ')}
        ORDER BY ag.rating DESC, ag.review_count DESC
        LIMIT 50
      `;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, agrovets: result.rows });
    } catch (error) {
      console.error('List agrovets error:', error);
      res.status(500).json({ error: 'Failed to fetch agrovets' });
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
        SELECT ag.*, a.name as dealer_name, a.phone as dealer_phone, a.address as dealer_address,
          (
            6371 * acos(
              LEAST(1, GREATEST(-1,
                cos(radians($1)) * cos(radians(ag.latitude)) *
                cos(radians(ag.longitude) - radians($2)) +
                sin(radians($1)) * sin(radians(ag.latitude))
              ))
            ) AS distance_km
        FROM agrovets ag
        JOIN agro_dealers a ON ag.dealer_id = a.id
        WHERE ag.is_active = true AND ag.verification_status = 'verified'
        HAVING distance_km <= $3
        ORDER BY ag.rating DESC, distance_km ASC
        LIMIT 50;
      `;

      const result = await pool.query(query, [latitude, longitude, searchRadius]);
      res.json({ success: true, count: result.rows.length, agrovets: result.rows });
    } catch (error) {
      console.error('Get nearby agrovets error:', error);
      res.status(500).json({ error: 'Failed to fetch nearby agrovets' });
    }
  },

  async getAgrovet(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query(
        `SELECT ag.*, a.name as dealer_name, a.phone as dealer_phone, a.email as dealer_email, a.address as dealer_address, a.products as dealer_products
         FROM agrovets ag
         JOIN agro_dealers a ON ag.dealer_id = a.id
         WHERE ag.id = $1 AND ag.is_active = true`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Agrovet not found' });
      }

      res.json({ success: true, agrovet: result.rows[0] });
    } catch (error) {
      console.error('Get agrovet error:', error);
      res.status(500).json({ error: 'Failed to fetch agrovet' });
    }
  },

  async getProducts(req, res) {
    try {
      const { id } = req.params;
      const { category, search } = req.query;
      const conditions = ['agrovet_id = $1', 'is_active = true'];
      const params = [id];
      let idx = 2;

      if (category) {
        conditions.push(`category ILIKE $${idx}`);
        params.push(`%${category}%`);
        idx++;
      }
      if (search) {
        conditions.push(`name ILIKE $${idx}`);
        params.push(`%${search}%`);
        idx++;
      }

      const query = `SELECT * FROM agrovet_products WHERE ${conditions.join(' AND ')} ORDER BY name ASC LIMIT 100`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, products: result.rows });
    } catch (error) {
      console.error('Get products error:', error);
      res.status(500).json({ error: 'Failed to fetch products' });
    }
  },

  async submitInquiry(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const { message, product_id, quantity } = req.body;

      const result = await pool.query(
        `INSERT INTO consultations (farmer_id, consultation_type, status, farmer_message, created_at)
         VALUES ($1, 'agrovet_inquiry', 'pending', $2, NOW())
         RETURNING *`,
        [userId, JSON.stringify({ agrovet_id: id, product_id, quantity, message })]
      );

      res.status(201).json({ success: true, inquiry: result.rows[0] });
    } catch (error) {
      console.error('Submit inquiry error:', error);
      res.status(500).json({ error: 'Failed to submit inquiry' });
    }
  },

  async submitReview(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const { rating, review_text } = req.body;

      if (!rating || rating < 1 || rating > 5) {
        return res.status(400).json({ error: 'Rating must be between 1 and 5' });
      }

      const result = await pool.query(
        `INSERT INTO reviews (user_id, target_type, target_id, rating, review_text)
         VALUES ($1, 'agrovet', $2, $3, $4)
         RETURNING *`,
        [userId, id, rating, review_text || '']
      );

      await pool.query(
        `UPDATE agrovets
         SET rating = ((rating * review_count) + $1) / (review_count + 1),
             review_count = review_count + 1
         WHERE id = $2`,
        [rating, id]
      );

      res.status(201).json({ success: true, review: result.rows[0] });
    } catch (error) {
      console.error('Submit review error:', error);
      res.status(500).json({ error: 'Failed to submit review' });
    }
  },
};

module.exports = agrovetController;
