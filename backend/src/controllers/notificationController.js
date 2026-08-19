const pool = require('../services/db');

const notificationController = {
  async listNotifications(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { unread_only, type } = req.query;
      const conditions = ['user_id = $1'];
      const params = [userId];
      let idx = 2;

      if (type) {
        conditions.push(`notification_type = $${idx}`);
        params.push(type);
        idx++;
      }
      if (unread_only !== undefined && unread_only === 'true') {
        conditions.push('is_read = false');
      }

      const query = `SELECT * FROM notifications WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC LIMIT 50`;
      const result = await pool.query(query, params);

      res.json({ success: true, count: result.rows.length, notifications: result.rows });
    } catch (error) {
      console.error('List notifications error:', error);
      res.status(500).json({ error: 'Failed to fetch notifications' });
    }
  },

  async markAsRead(req, res) {
    try {
      const userId = req.user?.uid;
      const { id } = req.params;

      const result = await pool.query(
        'UPDATE notifications SET is_read = true, read_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING *',
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Notification not found' });
      }

      res.json({ success: true, notification: result.rows[0] });
    } catch (error) {
      console.error('Mark as read error:', error);
      res.status(500).json({ error: 'Failed to mark notification as read' });
    }
  },

  async markAllAsRead(req, res) {
    try {
      const userId = req.user?.uid;
      await pool.query(
        'UPDATE notifications SET is_read = true, read_at = NOW() WHERE user_id = $1 AND is_read = false',
        [userId]
      );

      res.json({ success: true, message: 'All notifications marked as read' });
    } catch (error) {
      console.error('Mark all as read error:', error);
      res.status(500).json({ error: 'Failed to mark notifications as read' });
    }
  },

  async createNotification(req, res) {
    try {
      const userId = req.user?.uid;
      const { user_id, notification_type, title, body, data } = req.body;

      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      if (!user_id || !notification_type || !title || !body) {
        return res.status(400).json({ error: 'user_id, notification_type, title, and body are required' });
      }

      if (user_id !== userId) {
        return res.status(403).json({ error: 'You can only create notifications for yourself' });
      }

      const result = await pool.query(
        `INSERT INTO notifications (user_id, notification_type, title, body, data, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING *`,
        [user_id, notification_type, title, body, data || {}]
      );

      res.status(201).json({ success: true, notification: result.rows[0] });
    } catch (error) {
      console.error('Create notification error:', error);
      res.status(500).json({ error: 'Failed to create notification' });
    }
  },
};

module.exports = notificationController;
