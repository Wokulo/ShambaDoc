const express = require('express');
const router = express.Router();
const agronomistController = require('../controllers/agronomistController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, agronomistController.listAgronomists);
router.get('/nearby', optionalAuth, agronomistController.getNearby);
router.get('/:id', optionalAuth, agronomistController.getAgronomist);
router.post('/:id/consult', verifyFirebaseToken, agronomistController.requestConsultation);
router.post('/:id/review', verifyFirebaseToken, agronomistController.submitReview);

module.exports = router;
