// js/app.js

// ── Reloj en tiempo real ───────────────────────────────────
function updateClock() {
    const now = new Date();
    document.getElementById('currentTime').textContent =
        now.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
}
setInterval(updateClock, 1000);
updateClock();

// ── Cambiar video de fondo segun condicion ─────────────────
function updateBackground(condition) {
    const map    = VIDEO_MAP[condition] || VIDEO_MAP['Clouds'];
    const video  = document.getElementById('bgVideo');
    const poster = document.getElementById('bgPoster');

    // Evitar cambiar si ya está ese video o poster
    if (poster.dataset.current === map.video) return;
    poster.dataset.current = map.video;

    // Limpiar handlers anteriores para evitar loops
    video.oncanplay = null;
    video.onerror   = null;

    // 1. Mostrar poster inmediatamente
    poster.src = map.poster;
    poster.style.transition = 'none';
    poster.style.opacity = '1';

    // 2. Ocultar video actual
    video.style.transition = 'opacity 0.3s ease';
    video.style.opacity = '0';

    // 3. Cargar nuevo video
    setTimeout(() => {
        video.querySelector('source[type="video/mp4"]').src = map.video;
        video.load();

        // Si el video falla, mantener el poster
        video.onerror = () => {
        console.warn('Video no disponible, usando poster:', map.poster);
        poster.style.opacity = '1';
        video.style.opacity  = '0';
        video.onerror = null;
        video.oncanplay = null;
        };

        // Cuando el video cargue, hacer transición
        video.oncanplay = () => {
        video.oncanplay = null; // ← evita loop infinito
        setTimeout(() => {
            video.play().catch(() => {
            poster.style.opacity = '1';
            video.style.opacity  = '0';
            });
            video.style.transition = 'opacity 0.8s ease';
            video.style.opacity    = '1';
            poster.style.transition = 'opacity 0.8s ease';
            poster.style.opacity   = '0';
        }, 1500);
        };
    }, 300);
}

// ── Renderizar tarjeta ─────────────────────────────────────
function renderCard(cardId, data) {
    const card = document.getElementById(cardId);
    card.querySelector('.city-name').textContent    = data.city;
    card.querySelector('.temperature').textContent  = `${data.temperature}°C`;
    card.querySelector('.condition').textContent    = data.description;
    card.querySelector('.details').textContent      =
        `Humedad: ${data.humidity}% | Viento: ${data.windSpeed} m/s`;
}

// ── Seleccionar ciudad con Enter ───────────────────────────
document.addEventListener('card-select', e => {
    const idx = parseInt(e.detail.cardId.replace('card', ''));
    if (window._weatherData?.[idx]) {
        const data = window._weatherData[idx];
        updateBackground(data.condition);
        document.getElementById('cityName').textContent = data.city;
    }
});

// ── Cargar datos al iniciar ────────────────────────────────
async function init() {
    // Cargar cache inmediatamente mientras espera la API
    const cached = localStorage.getItem('weatherCache');
    if (cached) {
        const cachedData = JSON.parse(cached);
        cachedData.forEach((d, i) => renderCard(`card${i}`, d));
        updateBackground(cachedData[0].condition);
        document.getElementById('cityName').textContent = cachedData[0].city;
    }

    try {
        const data = await fetchAllCities();
        // Verificar que los datos son válidos
        const hasData = data.some(d => d.temperature !== '--');
        if (!hasData) return; // Mantener el cache si no hay datos nuevos

        window._weatherData = data;
        localStorage.setItem('weatherCache', JSON.stringify(data));
        data.forEach((d, i) => renderCard(`card${i}`, d));
        updateBackground(data[0].condition);
        document.getElementById('cityName').textContent = data[0].city;
    } catch (err) {
        console.warn('Error API, usando cache:', err.message);
        if (!cached) {
        document.getElementById('cityName').textContent = 'Sin conexión';
        }
    }
}

// ── Registrar Service Worker ───────────────────────────────
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js')
        .then(reg => console.log('SW registrado:', reg.scope))
        .catch(err => console.error('SW error:', err));
}


init();

// Refrescar datos cada 10 minutos
setInterval(init, 10 * 60 * 1000);