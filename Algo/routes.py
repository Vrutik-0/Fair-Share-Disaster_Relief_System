import math

def distance(a, b):
    return math.sqrt((a["x"]-b["x"])**2 + (a["y"]-b["y"])**2)

def mst_route(camps):
    visited = set()
    route = []

    visited.add(camps[0]["camp_id"])

    while len(visited) < len(camps):
        min_edge = None
        for c1 in camps:
            if c1["camp_id"] in visited:
                for c2 in camps:
                    if c2["camp_id"] not in visited:
                        d = distance(c1, c2)
                        if not min_edge or d < min_edge[0]:
                            min_edge = (d, c2)
        visited.add(min_edge[1]["camp_id"])
        route.append(min_edge[1])

    return route
