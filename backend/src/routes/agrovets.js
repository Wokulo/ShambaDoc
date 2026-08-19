const express = require('express');
const router = express.Router();
const agrovetController = require('../controllers/agrovetController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, agrovetController.listAgrovets);
router.get('/nearby', optionalAuth, agrovetController.getNearby);
router.get('/:id', optionalAuth, agrovetController.getAgrovet);
router.get('/:id/products', optionalAuth, agrovetController.getProducts);
router.post('/:id/inquire', verifyFirebaseToken, agrovetController.submitInquiry);
router.post('/:id/review', verifyFirebaseToken, agrovetController.submitReview);

module.exports = router;
