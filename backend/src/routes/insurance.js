const express = require('express');
const router = express.Router();
const insuranceController = require('../controllers/insuranceController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/providers', optionalAuth, insuranceController.listProviders);
router.get('/providers/nearby', optionalAuth, insuranceController.getNearbyProviders);
router.get('/providers/:id', optionalAuth, insuranceController.getProvider);
router.get('/providers/:id/products', optionalAuth, insuranceController.getProducts);
router.post('/providers/:id/inquire', verifyFirebaseToken, insuranceController.submitInquiry);
router.post('/claims', verifyFirebaseToken, insuranceController.submitClaimInquiry);

module.exports = router;
