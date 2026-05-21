const express = require('express');
const router = express.Router();
const diagnoseController = require('../controllers/diagnoseController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.post('/log', optionalAuth, diagnoseController.logDiagnosis);
router.get('/heatmap', verifyFirebaseToken, diagnoseController.getHeatmap);
router.post('/feedback', optionalAuth, diagnoseController.submitFeedback);
router.get('/stats', diagnoseController.getRegionalStats);

module.exports = router;
