const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const { verifyFirebaseToken } = require('../middleware/auth');

router.get('/conversations', verifyFirebaseToken, messageController.listConversations);
router.get('/conversations/:otherUserId', verifyFirebaseToken, messageController.getConversation);
router.post('/send', verifyFirebaseToken, messageController.sendMessage);
router.put('/:id/read', verifyFirebaseToken, messageController.markAsRead);

module.exports = router;
