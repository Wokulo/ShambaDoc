const pool = require('../services/db');

const agronomistController = {
  async listAgronomists(req, res) {
    try {
      const { county, specialization, verified } = req.query;
      const conditions = ['is_active = true'];
      const params = [];
      let idx = 1;

      if (county) {
        conditions.push(`county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }
      if (specialization) {
        conditions.push(`specialization @> $${idx}::text[]`);
        params.push([specialization]);
        idx++;
      }
      if (verified !== undefined) {
        conditions.push(`verification_status = $${idx}`);
        params.push(verified ? 'verified' : 'pending');
        idx++;
      }

      const query = `SELECT * FROM agronomists WHERE ${conditions.join(' AND ')} ORDER BY rating DESC, review_count DESC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, agronomists: result.rows });
    } catch (error) {
      console.error('List agronomists error:', error);
      res.status(500).json({ error: 'Failed to fetch agronomists' });
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
            full_name,
            professional_title,
            specialization,
            county,
            phone,
            email,
            availability,
            rating,
            review_count,
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
          FROM agronomists
          WHERE is_active = true AND verification_status = 'verified'
        ) AS agronomists_with_distance
        WHERE distance_km <= $3
        ORDER BY rating DESC, distance_km ASC
        LIMIT 50;
      `;

      const result = await pool.query(query, [latitude, longitude, searchRadius]);
      res.json({ success: true, count: result.rows.length, agronomists: result.rows });
    } catch (error) {
      console.error('Get nearby agronomists error:', error);
      res.status(500).json({ error: 'Failed to fetch nearby agronomists' });
    }
  },

  async getAgronomist(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query(
        'SELECT * FROM agronomists WHERE id = $1 AND is_active = true',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Agronomist not found' });
      }

      res.json({ success: true, agronomist: result.rows[0] });
    } catch (error) {
      console.error('Get agronomist error:', error);
      res.status(500).json({ error: 'Failed to fetch agronomist' });
    }
  },

  async requestConsultation(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const { consultation_type, farmer_message, scan_id, scheduled_at } = req.body;

      const result = await pool.query(
        `INSERT INTO consultations (scan_id, farmer_id, agronomist_id, consultation_type, status, farmer_message, scheduled_at, created_at)
         VALUES ($1, $2, $3, $4, 'pending', $5, $6, NOW())
         RETURNING *`,
        [scan_id || null, userId, id, consultation_type || 'chat', farmer_message, scheduled_at || null]
      );

      res.status(201).json({ success: true, consultation: result.rows[0] });
    } catch (error) {
      console.error('Request consultation error:', error);
      res.status(500).json({ error: 'Failed to request consultation' });
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
         VALUES ($1, 'agronomist', $2, $3, $4)
         RETURNING *`,
        [userId, id, rating, review_text || '']
      );

      await pool.query(
        `UPDATE agronomists
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

module.exports = agronomistController;
