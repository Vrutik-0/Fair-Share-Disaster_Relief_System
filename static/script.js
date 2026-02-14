// Validator functions
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function isValidPhone(phone) {
    // Must be 10 digits starting with 1-9
    const phoneRegex = /^[1-9][0-9]{9}$/;
    return phoneRegex.test(phone);
}

function showError(elementId, message) {
    const errorDiv = document.getElementById(elementId);
    if (errorDiv) {
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
    }
}

function hideError(elementId) {
    const errorDiv = document.getElementById(elementId);
    if (errorDiv) {
        errorDiv.textContent = '';
        errorDiv.style.display = 'none';
    }
}

function validateLoginForm(e) {
    e.preventDefault();
    let isValid = true;

    const email = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value.trim();

    // Validate email
    if (!email) {
        showError('emailError', 'Email is required');
        isValid = false;
    } else if (!isValidEmail(email)) {
        showError('emailError', 'Please enter a valid email address');
        isValid = false;
    } else {
        hideError('emailError');
    }

    // Validate password
    if (!password) {
        showError('passwordError', 'Password is required');
        isValid = false;
    } else {
        hideError('passwordError');
    }

    // Submit if valid
    if (isValid) {
        document.getElementById('loginForm').submit();
    }
}

function validateSignupForm(e) {
    e.preventDefault();
    let isValid = true;

    const name = document.getElementById('signupName').value.trim();
    const email = document.getElementById('signupEmail').value.trim();
    const phone = document.getElementById('signupPhone').value.trim();
    const role = document.getElementById('signupRole').value.trim();
    const password = document.getElementById('signupPassword').value.trim();

    // Validate name
    if (!name) {
        showError('nameError', 'Full name is required');
        isValid = false;
    } else if (name.length < 2) {
        showError('nameError', 'Name must be at least 2 characters');
        isValid = false;
    } else {
        hideError('nameError');
    }

    // Validate email
    if (!email) {
        showError('signupEmailError', 'Email is required');
        isValid = false;
    } else if (!isValidEmail(email)) {
        showError('signupEmailError', 'Please enter a valid email address');
        isValid = false;
    } else {
        hideError('signupEmailError');
    }

    // Validate phone
    if (!phone) {
        showError('phoneError', 'Phone number is required');
        isValid = false;
    } else if (!isValidPhone(phone)) {
        showError('phoneError', 'Phone must be 10 digits starting with 1-9 (e.g., 9876543210)');
        isValid = false;
    } else {
        hideError('phoneError');
    }

    // Validate role
    if (!role) {
        showError('roleError', 'Please select a role');
        isValid = false;
    } else {
        hideError('roleError');
    }

    // Validate password
    if (!password) {
        showError('signupPasswordError', 'Password is required');
        isValid = false;
    } else if (password.length < 6) {
        showError('signupPasswordError', 'Password must be at least 6 characters');
        isValid = false;
    } else {
        hideError('signupPasswordError');
    }

    // Submit if valid
    if (isValid) {
        document.getElementById('signupForm').submit();
    }
}


const totalPop = document.querySelector('input[name="total_population"]');
const injuredPop = document.querySelector('input[name="injured_population"]');
const preview = document.getElementById("urgencyPreview");

// Calculates and displays the Urgency Score
function updateUrgency() {
    const t = parseInt(totalPop?.value || 0);
    const i = parseInt(injuredPop?.value || 0);

    if (t === 0) {
        if (preview) preview.innerText = "Urgency Score: 0.00";
        return;
    }

    let score = (i / t) * 0.7 + (t / 1000) * 0.3;
    score = Math.min(score, 1).toFixed(2);

    if (preview) preview.innerText = `Urgency Score (auto): ${score}`;
}

if (totalPop && injuredPop) {
    totalPop.addEventListener("input", updateUrgency);
    injuredPop.addEventListener("input", updateUrgency);
}

// Tomtom
const TOMTOM_KEY = '1KePC88rQpaiVRKSJSwCzJmiQE18I29O';

// Map grid (0-1000) to Ahmedabad
function gridToLngLat(gridY, gridX) {
    const lat = 22.945 + (gridY * 0.15 / 1000);
    const lng = 72.495 + (gridX * 0.15 / 1000);
    return [lng, lat];
}

const DEPOT_LNGLAT = gridToLngLat(190, 500);
const GRID_BOUNDS = [gridToLngLat(0, 0), gridToLngLat(1000, 1000)];

let adminMap = null;
let campMarkers = [];
let routeLayerIds = [];

function getUrgencyColor(urgency) {
    if (urgency >= 0.7) return "red";
    if (urgency >= 0.4) return "orange";
    return "green";
}

function createCircleEl(color, size) {
    const el = document.createElement('div');
    el.style.cssText = `width:${size}px;height:${size}px;border-radius:50%;background:${color};border:2px solid ${color};opacity:0.9;cursor:pointer;`;
    return el;
}

function initAdminMap() {
    const mapElement = document.getElementById("admin-map");
    if (!mapElement || adminMap) return;

    adminMap = tt.map({
        key: TOMTOM_KEY,
        container: 'admin-map',
        center: gridToLngLat(500, 500),
        zoom: 10
    });

    adminMap.addControl(new tt.NavigationControl());

    // Depot marker
    const depotEl = createCircleEl('blue', 24);
    const depotPopup = new tt.Popup({ offset: 15 }).setHTML('<b>NGO / Warehouse</b><br>Depot');
    new tt.Marker({ element: depotEl })
        .setLngLat(DEPOT_LNGLAT)
        .setPopup(depotPopup)
        .addTo(adminMap);

    adminMap.on('load', () => {
        adminMap.fitBounds(GRID_BOUNDS, { padding: 40 });
        loadCampsOnAdminMap();
        loadTruckRoutes();
    });
}

async function loadCampsOnAdminMap() {
    if (!adminMap) return;

    try {
        const res = await fetch("/api/camps");
        const data = await res.json();

        // Clear old markers
        campMarkers.forEach(m => m.remove());
        campMarkers = [];

        data.camps.forEach(camp => {
            const color = getUrgencyColor(camp.urgency);
            const el = createCircleEl(color, 16);
            const pos = gridToLngLat(camp.lat, camp.lng);
            const popup = new tt.Popup({ offset: 10 }).setHTML(
                `<b>${camp.name}</b><br>Urgency: ${camp.urgency}<br>Position: (${camp.lat}, ${camp.lng})`
            );

            const marker = new tt.Marker({ element: el })
                .setLngLat(pos)
                .setPopup(popup)
                .addTo(adminMap);

            campMarkers.push(marker);
        });
    } catch (err) {
        console.error("Error loading camps:", err);
    }
}

// Fetch a real-road route between an array of [lng, lat] waypoints using TomTom Routing API
async function fetchRoadRoute(waypoints) {
    if (waypoints.length < 2) return waypoints;
    try {
        const locations = waypoints.map(p => `${p[1]},${p[0]}`).join(':');
        const url = `https://api.tomtom.com/routing/1/calculateRoute/${locations}/json?key=${TOMTOM_KEY}&travelMode=truck&routeType=fastest`;
        const res = await fetch(url);
        const data = await res.json();
        if (data.routes && data.routes.length > 0) {
            const points = data.routes[0].legs.flatMap(leg =>
                leg.points.map(p => [p.longitude, p.latitude])
            );
            return points;
        }
    } catch (err) {
        console.warn("TomTom routing failed, falling back to straight line:", err);
    }
    return waypoints;
}

async function loadTruckRoutes() {
    if (!adminMap) return;

    try {
        const res = await fetch("/api/truck-routes");
        const data = await res.json();

        const colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c"];

        // Remove old route layers
        routeLayerIds.forEach(id => {
            if (adminMap.getLayer(id)) adminMap.removeLayer(id);
            if (adminMap.getSource(id)) adminMap.removeSource(id);
        });
        routeLayerIds = [];

        console.log("Truck routes loaded:", data.routes.length, "routes");

        for (let idx = 0; idx < data.routes.length; idx++) {
            const route = data.routes[idx];
            const color = colors[idx % colors.length];
            const layerId = 'route-' + idx;

            console.log(`Route ${idx}: Truck ${route.truck_id}, ${route.camps.length} camps, ${route.edges.length} edges`);

            // Convert route_points from [gridY, gridX] to [lng, lat]
            let waypoints;
            if (route.route_points && route.route_points.length > 1) {
                waypoints = route.route_points.map(p => gridToLngLat(p[0], p[1]));
            } else {
                waypoints = [];
                route.edges.forEach(edge => {
                    if (waypoints.length === 0) waypoints.push(gridToLngLat(edge[0][0], edge[0][1]));
                    waypoints.push(gridToLngLat(edge[1][0], edge[1][1]));
                });
            }

            if (waypoints.length > 1) {
                // Get real road route from TomTom
                const roadCoords = await fetchRoadRoute(waypoints);

                adminMap.addSource(layerId, {
                    type: 'geojson',
                    data: {
                        type: 'Feature',
                        geometry: { type: 'LineString', coordinates: roadCoords }
                    }
                });

                adminMap.addLayer({
                    id: layerId,
                    type: 'line',
                    source: layerId,
                    paint: {
                        'line-color': color,
                        'line-width': 4,
                        'line-opacity': 0.8
                    }
                });

                routeLayerIds.push(layerId);
            }
        }
    } catch (err) {
        console.error("Error loading truck routes:", err);
    }
}

// Initialize admin map if element exists
if (document.getElementById("admin-map")) {
    initAdminMap();
    // Refresh camps every 5 seconds
    setInterval(loadCampsOnAdminMap, 5000);
}

function initGeneralMap() {
    const mapElement = document.getElementById("map");
    if (!mapElement) return;

    if (document.body.classList.contains('driver-page')) return;

    const map = tt.map({
        key: TOMTOM_KEY,
        container: 'map',
        center: gridToLngLat(500, 500),
        zoom: 10
    });

    map.addControl(new tt.NavigationControl());

    // Depot marker
    const depotEl = createCircleEl('blue', 24);
    new tt.Marker({ element: depotEl })
        .setLngLat(DEPOT_LNGLAT)
        .setPopup(new tt.Popup({ offset: 15 }).setHTML('<b>NGO / Warehouse</b>'))
        .addTo(map);

    map.on('load', () => {
        map.fitBounds(GRID_BOUNDS, { padding: 40 });

        // Load camps
        fetch("/api/camps")
            .then(res => res.json())
            .then(data => {
                data.camps.forEach(camp => {
                    const color = getUrgencyColor(camp.urgency);
                    const el = createCircleEl(color, 16);
                    const pos = gridToLngLat(camp.lat, camp.lng);

                    new tt.Marker({ element: el })
                        .setLngLat(pos)
                        .setPopup(new tt.Popup({ offset: 10 }).setHTML(
                            `<b>${camp.name}</b><br>Urgency: ${camp.urgency}`
                        ))
                        .addTo(map);
                });
            });

        // Load routes using real roads
        fetch("/api/truck-routes")
            .then(res => res.json())
            .then(async data => {
                const colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6"];

                for (let idx = 0; idx < data.routes.length; idx++) {
                    const route = data.routes[idx];
                    const color = colors[idx % colors.length];
                    const layerId = 'general-route-' + idx;

                    let waypoints = [];
                    route.edges.forEach(edge => {
                        if (waypoints.length === 0) waypoints.push(gridToLngLat(edge[0][0], edge[0][1]));
                        waypoints.push(gridToLngLat(edge[1][0], edge[1][1]));
                    });

                    if (waypoints.length > 1) {
                        const roadCoords = await fetchRoadRoute(waypoints);

                        map.addSource(layerId, {
                            type: 'geojson',
                            data: {
                                type: 'Feature',
                                geometry: { type: 'LineString', coordinates: roadCoords }
                            }
                        });

                        map.addLayer({
                            id: layerId,
                            type: 'line',
                            source: layerId,
                            paint: { 'line-color': color, 'line-width': 3 }
                        });
                    }
                }
            });
    });
}

// Only init general map if not on driver page and admin-map doesn't exist
if (document.getElementById("map") && !document.getElementById("admin-map")) {
    const isDriverPage = window.location.pathname.includes('/driver');
    if (!isDriverPage) {
        initGeneralMap();
    }
}

document.querySelectorAll('.flash-success, .flash-warning, .flash-error').forEach(el => {
    setTimeout(() => {
        el.style.opacity = '0';
        setTimeout(() => el.remove(), 500);
    }, 5000);
});

let _notifLastCount = 0;
let _notifKnownIds = new Set();

async function notifInit() {
    const notifBtn = document.getElementById('notif-btn');
    const inlineList = document.getElementById('notif-inline-list');

    if (!notifBtn && !inlineList) return;

    // Seed known IDs first so the initial poll doesn't alert old notifications
    await notifLoadHistory();
    await notifPollCount();

    // Poll every 8 seconds
    setInterval(notifPollCount, 8000);
    setInterval(notifLoadHistory, 15000);

    // Panel mode
    if (notifBtn) {
        notifBtn.addEventListener('click', () => {
            const panel = document.getElementById('notif-panel');
            const overlay = document.getElementById('notif-overlay');
            panel.classList.toggle('open');
            overlay.classList.toggle('show');
        });

        document.getElementById('notif-overlay')?.addEventListener('click', () => {
            document.getElementById('notif-panel').classList.remove('open');
            document.getElementById('notif-overlay').classList.remove('show');
        });
    }

    // Mark all read — panel mode
    document.getElementById('notif-mark-read')?.addEventListener('click', () => {
        fetch('/api/notifications/mark-read', { method: 'POST' })
            .then(() => {
                notifPollCount();
                notifLoadHistory();
            });
    });

    // Mark all read — inline mode (dashboards)
    document.getElementById('notif-mark-read-inline')?.addEventListener('click', (e) => {
        e.preventDefault();
        fetch('/api/notifications/mark-read', { method: 'POST' })
            .then(() => {
                notifPollCount();
                notifLoadHistory();
            });
    });
}

async function notifPollCount() {
    try {
        const res = await fetch('/api/notifications/unread-count');
        const data = await res.json();

        // Badge mode 
        const badge = document.getElementById('notif-badge');
        if (badge) {
            if (data.count > 0) {
                badge.textContent = data.count;
                badge.classList.remove('hidden');
            } else {
                badge.classList.add('hidden');
            }
        }

        // Inline blue dot mode
        const dot = document.getElementById('notif-unread-dot');
        if (dot) {
            if (data.count > 0) {
                dot.classList.remove('hidden');
            } else {
                dot.classList.add('hidden');
            }
        }

        // If count increased, fetch new notifications for toasts
        if (data.count > _notifLastCount) {
            notifShowNewToasts();
        }
        _notifLastCount = data.count;
    } catch (e) {
        // silently ignore polling errors
    }
}

async function notifLoadHistory() {
    try {
        const res = await fetch('/api/notifications');
        const data = await res.json();
        // Inline list takes priority
        const list = document.getElementById('notif-inline-list') || document.getElementById('notif-list');
        if (!list) return;

        if (data.length === 0) {
            list.innerHTML = '<div class="notif-empty">No notifications yet</div>';
            return;
        }

        // Track known IDs for toast deduplication
        data.forEach(n => _notifKnownIds.add(n.id));

        list.innerHTML = data.map(n => `
            <div class="notif-item ${n.is_read ? '' : 'unread'}">
                <span class="notif-dot ${n.level}"></span>
                <div class="notif-body">
                    <div>${n.message}</div>
                    <div class="notif-time">${n.time}</div>
                </div>
            </div>
        `).join('');
    } catch (e) { /* ignore */ }
}

async function notifShowNewToasts() {
    try {
        const res = await fetch('/api/notifications');
        const data = await res.json();

        // Find notifications we haven't alerted yet
        const newNotifs = data.filter(n => !n.is_read && !_notifKnownIds.has(n.id));
        if (newNotifs.length === 0) return;

        // Mark them as known so we don't alert again
        newNotifs.forEach(n => _notifKnownIds.add(n.id));

        // Simple alert popup
        if (newNotifs.length === 1) {
            alert("Notification: " + newNotifs[0].message);
        } else {
            alert("New Notifications:\n\n" + newNotifs.map(n => "• " + n.message).join("\n"));
        }

        // Update history panel
        notifLoadHistory();
    } catch (e) {
        console.error('notifShowNewToasts error:', e);
    }
}

// Initialize on page load — inline mode (dashboards) or panel mode (sub-pages)
if (document.getElementById('notif-btn') || document.getElementById('notif-inline-list')) {
    notifInit();
}

console.log("Fair-Share V1 successfull 🦆");