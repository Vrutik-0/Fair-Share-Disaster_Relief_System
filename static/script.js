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
