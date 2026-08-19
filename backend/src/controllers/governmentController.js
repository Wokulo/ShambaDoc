const pool = require('../services/db');

const governmentController = {
  async listOfficers(req, res) {
    try {
      const { county } = req.query;
      const conditions = ['is_active = true'];
      const params = [];
      let idx = 1;

      if (county) {
        conditions.push(`county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }

      const query = `SELECT * FROM government_officers WHERE ${conditions.join(' AND ')} ORDER BY county, designation LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, officers: result.rows });
    } catch (error) {
      console.error('List government officers error:', error);
      res.status(500).json({ error: 'Failed to fetch government officers' });
    }
  },

  async getNearbyOfficers(req, res) {
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
            designation,
            department,
            county,
            phone,
            email,
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
          FROM government_officers
          WHERE is_active = true AND verification_status = 'verified'
        ) AS officers_with_distance
        WHERE distance_km <= $3
        ORDER BY distance_km ASC
        LIMIT 50;
      `;

      const result = await pool.query(query, [latitude, longitude, searchRadius]);
      res.json({ success: true, count: result.rows.length, officers: result.rows });
    } catch (error) {
      console.error('Get nearby officers error:', error);
      res.status(500).json({ error: 'Failed to fetch nearby officers' });
    }
  },

  async getOfficer(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query(
        'SELECT * FROM government_officers WHERE id = $1 AND is_active = true',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Officer not found' });
      }

      res.json({ success: true, officer: result.rows[0] });
    } catch (error) {
      console.error('Get officer error:', error);
      res.status(500).json({ error: 'Failed to fetch officer' });
    }
  },

  async requestSupport(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const { request_type, message, location, scan_id } = req.body;

      const result = await pool.query(
        `INSERT INTO consultations (scan_id, farmer_id, government_officer_id, consultation_type, status, farmer_message, created_at)
         VALUES ($1, $2, $3, $4, 'pending', $5, NOW())
         RETURNING *`,
        [scan_id || null, userId, id, request_type || 'chat', JSON.stringify({ request_type, message, location })]
      );

      res.status(201).json({ success: true, request: result.rows[0] });
    } catch (error) {
      console.error('Request support error:', error);
      res.status(500).json({ error: 'Failed to request support' });
    }
  },

  async getAdvisories(req, res) {
    try {
      const { county, crop_type } = req.query;
      const conditions = ['is_published = true', "(published_at IS NULL OR published_at <= NOW())", "(expires_at IS NULL OR expires_at >= NOW())"];
      const params = [];
      let idx = 1;

      if (county) {
        conditions.push(`$${idx} = ANY(counties)`);
        params.push(county);
        idx++;
      }
      if (crop_type) {
        conditions.push(`$${idx} = ANY(crop_types)`);
        params.push(crop_type);
        idx++;
      }

      const query = `SELECT * FROM agricultural_advisories WHERE ${conditions.join(' AND ')} ORDER BY published_at DESC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, advisories: result.rows });
    } catch (error) {
      console.error('Get advisories error:', error);
      res.status(500).json({ error: 'Failed to fetch advisories' });
    }
  },

  async getPrograms(req, res) {
    try {
      const result = await pool.query(
        `SELECT * FROM government_programs
         WHERE is_active = true
           AND (application_start_date IS NULL OR application_start_date <= NOW())
           AND (application_end_date IS NULL OR application_end_date >= NOW())
         ORDER BY application_start_date DESC`
      );

      res.json({ success: true, count: result.rows.length, programs: result.rows });
    } catch (error) {
      console.error('Get programs error:', error);
      res.status(500).json({ error: 'Failed to fetch programs' });
    }
  },

  async getEvents(req, res) {
    try {
      const { county } = req.query;
      const conditions = ["event_date >= NOW()"];
      const params = [];
      let idx = 1;

      if (county) {
        conditions.push(`county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }

      const query = `SELECT * FROM agricultural_events WHERE ${conditions.join(' AND ')} ORDER BY event_date ASC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, events: result.rows });
    } catch (error) {
      console.error('Get events error:', error);
      res.status(500).json({ error: 'Failed to fetch events' });
    }
  },

  async reportOutbreak(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { disease_name, crop_type, county, severity, case_count, location } = req.body;

      const result = await pool.query(
        `INSERT INTO disease_outbreaks (disease_name, crop_type, county, severity, case_count, start_date, is_active)
         VALUES ($1, $2, $3, $4, $5, NOW(), true)
         RETURNING *`,
        [disease_name, crop_type, county, severity || 'medium', case_count || 1]
      );

      res.status(201).json({ success: true, outbreak: result.rows[0] });
    } catch (error) {
      console.error('Report outbreak error:', error);
      res.status(500).json({ error: 'Failed to report outbreak' });
    }
  },
};

module.exports = governmentController;
