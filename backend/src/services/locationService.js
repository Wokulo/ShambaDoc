const axios = require('axios');

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

const locationService = {
  async geocodeAddress(address) {
    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        {
          params: {
            address: address,
            key: GOOGLE_MAPS_API_KEY,
            region: 'ke',
          },
          timeout: 10000,
        }
      );

      if (response.data.status === 'OK' && response.data.results.length > 0) {
        const location = response.data.results[0].geometry.location;
        return {
          lat: location.lat,
          lng: location.lng,
          formatted_address: response.data.results[0].formatted_address,
        };
      }

      return null;
    } catch (error) {
      console.error('Geocoding error:', error.message);
      return null;
    }
  },

  async reverseGeocode(lat, lng) {
    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        {
          params: {
            latlng: `${lat},${lng}`,
            key: GOOGLE_MAPS_API_KEY,
          },
          timeout: 10000,
        }
      );

      if (response.data.status === 'OK' && response.data.results.length > 0) {
        const result = response.data.results[0];
        let county = null;
        let country = null;

        for (const component of result.address_components) {
          if (component.types.includes('administrative_area_level_2')) {
            county = component.long_name;
          }
          if (component.types.includes('country')) {
            country = component.long_name;
          }
        }

        return {
          formatted_address: result.formatted_address,
          county,
          country,
        };
      }

      return null;
    } catch (error) {
      console.error('Reverse geocoding error:', error.message);
      return null;
    }
  }
};

module.exports = locationService;
