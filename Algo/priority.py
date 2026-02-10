URC = {
    "critical": 4,
    "high": 3,
    "medium": 2,
    "low": 1
}

# Compute priority for a camp
def compute_priority(camp):
    urgency_weight = URC.get(camp["urgency"], 1)
    supply = max(camp["current_supply"], 1)

    return (camp["population"] * urgency_weight) / supply

# Rank camps by priority score
def rank_camps_greedy(camps):
    for c in camps:
        c["priority_score"] = compute_priority(c)

    return sorted(camps, key=lambda x: x["priority_score"], reverse=True)
