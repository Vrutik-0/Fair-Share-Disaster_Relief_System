def greedy_route(camps, depot, tol=0.03):
    remaining = camps[:]
    route = []
    current = depot

    while remaining:
        # find max urgency in remain
        max_urgency = max(c["urgency"] for c in remaining)

        # urgency group
        urgency_group = [
            c for c in remaining
            if abs(c["urgency"] - max_urgency) <= tol
        ]

        # if only one
        if len(urgency_group) == 1:
            next_camp = urgency_group[0]
        else:
            # same urgency themn choose closest
            next_camp = min(
                urgency_group,
                key=lambda c: (c["x"] - current["x"])**2 +
                              (c["y"] - current["y"])**2
            )

        route.append(next_camp)
        remaining.remove(next_camp)
        current = next_camp

    return route
