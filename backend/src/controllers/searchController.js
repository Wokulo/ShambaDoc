const pool = require('../services/db');

const searchController = {
  async searchServices(req, res) {
    try {
      const { q, type, county, lat, lng, radius = 50, verified } = req.query;

      if (!q) {
        return res.status(400).json({ error: 'Search query is required' });
      }

      const searchTerm = `%${q}%`;
      const results = [];

      if (!type || type === 'agronomist') {
        const agronomistQuery = `
          SELECT 'agronomist' as type, id, full_name as name, county, phone, email, verification_status, rating, review_count
          FROM agronomists
          WHERE is_active = true AND (full_name ILIKE $1 OR professional_title ILIKE $1 OR bio ILIKE $1)
        `;
        const agronomistParams = [searchTerm];
        if (county) {
          agronomistQuery += ` AND county ILIKE $2`;
          agronomistParams.push(`%${county}%`);
        }
        if (verified !== undefined) {
          agronomistQuery += ` AND verification_status = $${agronomistParams.length + 1}`;
          agronomistParams.push(verified ? 'verified' : 'pending');
        }
        const agResult = await pool.query(agronomistQuery + ' LIMIT 20', agronomistParams);
        results.push(...agResult.rows.map(r => ({ ...r, distance_km: null })));
      }

      if (!type || type === 'government_officer') {
        const govQuery = `
          SELECT 'government_officer' as type, id, full_name as name, designation, county, phone, email, verification_status
          FROM government_officers
          WHERE is_active = true AND (full_name ILIKE $1 OR designation ILIKE $1 OR department ILIKE $1)
        `;
        const govParams = [searchTerm];
        if (county) {
          govQuery += ` AND county ILIKE $2`;
          govParams.push(`%${county}%`);
        }
        const govResult = await pool.query(govQuery + ' LIMIT 20', govParams);
        results.push(...govResult.rows.map(r => ({ ...r, distance_km: null })));
      }

      if (!type || type === 'agrovet') {
        const agrovetQuery = `
          SELECT 'agrovet' as type, ag.id, ag.business_name as name, ag.county, ag.phone, ag.email, ag.verification_status, ag.rating, ag.review_count, a.address
          FROM agrovets ag
          JOIN agro_dealers a ON ag.dealer_id = a.id
          WHERE ag.is_active = true AND (ag.business_name ILIKE $1 OR a.address ILIKE $1)
        `;
        const agrovetParams = [searchTerm];
        if (county) {
          agrovetQuery += ` AND ag.county ILIKE $2`;
          agrovetParams.push(`%${county}%`);
        }
        if (verified !== undefined) {
          agrovetQuery += ` AND ag.verification_status = $${agrovetParams.length + 1}`;
          agrovetParams.push(verified ? 'verified' : 'pending');
        }
        const agrovetResult = await pool.query(agrovetQuery + ' LIMIT 20', agrovetParams);
        results.push(...agrovetResult.rows.map(r => ({ ...r, distance_km: null })));
      }

      if (!type || type === 'sacco') {
        const saccoQuery = `
          SELECT 'sacco' as type, id, name, county, phone, email, verification_status
          FROM saccos
          WHERE is_active = true AND (name ILIKE $1 OR description ILIKE $1)
        `;
        const saccoParams = [searchTerm];
        if (county) {
          saccoQuery += ` AND county ILIKE $2`;
          saccoParams.push(`%${county}%`);
        }
        if (verified !== undefined) {
          saccoQuery += ` AND verification_status = $${saccoParams.length + 1}`;
          saccoParams.push(verified ? 'verified' : 'pending');
        }
        const saccoResult = await pool.query(saccoQuery + ' LIMIT 20', saccoParams);
        results.push(...saccoResult.rows.map(r => ({ ...r, distance_km: null })));
      }

      if (!type || type === 'insurance') {
        const insuranceQuery = `
          SELECT 'insurance' as type, id, name, county, phone, email, verification_status
          FROM insurance_providers
          WHERE is_active = true AND (name ILIKE $1 OR description ILIKE $1)
        `;
        const insuranceParams = [searchTerm];
        if (county) {
          insuranceQuery += ` AND county ILIKE $2`;
          insuranceParams.push(`%${county}%`);
        }
        if (verified !== undefined) {
          insuranceQuery += ` AND verification_status = $${insuranceParams.length + 1}`;
          insuranceParams.push(verified ? 'verified' : 'pending');
        }
        const insuranceResult = await pool.query(insuranceQuery + ' LIMIT 20', insuranceParams);
        results.push(...insuranceResult.rows.map(r => ({ ...r, distance_km: null })));
      }

      res.json({ success: true, count: results.length, results });
    } catch (error) {
      console.error('Search services error:', error);
      res.status(500).json({ error: 'Failed to search services' });
    }
  },

  async searchDiseases(req, res) {
    try {
      const { q, crop_type } = req.query;

      if (!q) {
        return res.status(400).json({ error: 'Search query is required' });
      }

      const searchTerm = `%${q}%`;
      const conditions = ['1=1'];
      const params = [searchTerm];
      let idx = 2;

      if (crop_type) {
        conditions.push(`crop_type ILIKE $${idx}`);
        params.push(`%${crop_type}%`);
        idx++;
      }

      const query = `SELECT * FROM disease_knowledge WHERE (disease_name ILIKE $1 OR description_en ILIKE $1) AND ${conditions.join(' AND ')} ORDER BY disease_name ASC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, diseases: result.rows });
    } catch (error) {
      console.error('Search diseases error:', error);
      res.status(500).json({ error: 'Failed to search diseases' });
    }
  },

  async searchCrops(req, res) {
    try {
      const result = await pool.query(
        `SELECT DISTINCT crop_type FROM plots WHERE crop_type IS NOT NULL
         UNION
         SELECT DISTINCT crop_type FROM scans WHERE crop_type IS NOT NULL
         ORDER BY crop_type ASC`
      );

      res.json({ success: true, count: result.rows.length, crops: result.rows.map(r => r.crop_type) });
    } catch (error) {
      console.error('Search crops error:', error);
      res.status(500).json({ error: 'Failed to search crops' });
    }
  },

  async searchEvents(req, res) {
    try {
      const { q, county, event_type, from_date, to_date } = req.query;
      const conditions = ["event_date >= NOW()"];
      const params = [];
      let idx = 1;

      if (q) {
        conditions.push(`(title ILIKE $${idx} OR description ILIKE $${idx})`);
        params.push(`%${q}%`);
        idx++;
      }
      if (county) {
        conditions.push(`county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }
      if (event_type) {
        conditions.push(`event_type = $${idx}`);
        params.push(event_type);
        idx++;
      }
      if (from_date) {
        conditions.push(`event_date >= $${idx}`);
        params.push(from_date);
        idx++;
      }
      if (to_date) {
        conditions.push(`event_date <= $${idx}`);
        params.push(to_date);
        idx++;
      }

      const query = `SELECT * FROM agricultural_events WHERE ${conditions.join(' AND ')} ORDER BY event_date ASC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, events: result.rows });
    } catch (error) {
      console.error('Search events error:', error);
      res.status(500).json({ error: 'Failed to search events' });
    }
  },
};

module.exports = searchController;
