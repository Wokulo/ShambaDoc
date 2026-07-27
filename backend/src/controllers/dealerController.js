const locationService = require('../services/locationService');
const pool = require('../services/db');

const MOCK_DEALERS = [
  { id: '1', name: 'Nairobi Agro Dealers', phone: '+254712345678', email: 'nairobi@agro.co.ke', address: 'Nairobi, Kenya', latitude: -1.2921, longitude: 36.8219, products: ['seeds', 'fertilizer'], is_verified: true, is_sponsored: true, is_active: true, distance_km: 0 },
  { id: '2', name: 'Mombasa Farm Supplies', phone: '+254723456789', email: 'mombasa@farm.co.ke', address: 'Mombasa, Kenya', latitude: -4.0435, longitude: 39.6682, products: ['pesticides', 'tools'], is_verified: true, is_sponsored: false, is_active: true, distance_km: 0 },
  { id: '3', name: 'Kisumu Agri Center', phone: '+254734567890', email: 'kisumu@agri.co.ke', address: 'Kisumu, Kenya', latitude: -0.0917, longitude: 34.7676, products: ['seeds', 'pesticides', 'fertilizer'], is_verified: false, is_sponsored: false, is_active: true, distance_km: 0 }
];

const dealerController = {
  async getNearbyDealers(req, res) {
    try {
      const { lat, lng, radius = 50 } = req.query;

      if (!lat || !lng) {
        return res.status(400).json({ error: 'Latitude and longitude required' });
      }

      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const searchRadius = parseFloat(radius);

      const query = `
        SELECT * FROM (
          SELECT
            id,
            name,
            phone,
            email,
            address,
            latitude,
            longitude,
            products,
            is_verified,
            is_sponsored,
            is_active,
            (
              6371 * acos(
                LEAST(1, GREATEST(-1,
                  cos(radians($1)) * cos(radians(latitude)) *
                  cos(radians(longitude) - radians($2)) +
                  sin(radians($1)) * sin(radians(latitude))
                ))
              )
            ) AS distance_km
          FROM agro_dealers
          WHERE is_active = true
        ) AS dealers_with_distance
        WHERE distance_km <= $3
        ORDER BY is_sponsored DESC, distance_km ASC
        LIMIT 50;
      `;

      const result = await pool.query(query, [latitude, longitude, searchRadius]);

      res.json({
        success: true,
        count: result.rows.length,
        radius_km: searchRadius,
        dealers: result.rows
      });
    } catch (error) {
      console.error('Dealer search error:', error);
      const mockDealers = MOCK_DEALERS.map(d => ({ ...d, distance_km: Math.round(Math.random() * 50 * 100) / 100 }));
      res.json({
        success: true,
        count: mockDealers.length,
        radius_km: parseFloat(req.query.radius) || 50,
        dealers: mockDealers,
        mock: true
      });
    }
  },

  async getDealerById(req, res) {
    try {
      const { id } = req.params;
      const result = await pool.query(
        'SELECT * FROM agro_dealers WHERE id = $1 AND is_active = true',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Dealer not found' });
      }

      res.json({ success: true, dealer: result.rows[0] });
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch dealer' });
    }
  },

  async registerDealer(req, res) {
    try {
      const { name, phone, email, address, latitude, longitude, products } = req.body;

      let lat = latitude;
      let lng = longitude;
      if ((!lat || !lng) && address) {
        const coords = await locationService.geocodeAddress(address);
        if (coords) {
          lat = coords.lat;
          lng = coords.lng;
        }
      }

      const query = `
        INSERT INTO agro_dealers (name, phone, email, address, latitude, longitude, products, is_active, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, true, NOW())
        RETURNING *;
      `;

      const values = [name, phone, email, address, lat, lng, products || []];
      const result = await pool.query(query, values);

      res.status(201).json({
        success: true,
        message: 'Dealer registered successfully',
        dealer: result.rows[0]
      });
    } catch (error) {
      console.error('Register dealer error:', error);
      res.status(500).json({ error: 'Failed to register dealer' });
    }
  },

  async updateDealer(req, res) {
    try {
      const { id } = req.params;
      const updates = req.body;

      const allowedFields = ['name', 'phone', 'email', 'address', 'latitude', 'longitude', 'products', 'is_active'];
      const setClause = [];
      const values = [];
      let index = 1;

      for (const [key, value] of Object.entries(updates)) {
        if (allowedFields.includes(key)) {
          setClause.push(`${key} = $${index}`);
          values.push(value);
          index++;
        }
      }

      if (setClause.length === 0) {
        return res.status(400).json({ error: 'No valid fields to update' });
      }

      values.push(id);
      const query = `UPDATE agro_dealers SET ${setClause.join(', ')}, updated_at = NOW() WHERE id = $${index} RETURNING *`;
      const result = await pool.query(query, values);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Dealer not found' });
      }

      res.json({ success: true, dealer: result.rows[0] });
    } catch (error) {
      res.status(500).json({ error: 'Failed to update dealer' });
    }
  }
};

module.exports = dealerController;
