const pool = require('../services/db');

const farmerController = {
  async getProfile(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const result = await pool.query(
        'SELECT * FROM farmer_profiles WHERE user_id = $1',
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Farmer profile not found' });
      }

      res.json({ success: true, profile: result.rows[0] });
    } catch (error) {
      console.error('Get farmer profile error:', error);
      res.status(500).json({ error: 'Failed to fetch farmer profile' });
    }
  },

  async upsertProfile(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const {
        full_name,
        county,
        sub_county,
        ward,
        farm_size_hectares,
        primary_crops,
        farming_experience_years,
        phone_number,
        profile_photo_url,
      } = req.body;

      const result = await pool.query(
        `INSERT INTO farmer_profiles (user_id, full_name, county, sub_county, ward, farm_size_hectares, primary_crops, farming_experience_years, phone_number, profile_photo_url, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
         ON CONFLICT (user_id) 
         DO UPDATE SET 
           full_name = EXCLUDED.full_name,
           county = EXCLUDED.county,
           sub_county = EXCLUDED.sub_county,
           ward = EXCLUDED.ward,
           farm_size_hectares = EXCLUDED.farm_size_hectares,
           primary_crops = EXCLUDED.primary_crops,
           farming_experience_years = EXCLUDED.farming_experience_years,
           phone_number = EXCLUDED.phone_number,
           profile_photo_url = EXCLUDED.profile_photo_url,
           updated_at = NOW()
         RETURNING *`,
        [userId, full_name, county, sub_county, ward, farm_size_hectares, primary_crops || [], farming_experience_years, phone_number, profile_photo_url]
      );

      res.json({ success: true, profile: result.rows[0] });
    } catch (error) {
      console.error('Upsert farmer profile error:', error);
      res.status(500).json({ error: 'Failed to save farmer profile' });
    }
  },

  async getFarms(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const profileResult = await pool.query(
        'SELECT id FROM farmer_profiles WHERE user_id = $1',
        [userId]
      );

      if (profileResult.rows.length === 0) {
        return res.json({ success: true, farms: [] });
      }

      const farmerProfileId = profileResult.rows[0].id;
      const result = await pool.query(
        'SELECT * FROM plots WHERE farmer_profile_id = $1 ORDER BY created_at DESC',
        [farmerProfileId]
      );

      res.json({ success: true, farms: result.rows });
    } catch (error) {
      console.error('Get farms error:', error);
      res.status(500).json({ error: 'Failed to fetch farms' });
    }
  },

  async createFarm(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { name, crop_type, county, latitude, longitude, area_hectares, planted_at, notes } = req.body;

      const profileResult = await pool.query(
        'SELECT id FROM farmer_profiles WHERE user_id = $1',
        [userId]
      );

      if (profileResult.rows.length === 0) {
        return res.status(404).json({ error: 'Farmer profile not found. Create profile first.' });
      }

      const farmerProfileId = profileResult.rows[0].id;
      const result = await pool.query(
        `INSERT INTO plots (user_id, farmer_profile_id, name, crop_type, county, latitude, longitude, area_hectares, planted_at, notes, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
         RETURNING *`,
        [userId, farmerProfileId, name, crop_type, county, latitude, longitude, area_hectares, planted_at, notes]
      );

      res.status(201).json({ success: true, farm: result.rows[0] });
    } catch (error) {
      console.error('Create farm error:', error);
      res.status(500).json({ error: 'Failed to create farm' });
    }
  },

  async updateFarm(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const updates = req.body;
      const setClause = [];
      const values = [];
      let index = 1;

      const allowedFields = ['name', 'crop_type', 'county', 'latitude', 'longitude', 'area_hectares', 'planted_at', 'notes'];
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

      values.push(id, userId);
      const query = `UPDATE plots SET ${setClause.join(', ')}, updated_at = NOW() WHERE id = $${index} AND user_id = $${index + 1} RETURNING *`;
      const result = await pool.query(query, values);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Farm not found' });
      }

      res.json({ success: true, farm: result.rows[0] });
    } catch (error) {
      console.error('Update farm error:', error);
      res.status(500).json({ error: 'Failed to update farm' });
    }
  },

  async deleteFarm(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { id } = req.params;
      const result = await pool.query(
        'DELETE FROM plots WHERE id = $1 AND user_id = $2 RETURNING id',
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Farm not found' });
      }

      res.json({ success: true, message: 'Farm deleted successfully' });
    } catch (error) {
      console.error('Delete farm error:', error);
      res.status(500).json({ error: 'Failed to delete farm' });
    }
  },

  async getCrops(req, res) {
    try {
      const result = await pool.query(
        'SELECT DISTINCT crop_type FROM plots WHERE crop_type IS NOT NULL ORDER BY crop_type'
      );
      const crops = result.rows.map(row => row.crop_type);
      res.json({ success: true, crops });
    } catch (error) {
      console.error('Get crops error:', error);
      res.status(500).json({ error: 'Failed to fetch crops' });
    }
  },

  async addCrop(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { crop_type } = req.body;
      if (!crop_type) {
        return res.status(400).json({ error: 'Crop type is required' });
      }

      const profileResult = await pool.query(
        'SELECT id, primary_crops FROM farmer_profiles WHERE user_id = $1',
        [userId]
      );

      if (profileResult.rows.length === 0) {
        return res.status(404).json({ error: 'Farmer profile not found' });
      }

      const profile = profileResult.rows[0];
      const currentCrops = profile.primary_crops || [];
      if (!currentCrops.includes(crop_type)) {
        currentCrops.push(crop_type);
      }

      await pool.query(
        'UPDATE farmer_profiles SET primary_crops = $1, updated_at = NOW() WHERE user_id = $2',
        [currentCrops, userId]
      );

      res.json({ success: true, crops: currentCrops });
    } catch (error) {
      console.error('Add crop error:', error);
      res.status(500).json({ error: 'Failed to add crop' });
    }
  },

  async getDashboard(req, res) {
    try {
      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const [profileResult, farmsResult, scansResult] = await Promise.all([
        pool.query('SELECT * FROM farmer_profiles WHERE user_id = $1', [userId]),
        pool.query(
          `SELECT p.* FROM plots p
           JOIN farmer_profiles fp ON p.farmer_profile_id = fp.id
           WHERE fp.user_id = $1
           ORDER BY p.created_at DESC LIMIT 5`,
          [userId]
        ),
        pool.query(
          'SELECT * FROM scans WHERE user_id = $1 ORDER BY scanned_at DESC LIMIT 5',
          [userId]
        ),
      ]);

      res.json({
        success: true,
        profile: profileResult.rows[0] || null,
        farms: farmsResult.rows,
        recentScans: scansResult.rows,
      });
    } catch (error) {
      console.error('Get dashboard error:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard data' });
    }
  },
};

module.exports = farmerController;
