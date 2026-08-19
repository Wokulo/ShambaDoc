const express = require('express');
const router = express.Router();
const searchController = require('../controllers/searchController');
const { optionalAuth } = require('../middleware/auth');

router.get('/services', optionalAuth, searchController.searchServices);
router.get('/diseases', optionalAuth, searchController.searchDiseases);
router.get('/crops', optionalAuth, searchController.searchCrops);
router.get('/events', optionalAuth, searchController.searchEvents);

module.exports = router;
