const express = require('express');
const router = express.Router();
const farmerController = require('../controllers/farmerController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/profile', optionalAuth, farmerController.getProfile);
router.put('/profile', verifyFirebaseToken, farmerController.upsertProfile);
router.get('/farms', optionalAuth, farmerController.getFarms);
router.post('/farms', verifyFirebaseToken, farmerController.createFarm);
router.put('/farms/:id', verifyFirebaseToken, farmerController.updateFarm);
router.delete('/farms/:id', verifyFirebaseToken, farmerController.deleteFarm);
router.get('/crops', optionalAuth, farmerController.getCrops);
router.post('/crops', verifyFirebaseToken, farmerController.addCrop);
router.get('/dashboard', optionalAuth, farmerController.getDashboard);

module.exports = router;
