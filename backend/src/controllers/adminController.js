const pool = require('../services/db');

const adminController = {
  async listVerificationRequests(req, res) {
    try {
      const { status, requester_type } = req.query;
      const conditions = [];
      const params = [];
      let idx = 1;

      if (status) {
        conditions.push(`status = $${idx}`);
        params.push(status);
        idx++;
      }
      if (requester_type) {
        conditions.push(`requester_type = $${idx}`);
        params.push(requester_type);
        idx++;
      }

      const query = `SELECT * FROM verification_requests WHERE ${conditions.length > 0 ? conditions.join(' AND ') : '1=1'} ORDER BY submitted_at DESC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, requests: result.rows });
    } catch (error) {
      console.error('List verification requests error:', error);
      res.status(500).json({ error: 'Failed to fetch verification requests' });
    }
  },

  async reviewVerification(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { status, review_notes } = req.body;

      if (!['verified', 'rejected'].includes(status)) {
        return res.status(400).json({ error: 'Status must be verified or rejected' });
      }

      const result = await pool.query(
        `UPDATE verification_requests SET status = $1, review_notes = $2, reviewed_by = $3, reviewed_at = NOW() WHERE id = $4 RETURNING *`,
        [status, review_notes || '', userId, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Verification request not found' });
      }

      res.json({ success: true, request: result.rows[0] });
    } catch (error) {
      console.error('Review verification error:', error);
      res.status(500).json({ error: 'Failed to review verification' });
    }
  },

  async listUsers(req, res) {
    try {
      const { role, county } = req.query;
      const conditions = [];
      const params = [];
      let idx = 1;

      if (role) {
        conditions.push(`role = $${idx}`);
        params.push(role);
        idx++;
      }
      if (county) {
        conditions.push(`county ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }

      const query = `SELECT uid, phone_number, display_name, email, county, farm_size_hectares, preferred_language, role, sync_consent, created_at, last_login FROM users WHERE ${conditions.length > 0 ? conditions.join(' AND ') : '1=1'} ORDER BY created_at DESC LIMIT 100`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, users: result.rows });
    } catch (error) {
      console.error('List users error:', error);
      res.status(500).json({ error: 'Failed to fetch users' });
    }
  },

  async updateUserRole(req, res) {
    try {
      const { id } = req.params;
      const { role } = req.body;

      const validRoles = ['farmer', 'dealer', 'sacco_admin', 'analyst', 'agronomist', 'admin'];
      if (!validRoles.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
      }

      const result = await pool.query(
        'UPDATE users SET role = $1 WHERE uid = $2 RETURNING uid, role',
        [role, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json({ success: true, user: result.rows[0] });
    } catch (error) {
      console.error('Update user role error:', error);
      res.status(500).json({ error: 'Failed to update user role' });
    }
  },

  async getScanReports(req, res) {
    try {
      const { days = 30, county, crop_type } = req.query;
      const conditions = [];
      const params = [];
      let idx = 1;

      conditions.push(`scanned_at >= NOW() - INTERVAL '${parseInt(days)} days'`);
      if (county) {
        conditions.push(`region ILIKE $${idx}`);
        params.push(`%${county}%`);
        idx++;
      }
      if (crop_type) {
        conditions.push(`crop_type ILIKE $${idx}`);
        params.push(`%${crop_type}%`);
        idx++;
      }

      const query = `SELECT crop_type, disease_name, confidence_tier, severity, region, COUNT(*) as scan_count, AVG(confidence) as avg_confidence FROM scans WHERE ${conditions.join(' AND ')} GROUP BY crop_type, disease_name, confidence_tier, severity, region ORDER BY scan_count DESC LIMIT 100`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, reports: result.rows });
    } catch (error) {
      console.error('Get scan reports error:', error);
      res.status(500).json({ error: 'Failed to fetch scan reports' });
    }
  },

  async getProviderReports(req, res) {
    try {
      const agronomistQuery = `
        SELECT 'agronomist' as provider_type, COUNT(*) as total, COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count, AVG(rating) as avg_rating
        FROM agronomists
      `;
      const agronomistResult = await pool.query(agronomistQuery);

      const agrovetQuery = `
        SELECT 'agrovet' as provider_type, COUNT(*) as total, COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count, AVG(rating) as avg_rating
        FROM agrovets
      `;
      const agrovetResult = await pool.query(agrovetQuery);

      const govQuery = `
        SELECT 'government_officer' as provider_type, COUNT(*) as total, COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count
        FROM government_officers
      `;
      const govResult = await pool.query(govQuery);

      const saccoQuery = `
        SELECT 'sacco' as provider_type, COUNT(*) as total, COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count
        FROM saccos
      `;
      const saccoResult = await pool.query(saccoQuery);

      const insuranceQuery = `
        SELECT 'insurance' as provider_type, COUNT(*) as total, COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count
        FROM insurance_providers
      `;
      const insuranceResult = await pool.query(insuranceQuery);

      res.json({
        success: true,
        reports: [
          ...agronomistResult.rows,
          ...agrovetResult.rows,
          ...govResult.rows,
          ...saccoResult.rows,
          ...insuranceResult.rows,
        ],
      });
    } catch (error) {
      console.error('Get provider reports error:', error);
      res.status(500).json({ error: 'Failed to fetch provider reports' });
    }
  },

  async createAdvisory(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { title, content, crop_types, counties, severity_level, expires_at } = req.body;

      const userResult = await pool.query(
        `SELECT role FROM users WHERE uid = $1`,
        [userId]
      );

      if (userResult.rows.length === 0 || !['government_officer', 'agronomist', 'admin'].includes(userResult.rows[0].role)) {
        return res.status(403).json({ error: 'Only authorized users can create advisories' });
      }

      const result = await pool.query(
        `INSERT INTO agricultural_advisories (author_id, author_type, title, content, crop_types, counties, severity_level, is_published, published_at, expires_at, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, true, NOW(), $8, NOW())
         RETURNING *`,
        [userId, userResult.rows[0].role, title, content, crop_types || [], counties || [], severity_level || 'info', expires_at || null]
      );

      res.status(201).json({ success: true, advisory: result.rows[0] });
    } catch (error) {
      console.error('Create advisory error:', error);
      res.status(500).json({ error: 'Failed to create advisory' });
    }
  },

  async updateAdvisory(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { title, content, crop_types, counties, severity_level, is_published, expires_at } = req.body;

      const result = await pool.query(
        `UPDATE agricultural_advisories SET title = $1, content = $2, crop_types = $3, counties = $4, severity_level = $5, is_published = $6, expires_at = $7, updated_at = NOW() WHERE id = $8 RETURNING *`,
        [title, content, crop_types || [], counties || [], severity_level, is_published, expires_at, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Advisory not found' });
      }

      res.json({ success: true, advisory: result.rows[0] });
    } catch (error) {
      console.error('Update advisory error:', error);
      res.status(500).json({ error: 'Failed to update advisory' });
    }
  },

  async deleteAdvisory(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query('DELETE FROM agricultural_advisories WHERE id = $1 RETURNING id', [id]);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Advisory not found' });
      }

      res.json({ success: true, message: 'Advisory deleted successfully' });
    } catch (error) {
      console.error('Delete advisory error:', error);
      res.status(500).json({ error: 'Failed to delete advisory' });
    }
  },
};

module.exports = adminController;
