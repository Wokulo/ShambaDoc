const express = require('express');
const router = express.Router();
const dealerController = require('../controllers/dealerController');
const { verifyFirebaseToken } = require('../middleware/auth');

router.get('/', dealerController.getNearbyDealers);
router.get('/:id', dealerController.getDealerById);
router.post('/', verifyFirebaseToken, dealerController.registerDealer);
router.put('/:id', verifyFirebaseToken, dealerController.updateDealer);

module.exports = router;
