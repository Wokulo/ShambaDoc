const express = require('express');
const router = express.Router();
const consultationController = require('../controllers/consultationController');
const { verifyFirebaseToken } = require('../middleware/auth');

router.get('/', verifyFirebaseToken, consultationController.listConsultations);
router.get('/:id', verifyFirebaseToken, consultationController.getConsultation);
router.post('/', verifyFirebaseToken, consultationController.createConsultation);
router.put('/:id/status', verifyFirebaseToken, consultationController.updateStatus);
router.post('/:id/message', verifyFirebaseToken, consultationController.addMessage);
router.post('/:id/complete', verifyFirebaseToken, consultationController.completeConsultation);

module.exports = router;
