const pool = require('../services/db');

const messageController = {
  async listConversations(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const query = `
        SELECT DISTINCT
          CASE WHEN sender_id = $1 THEN receiver_id ELSE sender_id END as other_user_id,
          MAX(created_at) as last_message_at,
          COUNT(*) FILTER (WHERE receiver_id = $1 AND is_read = false) as unread_count
        FROM messages
        WHERE sender_id = $1 OR receiver_id = $1
        GROUP BY other_user_id
        ORDER BY last_message_at DESC
        LIMIT 50
      `;

      const result = await pool.query(query, [userId]);
      res.json({ success: true, conversations: result.rows });
    } catch (error) {
      console.error('List conversations error:', error);
      res.status(500).json({ error: 'Failed to fetch conversations' });
    }
  },

  async getConversation(req, res) {
    try {
      const userId = req.user?.uid;
      const { otherUserId } = req.params;

      await pool.query(
        'UPDATE messages SET is_read = true, read_at = NOW() WHERE sender_id = $1 AND receiver_id = $2 AND is_read = false',
        [otherUserId, userId]
      );

      const result = await pool.query(
        `SELECT * FROM messages
         WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1)
         ORDER BY created_at ASC
         LIMIT 200`,
        [userId, otherUserId]
      );

      res.json({ success: true, messages: result.rows });
    } catch (error) {
      console.error('Get conversation error:', error);
      res.status(500).json({ error: 'Failed to fetch conversation' });
    }
  },

  async sendMessage(req, res) {
    try {
      const userId = req.user?.uid;
      const { receiver_id, content, message_type, consultation_id } = req.body;

      if (!receiver_id || !content) {
        return res.status(400).json({ error: 'Receiver and content are required' });
      }

      const result = await pool.query(
        `INSERT INTO messages (consultation_id, sender_id, receiver_id, message_type, content, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING *`,
        [consultation_id || null, userId, receiver_id, message_type || 'text', content]
      );

      res.status(201).json({ success: true, message: result.rows[0] });
    } catch (error) {
      console.error('Send message error:', error);
      res.status(500).json({ error: 'Failed to send message' });
    }
  },

  async markAsRead(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;

      await pool.query(
        'UPDATE messages SET is_read = true, read_at = NOW() WHERE id = $1 AND receiver_id = $2',
        [id, userId]
      );

      res.json({ success: true });
    } catch (error) {
      console.error('Mark as read error:', error);
      res.status(500).json({ error: 'Failed to mark message as read' });
    }
  },
};

module.exports = messageController;
