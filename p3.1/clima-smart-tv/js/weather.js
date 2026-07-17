// js/weather.js
// NOTA DE SEGURIDAD: En produccion, la API key debe ir en un
// backend proxy (Node/Express) que reciba peticiones del cliente
// y haga la llamada a OpenWeatherMap sin exponer la key.
// Para esta practica academica la declaramos como constante
// y documentamos que el archivo NO se sube a GitHub.
// En produccion: reemplazar por llamada a /api/weather?city=X

const API_KEY = window.ENV_API_KEY || 'TU_API_KEY_AQUI';
const BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
const CITIES = ['Queretaro', 'Ciudad de Mexico', 'Guadalajara', 'Monterrey'];

// Mapeo condicion -> archivo de video
const VIDEO_MAP = {
    Clear:       { video: '/assets/videos/clear.mp4',   poster: '/assets/posters/clear.jpg'   },
    Clouds:      { video: '/assets/videos/cloudy.mp4',  poster: '/assets/posters/cloudy.jpg'  },
    Rain:        { video: '/assets/videos/rain.mp4',    poster: '/assets/posters/rain.jpg'    },
    Drizzle:     { video: '/assets/videos/rain.mp4',    poster: '/assets/posters/rain.jpg'    },
    Thunderstorm:{ video: '/assets/videos/thunder.mp4', poster: '/assets/posters/thunder.jpg' },
    Snow:        { video: '/assets/videos/cloudy.mp4',  poster: '/assets/posters/cloudy.jpg'  },
};

async function fetchWeather(city) {
    // Sanitizar entrada
    const clean = city.trim().replace(/[^\w\s]/g, '');
    if (!clean) throw new Error('Ciudad invalida');

    const url = `${BASE_URL}?q=${encodeURIComponent(clean)}&appid=${API_KEY}&units=metric&lang=es`;

    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) {
        if (res.status === 401) throw new Error('API key invalida');
        if (res.status === 404) throw new Error(`Ciudad '${city}' no encontrada`);
        throw new Error(`Error API: ${res.status}`);
    }

    const json = await res.json();

    // Validar estructura antes de usar
    if (!json.main || !json.weather?.[0]) {
        throw new Error('Respuesta de API inesperada');
    }

    return {
        city:        json.name,
        temperature: Math.round(json.main.temp),
        condition:   json.weather[0].main,
        description: json.weather[0].description,
        humidity:    json.main.humidity,
        windSpeed:   json.wind?.speed?.toFixed(1) ?? '0',
    };
}

async function fetchAllCities() {
    // Si no hay conexión, lanzar error inmediatamente
    if (!navigator.onLine) {
        throw new Error('Sin conexión a internet');
    }

    const results = await Promise.allSettled(
        CITIES.map(city => fetchWeather(city))
    );

    const data = results.map((r, i) =>
        r.status === 'fulfilled'
        ? r.value
        : { city: CITIES[i], temperature: '--', condition: 'Error',
            description: 'Sin datos', humidity: '--', windSpeed: '--' }
    );

    // Si TODOS fallaron, lanzar error para ir al cache
    const allFailed = data.every(d => d.condition === 'Error');
    if (allFailed) throw new Error('No se pudo obtener datos de la API');

    return data;
}