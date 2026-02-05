const totalPop = document.querySelector('input[name="total_population"]');
const injuredPop = document.querySelector('input[name="injured_population"]');
const preview = document.getElementById("urgencyPreview");

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

let adminMap = null;
let campMarkers = [];

function getUrgencyColor(urgency) {
    if (urgency >= 0.7) return "red";
    if (urgency >= 0.4) return "orange";
    return "green";
}

function initAdminMap() {
    const mapElement = document.getElementById("admin-map");
    if (!mapElement || adminMap) return;

    adminMap = L.map("admin-map", {
        crs: L.CRS.Simple,
        minZoom: -2
    });

    const bounds = [[0, 0], [1000, 1000]];
    adminMap.fitBounds(bounds);

    // Boundary box
    L.rectangle(bounds, {
        color: "#5f5f5f",
        weight: 2,
        fill: false
    }).addTo(adminMap);

    // Grid
    drawGrid(adminMap, 100);

    // NGO/Warehouse marker
    L.circleMarker([0, 500], {
        radius: 12,
        color: "blue",
        fillColor: "blue",
        fillOpacity: 0.9
    }).addTo(adminMap).bindTooltip("🏭 NGO / Warehouse", { permanent: true });

    // Load camps
    loadCampsOnAdminMap();

    // Load truck routes
    loadTruckRoutes();
}

async function loadCampsOnAdminMap() {
    if (!adminMap) return;

    try {
        const res = await fetch("/api/camps");
        const data = await res.json();

        // Clear old markers
        campMarkers.forEach(m => adminMap.removeLayer(m));
        campMarkers = [];

        data.camps.forEach(camp => {
            const marker = L.circleMarker(
                [camp.lat, camp.lng],
                {
                    radius: 8,
                    color: getUrgencyColor(camp.urgency),
                    fillColor: getUrgencyColor(camp.urgency),
                    fillOpacity: 0.8
                }
            ).addTo(adminMap);

            marker.bindTooltip(`
                <b>${camp.name}</b><br>
                Urgency: ${camp.urgency}<br>
                Position: (${camp.lat}, ${camp.lng})
            `);

            campMarkers.push(marker);
        });
    } catch (err) {
        console.error("Error loading camps:", err);
    }
}

async function loadTruckRoutes() {
    if (!adminMap) return;

    try {
        const res = await fetch("/api/truck-routes");
        const data = await res.json();

        const colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c"];

        console.log("Truck routes loaded:", data.routes.length, "routes");

        data.routes.forEach((route, idx) => {
            const color = colors[idx % colors.length];
            
            console.log(`Route ${idx}: Truck ${route.truck_id}, ${route.camps.length} camps, ${route.edges.length} edges`);

            // Draw route line using route_points if available
            if (route.route_points && route.route_points.length > 1) {
                L.polyline(route.route_points, {
                    color: color,
                    weight: 4,
                    opacity: 0.8
                }).addTo(adminMap);
            } else {
                // Fallback to drawing edges
                route.edges.forEach((edge) => {
                    L.polyline(edge, {
                        color: color,
                        weight: 4,
                        opacity: 0.8
                    }).addTo(adminMap);
                });
            }
        });
    } catch (err) {
        console.error("Error loading truck routes:", err);
    }
}

function drawGrid(map, step = 100) {
    // Vertical lines
    for (let x = 0; x <= 1000; x += step) {
        L.polyline([[0, x], [1000, x]], {
            color: "#b6b6b6",
            weight: 1,
            opacity: 0.4,
            interactive: false
        }).addTo(map);
    }

    // Horizontal lines
    for (let y = 0; y <= 1000; y += step) {
        L.polyline([[y, 0], [y, 1000]], {
            color: "#b6b6b6",
            weight: 1,
            opacity: 0.4,
            interactive: false
        }).addTo(map);
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

    // Check if this is the driver page (has different initialization)
    if (document.body.classList.contains('driver-page')) return;

    const map = L.map("map", {
        crs: L.CRS.Simple,
        minZoom: -2
    });

    const bounds = [[0, 0], [1000, 1000]];
    map.fitBounds(bounds);

    L.rectangle(bounds, {
        color: "#5f5f5f",
        weight: 2,
        fill: false
    }).addTo(map);

    drawGrid(map, 100);

    // NGO marker
    L.circleMarker([0, 500], {
        radius: 12,
        color: "blue",
        fillColor: "blue",
        fillOpacity: 0.9
    }).addTo(map).bindTooltip("🏭 NGO / Warehouse", { permanent: true });

    // Load camps
    fetch("/api/camps")
        .then(res => res.json())
        .then(data => {
            data.camps.forEach(camp => {
                L.circleMarker([camp.lat, camp.lng], {
                    radius: 8,
                    color: getUrgencyColor(camp.urgency),
                    fillColor: getUrgencyColor(camp.urgency),
                    fillOpacity: 0.8
                }).addTo(map).bindTooltip(`
                    <b>${camp.name}</b><br>
                    Urgency: ${camp.urgency}
                `);
            });
        });

    // Load routes
    fetch("/api/truck-routes")
        .then(res => res.json())
        .then(data => {
            const colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6"];
            
            data.routes.forEach((route, idx) => {
                const color = colors[idx % colors.length];
                
                route.edges.forEach(edge => {
                    L.polyline(edge, {
                        color: color,
                        weight: 3
                    }).addTo(map);
                });
            });
        });
}

// Only init general map if not on driver page and admin-map doesn't exist
if (document.getElementById("map") && !document.getElementById("admin-map")) {
    // Check if we're not on driver dashboard (driver has its own script)
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

console.log("Fair-Share V1 successfull 🦆");
