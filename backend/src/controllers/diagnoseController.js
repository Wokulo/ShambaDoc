const plantIdService = require('../services/plantIdService');
const pool = require('../services/db');

const diagnoseController = {
  async logDiagnosis(req, res) {
    try {
      const {
        scan_id,
        disease,
        confidence,
        confidence_tier,
        severity,
        crop_type,
        lat,
        lng,
        timestamp,
        image_base64
      } = req.body;

      if (!scan_id || !disease || confidence === undefined) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      const query = `
        INSERT INTO scans (scan_id, user_id, disease_name, confidence, confidence_tier, severity,
                           crop_type, latitude, longitude, scanned_at, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
        ON CONFLICT (scan_id) DO NOTHING
        RETURNING *;
      `;

      const values = [
        scan_id,
        req.user?.uid || null,
        disease,
        confidence,
        confidence_tier || deriveConfidenceTier(confidence),
        severity || null,
        crop_type || 'Unknown',
        lat || null,
        lng || null,
        timestamp ? new Date(timestamp) : new Date()
      ];

      const result = await pool.query(query, values);

      if (confidence < 0.75 && image_base64) {
        plantIdService.analyzeImage(image_base64).catch(console.error);
      }

      res.status(201).json({
        success: true,
        message: 'Scan logged successfully',
        data: result.rows[0] || { scan_id }
      });
    } catch (error) {
      console.error('Log diagnosis error:', error);
      res.status(500).json({ error: 'Failed to log diagnosis' });
    }
  },

  async getHeatmap(req, res) {
    try {
      const { region, crop, days = 30 } = req.query;

      const daysInt = Math.min(Math.max(parseInt(days) || 30, 1), 365);
      const params = [daysInt];
      let paramIndex = 2;
      let filters = '';

      if (region) {
        filters += ` AND region = $${paramIndex++}`;
        params.push(region);
      }
      if (crop) {
        filters += ` AND crop_type = $${paramIndex++}`;
        params.push(crop);
      }

      const query = `
        SELECT 
          latitude, longitude, disease_name, crop_type,
          COUNT(*) as case_count,
          AVG(confidence) as avg_confidence
        FROM scans
        WHERE scanned_at >= NOW() - ($1 * INTERVAL '1 day')
        ${filters}
        GROUP BY latitude, longitude, disease_name, crop_type
        HAVING COUNT(*) >= 3
        ORDER BY case_count DESC
      `;

      const result = await pool.query(query, params);

      res.json({
        success: true,
        count: result.rows.length,
        data: result.rows
      });
    } catch (error) {
      console.error('Heatmap error:', error);
      res.status(500).json({ error: 'Failed to fetch heatmap data' });
    }
  },

  async submitFeedback(req, res) {
    try {
      const { scan_id, was_correct, correct_disease } = req.body;

      if (!scan_id || was_correct === undefined) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      const query = `
        INSERT INTO feedback (scan_id, user_id, was_correct, correct_disease, submitted_at)
        VALUES ($1, $2, $3, $4, NOW())
        RETURNING *;
      `;

      const values = [scan_id, req.user?.uid || null, was_correct, correct_disease || null];
      const result = await pool.query(query, values);

      res.status(201).json({
        success: true,
        message: 'Feedback recorded',
        data: result.rows[0]
      });
    } catch (error) {
      console.error('Feedback error:', error);
      res.status(500).json({ error: 'Failed to submit feedback' });
    }
  },

  async getRegionalStats(req, res) {
    try {
      const { county, days = 30 } = req.query;

      const daysInt = Math.min(Math.max(parseInt(days) || 30, 1), 365);
      const params = [daysInt];
      let countyFilter = '';
      if (county) {
        countyFilter = 'AND region = $2';
        params.push(county);
      }

      const query = `
        SELECT 
          disease_name, crop_type,
          COUNT(*) as total_cases,
          ROUND(AVG(confidence)::numeric, 2) as avg_confidence,
          COUNT(DISTINCT user_id) as affected_farmers
        FROM scans
        WHERE scanned_at >= NOW() - ($1 * INTERVAL '1 day')
        ${countyFilter}
        GROUP BY disease_name, crop_type
        ORDER BY total_cases DESC
        LIMIT 20;
      `;

      const result = await pool.query(query, params);
      res.json({ success: true, data: result.rows });
    } catch (error) {
      console.error('Stats error:', error);
      res.status(500).json({ error: 'Failed to fetch statistics' });
    }
  }
};

function deriveConfidenceTier(confidence) {
  const value = Number(confidence);
  if (value >= 0.75) return 'high';
  if (value >= 0.40) return 'uncertain';
  return 'low';
}

module.exports = diagnoseController;
