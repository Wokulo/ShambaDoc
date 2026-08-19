const pool = require('../services/db');

const caseController = {
  async listCases(req, res) {
    try {
      const userId = req.user?.uid;
      const { status, assigned_to, my_cases } = req.query;
      const conditions = [];
      const params = [];
      let idx = 1;

      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      if (my_cases === 'true') {
        conditions.push('(user_id = $1 OR assigned_to = $1)');
        params.push(userId);
        idx++;
      } else {
        conditions.push('(user_id = $1 OR assigned_to = $1)');
        params.push(userId);
        idx++;
      }

      if (status) {
        conditions.push(`status = $${idx}`);
        params.push(status);
        idx++;
      }
      if (assigned_to) {
        conditions.push(`assigned_to = $${idx}`);
        params.push(assigned_to);
        idx++;
      }

      const query = `SELECT * FROM human_escalations WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, cases: result.rows });
    } catch (error) {
      console.error('List cases error:', error);
      res.status(500).json({ error: 'Failed to fetch cases' });
    }
  },

  async getCase(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;

      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const result = await pool.query(
        `SELECT * FROM human_escalations WHERE id = $1 AND (user_id = $2 OR assigned_to = $2)`,
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Case not found' });
      }

      res.json({ success: true, case: result.rows[0] });
    } catch (error) {
      console.error('Get case error:', error);
      res.status(500).json({ error: 'Failed to fetch case' });
    }
  },

  async createCase(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { scan_id, farmer_note } = req.body;

      const result = await pool.query(
        `INSERT INTO human_escalations (scan_id, user_id, status, farmer_note, created_at)
         VALUES ($1, $2, 'open', $3, NOW())
         RETURNING *`,
        [scan_id || null, userId, farmer_note || '']
      );

      res.status(201).json({ success: true, case: result.rows[0] });
    } catch (error) {
      console.error('Create case error:', error);
      res.status(500).json({ error: 'Failed to create case' });
    }
  },

  async assignCase(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { assigned_to } = req.body;

      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      if (!assigned_to) {
        return res.status(400).json({ error: 'assigned_to is required' });
      }

      const caseResult = await pool.query(
        'SELECT assigned_to, status FROM human_escalations WHERE id = $1',
        [id]
      );

      if (caseResult.rows.length === 0) {
        return res.status(404).json({ error: 'Case not found' });
      }

      const currentCase = caseResult.rows[0];
      if (currentCase.assigned_to && currentCase.assigned_to !== userId) {
        return res.status(403).json({ error: 'You are not authorized to reassign this case' });
      }

      const result = await pool.query(
        `UPDATE human_escalations SET assigned_to = $1, status = 'in_review', updated_at = NOW() WHERE id = $2 RETURNING *`,
        [assigned_to, id]
      );

      res.json({ success: true, case: result.rows[0] });
    } catch (error) {
      console.error('Assign case error:', error);
      res.status(500).json({ error: 'Failed to assign case' });
    }
  },

  async resolveCase(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { agronomist_diagnosis, agronomist_advice } = req.body;

      const result = await pool.query(
        `UPDATE human_escalations SET status = 'resolved', agronomist_diagnosis = $1, agronomist_advice = $2, resolved_at = NOW(), updated_at = NOW()
         WHERE id = $3 AND (user_id = $4 OR assigned_to = $4) RETURNING *`,
        [agronomist_diagnosis || null, agronomist_advice || null, id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Case not found' });
      }

      res.json({ success: true, case: result.rows[0] });
    } catch (error) {
      console.error('Resolve case error:', error);
      res.status(500).json({ error: 'Failed to resolve case' });
    }
  },

  async escalateCase(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { note } = req.body;

      const caseResult = await pool.query(
        'SELECT * FROM human_escalations WHERE id = $1 AND user_id = $2',
        [id, userId]
      );

      if (caseResult.rows.length === 0) {
        return res.status(404).json({ error: 'Case not found' });
      }

      const result = await pool.query(
        `UPDATE human_escalations SET status = 'open', farmer_note = farmer_note || E'\n--- Escalation ---\n' || $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
        [note || 'Case escalated by farmer', id]
      );

      res.json({ success: true, case: result.rows[0] });
    } catch (error) {
      console.error('Escalate case error:', error);
      res.status(500).json({ error: 'Failed to escalate case' });
    }
  },
};

module.exports = caseController;
