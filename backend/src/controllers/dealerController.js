const locationService = require('../services/locationService');
const pool = require('../services/db');

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
              cos(radians($1)) * cos(radians(latitude)) *
              cos(radians(longitude) - radians($2)) +
              sin(radians($1)) * sin(radians(latitude))
            )
          ) AS distance_km
        FROM agro_dealers
        WHERE is_active = true
        HAVING (
          6371 * acos(
            cos(radians($1)) * cos(radians(latitude)) *
            cos(radians(longitude) - radians($2)) +
            sin(radians($1)) * sin(radians(latitude))
          )
        ) <= $3
        ORDER BY distance_km ASC, is_sponsored DESC
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
      res.status(500).json({ error: 'Failed to fetch dealers' });
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
