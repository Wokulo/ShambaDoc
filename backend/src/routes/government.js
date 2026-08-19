const express = require('express');
const router = express.Router();
const governmentController = require('../controllers/governmentController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/officers', optionalAuth, governmentController.listOfficers);
router.get('/officers/nearby', optionalAuth, governmentController.getNearbyOfficers);
router.get('/officers/:id', optionalAuth, governmentController.getOfficer);
router.post('/officers/:id/request', verifyFirebaseToken, governmentController.requestSupport);
router.get('/advisories', optionalAuth, governmentController.getAdvisories);
router.get('/programs', optionalAuth, governmentController.getPrograms);
router.get('/events', optionalAuth, governmentController.getEvents);
router.post('/outbreaks', verifyFirebaseToken, governmentController.reportOutbreak);

module.exports = router;
