const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyFirebaseToken } = require('../middleware/auth');

router.get('/verifications', verifyFirebaseToken, adminController.listVerificationRequests);
router.put('/verifications/:id', verifyFirebaseToken, adminController.reviewVerification);
router.get('/users', verifyFirebaseToken, adminController.listUsers);
router.put('/users/:id/role', verifyFirebaseToken, adminController.updateUserRole);
router.get('/reports/scans', verifyFirebaseToken, adminController.getScanReports);
router.get('/reports/providers', verifyFirebaseToken, adminController.getProviderReports);
router.post('/advisories', verifyFirebaseToken, adminController.createAdvisory);
router.put('/advisories/:id', verifyFirebaseToken, adminController.updateAdvisory);
router.delete('/advisories/:id', verifyFirebaseToken, adminController.deleteAdvisory);

module.exports = router;
