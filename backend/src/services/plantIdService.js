const axios = require('axios');

const PLANT_ID_API_KEY = process.env.PLANT_ID_API_KEY;
const PLANT_ID_URL = 'https://api.plant.id/v2/health_assessment';

const plantIdService = {
  async analyzeImage(base64Image) {
    try {
      const response = await axios.post(
        PLANT_ID_URL,
        {
          api_key: PLANT_ID_API_KEY,
          images: [base64Image],
          modifiers: ['similar_images'],
          language: 'en',
          disease_details: ['description', 'treatment', 'classification'],
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000,
        }
      );

      if (response.data && response.data.health_assessment) {
        return {
          success: true,
          data: response.data.health_assessment,
        };
      }

      return { success: false, error: 'No assessment data returned' };
    } catch (error) {
      console.error('Plant.id API error:', error.response?.data || error.message);
      throw new Error('Plant.id analysis failed');
    }
  },

  async identifyPlant(base64Image) {
    try {
      const response = await axios.post(
        'https://api.plant.id/v2/identify',
        {
          api_key: PLANT_ID_API_KEY,
          images: [base64Image],
          modifiers: ['similar_images'],
          plant_details: ['common_names', 'url', 'wiki_description', 'taxonomy'],
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000,
        }
      );

      return response.data;
    } catch (error) {
      console.error('Plant identification error:', error.message);
      throw error;
    }
  }
};

module.exports = plantIdService;
