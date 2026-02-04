URGENCY_MULTIPLIER = {
    "critical": 4,
    "high": 3,
    "medium": 2,
    "low": 1
}

def rank_camps(camps):
    for c in camps:
        c["priority_score"] = (
            c["population"] *
            URGENCY_MULTIPLIER[c["priority"]] /
            max(c["current_supply"], 1)
        )

    return sorted(camps, key=lambda x: x["priority_score"], reverse=True)
