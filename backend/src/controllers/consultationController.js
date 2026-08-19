const pool = require('../services/db');

const consultationController = {
  async listConsultations(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { status, type } = req.query;
      const conditions = ['(farmer_id = $1 OR agronomist_id = $1 OR government_officer_id = $1)'];
      const params = [userId];
      let idx = 2;

      if (status) {
        conditions.push(`status = $${idx}`);
        params.push(status);
        idx++;
      }
      if (type) {
        conditions.push(`consultation_type = $${idx}`);
        params.push(type);
        idx++;
      }

      const query = `SELECT * FROM consultations WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, consultations: result.rows });
    } catch (error) {
      console.error('List consultations error:', error);
      res.status(500).json({ error: 'Failed to fetch consultations' });
    }
  },

  async getConsultation(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;

      const result = await pool.query(
        `SELECT * FROM consultations WHERE id = $1 AND (farmer_id = $2 OR agronomist_id = $2 OR government_officer_id = $2)`,
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Consultation not found' });
      }

      const messagesResult = await pool.query(
        'SELECT * FROM messages WHERE consultation_id = $1 ORDER BY created_at ASC',
        [id]
      );

      res.json({ success: true, consultation: result.rows[0], messages: messagesResult.rows });
    } catch (error) {
      console.error('Get consultation error:', error);
      res.status(500).json({ error: 'Failed to fetch consultation' });
    }
  },

  async createConsultation(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { agronomist_id, government_officer_id, consultation_type, farmer_message, scan_id, scheduled_at } = req.body;

      const result = await pool.query(
        `INSERT INTO consultations (scan_id, farmer_id, agronomist_id, government_officer_id, consultation_type, status, farmer_message, scheduled_at, created_at)
         VALUES ($1, $2, $3, $4, $5, 'pending', $6, $7, NOW())
         RETURNING *`,
        [scan_id || null, userId, agronomist_id || null, government_officer_id || null, consultation_type || 'chat', farmer_message, scheduled_at || null]
      );

      res.status(201).json({ success: true, consultation: result.rows[0] });
    } catch (error) {
      console.error('Create consultation error:', error);
      res.status(500).json({ error: 'Failed to create consultation' });
    }
  },

  async updateStatus(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { status } = req.body;

      if (!['accepted', 'in_progress', 'completed', 'cancelled'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
      }

      const result = await pool.query(
        `UPDATE consultations SET status = $1, updated_at = NOW() WHERE id = $2 AND (farmer_id = $3 OR agronomist_id = $3 OR government_officer_id = $3) RETURNING *`,
        [status, id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Consultation not found' });
      }

      res.json({ success: true, consultation: result.rows[0] });
    } catch (error) {
      console.error('Update consultation status error:', error);
      res.status(500).json({ error: 'Failed to update consultation' });
    }
  },

  async addMessage(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { content, message_type, receiver_id } = req.body;

      const consultation = await pool.query(
        'SELECT farmer_id, agronomist_id, government_officer_id FROM consultations WHERE id = $1',
        [id]
      );

      if (consultation.rows.length === 0) {
        return res.status(404).json({ error: 'Consultation not found' });
      }

      const c = consultation.rows[0];
      if (![c.farmer_id, c.agronomist_id, c.government_officer_id].includes(userId)) {
        return res.status(403).json({ error: 'Access denied' });
      }

      const result = await pool.query(
        `INSERT INTO messages (consultation_id, sender_id, receiver_id, message_type, content, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING *`,
        [id, userId, receiver_id || c.farmer_id, message_type || 'text', content]
      );

      res.status(201).json({ success: true, message: result.rows[0] });
    } catch (error) {
      console.error('Add message error:', error);
      res.status(500).json({ error: 'Failed to add message' });
    }
  },

  async completeConsultation(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;
      const { agronomist_diagnosis, agronomist_advice } = req.body;

      const result = await pool.query(
        `UPDATE consultations SET status = 'completed', agronomist_diagnosis = $1, agronomist_advice = $2, completed_at = NOW(), updated_at = NOW()
         WHERE id = $3 AND (farmer_id = $4 OR agronomist_id = $4) RETURNING *`,
        [agronomist_diagnosis || null, agronomist_advice || null, id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Consultation not found' });
      }

      res.json({ success: true, consultation: result.rows[0] });
    } catch (error) {
      console.error('Complete consultation error:', error);
      res.status(500).json({ error: 'Failed to complete consultation' });
    }
  },
};

module.exports = consultationController;
