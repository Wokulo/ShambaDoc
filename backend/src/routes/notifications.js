const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { verifyFirebaseToken } = require('../middleware/auth');

router.get('/', verifyFirebaseToken, notificationController.listNotifications);
router.put('/:id/read', verifyFirebaseToken, notificationController.markAsRead);
router.put('/read-all', verifyFirebaseToken, notificationController.markAllAsRead);
router.post('/', verifyFirebaseToken, notificationController.createNotification);

module.exports = router;
