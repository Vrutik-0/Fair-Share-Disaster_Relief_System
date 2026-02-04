URGENCY_MULTIPLIER = {
    "critical": 4,
    "high": 3,
    "medium": 2,
    "low": 1
}

def compute_priority(camp):
    """
    camp must contain:
    - population
    - urgency (priority)
    - current_supply
    """
    urgency_weight = URGENCY_MULTIPLIER.get(camp["urgency"], 1)
    supply = max(camp["current_supply"], 1)

    return (camp["population"] * urgency_weight) / supply


def rank_camps_greedy(camps):
    """
    camps = list of camp dicts
    returns camps sorted by priority score (desc)
    """
    for c in camps:
        c["priority_score"] = compute_priority(c)

    return sorted(camps, key=lambda x: x["priority_score"], reverse=True)
