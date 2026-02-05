const totalPop = document.querySelector('input[name="total_population"]');
const injuredPop = document.querySelector('input[name="injured_population"]');
const preview = document.getElementById("urgencyPreview");

function updateUrgency() {
    const t = parseInt(totalPop.value || 0);
    const i = parseInt(injuredPop.value || 0);

    if (t === 0) {
        preview.innerText = "Urgency Score: 0.00";
        return;
    }

    let score = (i / t) * 0.7 + (t / 1000) * 0.3;
    score = Math.min(score, 1).toFixed(2);

    preview.innerText = `Urgency Score (auto): ${score}`;
}

if (totalPop && injuredPop) {
    totalPop.addEventListener("input", updateUrgency);
    injuredPop.addEventListener("input", updateUrgency);
}

let mapInitialized = false;
let map;
let markers = [];

function getColor(urgency) {
    if (urgency >= 0.7) return "red";
    if (urgency >= 0.4) return "orange";
    return "green";
}

async function loadCampsOnMap() {
    const res = await fetch("/api/camps");
    const data = await res.json();

    // clear old markers
    markers.forEach(m => map.removeLayer(m));
    markers = [];

    data.camps.forEach(camp => {
        const marker = L.circleMarker(
            [camp.lat, camp.lng],
            {
                radius: 8,
                color: getColor(camp.urgency),
                fillColor: getColor(camp.urgency),
                fillOpacity: 0.8
            }
        ).addTo(map);

        //For Click Expandable Dots
        /*marker.bindPopup(`
            <b>${camp.name}</b><br>
            Urgency: ${camp.urgency}<br>
            X: ${camp.lat}, Y: ${camp.lng}
        `);*/

        //For Hover Expandable Dots
        marker.bindTooltip(`
            <b>${camp.name}</b><br>
            Urgency: ${camp.urgency}<br>
            X: ${camp.lat}, Y: ${camp.lng}
        `);

        markers.push(marker);
    });
}

if (document.getElementById("map")) {
    map = L.map("map", {
        crs: L.CRS.Simple,
        minZoom: -2
    });

    const bounds = [[0, 0], [1000, 1000]];
    map.fitBounds(bounds);

    // boundary box
    L.rectangle(bounds, {
        color: "#5f5f5f",
        weight: 2,
        fill: false
    }).addTo(map);

    drawGrid(map, 50); //grid units

    loadCampsOnMap();
    setInterval(loadCampsOnMap, 3000);
}


function drawGrid(map, step = 100) {
    const lines = [];

    //vertical line
    for (let x = 0; x <= 1000; x += step) {
        lines.push(
            L.polyline([[0, x], [1000, x]], {
                color: "#b6b6b6",
                weight: 1,
                opacity: 0.6,
                interactive: false
            })
        );
    }

    //horizontal line
    for (let y = 0; y <= 1000; y += step) {
        lines.push(
            L.polyline([[y, 0], [y, 1000]], {
                color: "#b6b6b6",
                weight: 1,
                opacity: 0.6,
                interactive: false
            })
        );
    }

    lines.forEach(line => line.addTo(map));
}

fetch("/api/truck-routes")
  .then(res => res.json())
  .then(data => {

    const colors = ["red", "blue", "green", "orange", "purple"];

    data.routes.forEach(route => {
      const color = colors[route.truck_id % colors.length];

      route.edges.forEach(edge => {
        L.polyline(edge, {
          color: color,
          weight: 3
        }).addTo(map);
      });
    });

  });

if (document.getElementById("map")) {
  const map = L.map("map", {
    crs: L.CRS.Simple,
    minZoom: -1
  }).setView([500, 500], 0);

  L.rectangle([[0,0],[1000,1000]], {color:"#ccc", weight:1}).addTo(map);

  fetch("/api/driver-route")
    .then(res => res.json())
    .then(data => {
      if (!data.points || data.points.length === 0) return;

      L.polyline(data.points, {
        color: "blue",
        weight: 4
      }).addTo(map);

      data.points.forEach(p => {
        L.circleMarker(p, {
          radius: 6,
          color: "blue"
        }).addTo(map);
      });
    });
}

route.edges.forEach((edge, idx) => {
  L.polyline(edge, { color, weight: 3 }).addTo(map);

  if (idx === 0) {
    L.marker(edge[1]).bindTooltip(`Stop ${idx+1}`).addTo(map);
  }
});
