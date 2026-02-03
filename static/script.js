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

const canvas = document.getElementById("campMap");

if (canvas) {
    const ctx = canvas.getContext("2d");
    const SCALE = 0.5; // 1000 → 500

    function drawGrid() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = "#e5e7eb";

        for (let i = 0; i <= 1000; i += 100) {
            ctx.beginPath();
            ctx.moveTo(i * SCALE, 0);
            ctx.lineTo(i * SCALE, 500);
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(0, i * SCALE);
            ctx.lineTo(500, i * SCALE);
            ctx.stroke();
        }
    }

    function getColor(urgency) {
        if (urgency >= 0.7) return "red";
        if (urgency >= 0.4) return "orange";
        return "green";
    }

    function drawCamps(camps) {
        camps.forEach(camp => {
            ctx.beginPath();
            ctx.arc(
                camp.x * SCALE,
                camp.y * SCALE,
                5,
                0,
                Math.PI * 2
            );
            ctx.fillStyle = getColor(camp.urgency);
            ctx.fill();
        });
    }

    async function loadCamps() {
        const res = await fetch("/api/camps");
        const data = await res.json();

        drawGrid();
        drawCamps(data.camps);
    }

    // initial load
    loadCamps();

    // 🔁 auto-refresh every 3 seconds
    setInterval(loadCamps, 3000);
}
