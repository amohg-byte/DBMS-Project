require('dotenv').config();
const axios = require('axios');

const API_KEY = process.env.TOMTOM_API_KEY;

// City center coordinates to use as base points for random offset querying
const CITY_COORDS = {
    'Mumbai': { lat: 19.0760, lon: 72.8777 },
    'Delhi': { lat: 28.7041, lon: 77.1025 },
    'Bangalore': { lat: 12.9716, lon: 77.5946 },
    'Hyderabad': { lat: 17.3850, lon: 78.4867 },
    'Chennai': { lat: 13.0827, lon: 80.2707 },
    'Kolkata': { lat: 22.5726, lon: 88.3639 },
    // Added Pune support
    'Pune' : { lat: 18.5204, lon: 73.8567 }
    'Ahmedabad': { lat: 23.0225, lon: 72.5714 }
};

// Generate a random coordinate within ~5km of the city center
function getRandomCoordinate(baseLat, baseLon) {
    const latOffset = (Math.random() - 0.5) * 0.09; // Roughly ~5km
    const lonOffset = (Math.random() - 0.5) * 0.09;
    return {
        lat: (baseLat + latOffset).toFixed(5),
        lon: (baseLon + lonOffset).toFixed(5)
    };
}

async function getLiveTrafficForCity(cityName) {
    if (!API_KEY) {
        console.warn('⚠️ No TOMTOM_API_KEY found, returning fallback data.');
        return null; // Fallback to synthetic if no key
    }

    const baseCoords = CITY_COORDS[cityName];
    if (!baseCoords) return null; // Only fetch for supported top cities

    const { lat, lon } = getRandomCoordinate(baseCoords.lat, baseCoords.lon);
    const url = `https://api.tomtom.com/traffic/services/4/flowSegmentData/relative0/10/json?key=${API_KEY}&point=${lat},${lon}`;

    try {
        const { data } = await axios.get(url, { timeout: 5000 });
        if (data && data.flowSegmentData) {
            const { currentSpeed, freeFlowSpeed } = data.flowSegmentData;
            return {
                currentSpeed,
                freeFlowSpeed,
                fetchCoords: { lat, lon }
            };
        }
    } catch (err) {
        // Silently fail and fallback to synthetic if API hits rate limits or coordinate has no road
        return null; 
    }
    return null;
}

// Helper to calculate theoretical congestion from speed metric
function determineCongestion(current, freeFlow) {
    if (!freeFlow) return 'Low';
    const ratio = current / freeFlow;
    if (ratio > 0.8) return 'Low';
    if (ratio > 0.6) return 'Moderate';
    if (ratio > 0.3) return 'High';
    return 'Severe';
}

module.exports = {
    getLiveTrafficForCity,
    determineCongestion,
    CITY_COORDS
};
