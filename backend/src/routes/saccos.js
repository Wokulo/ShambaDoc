const express = require('express');
const router = express.Router();
const saccoController = require('../controllers/saccoController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, saccoController.listSaccos);
router.get('/nearby', optionalAuth, saccoController.getNearby);
router.get('/:id', optionalAuth, saccoController.getSacco);
router.get('/:id/products', optionalAuth, saccoController.getFinancialProducts);
router.post('/:id/inquire', verifyFirebaseToken, saccoController.submitInquiry);

module.exports = router;
