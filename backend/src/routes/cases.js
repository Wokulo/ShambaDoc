const express = require('express');
const router = express.Router();
const caseController = require('../controllers/caseController');
const { verifyFirebaseToken, optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, caseController.listCases);
router.get('/:id', optionalAuth, caseController.getCase);
router.post('/', verifyFirebaseToken, caseController.createCase);
router.put('/:id/assign', verifyFirebaseToken, caseController.assignCase);
router.put('/:id/resolve', verifyFirebaseToken, caseController.resolveCase);
router.post('/:id/escalate', verifyFirebaseToken, caseController.escalateCase);

module.exports = router;
