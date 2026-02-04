import math

def distance(a, b):
    return math.sqrt((a["x"] - b["x"])**2 + (a["y"] - b["y"])**2)


def mst_edges(camps):
    """
    camps = [
      {"camp_id": 1, "x": 150, "y": 200},
      ...
    ]
    returns list of edges [(campA, campB), ...]
    """

    if len(camps) <= 1:
        return []

    visited = {camps[0]["camp_id"]}
    edges = []

    while len(visited) < len(camps):
        min_edge = None

        for c1 in camps:
            if c1["camp_id"] in visited:
                for c2 in camps:
                    if c2["camp_id"] not in visited:
                        d = distance(c1, c2)
                        if not min_edge or d < min_edge[0]:
                            min_edge = (d, c1, c2)

        _, from_camp, to_camp = min_edge
        visited.add(to_camp["camp_id"])
        edges.append((from_camp, to_camp))

    return edges
