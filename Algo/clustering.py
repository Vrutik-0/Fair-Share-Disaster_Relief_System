from sklearn.cluster import KMeans

def cluster_camps(camps, trucks):
    """
    camps: list of dicts {camp_id, x, y}
    trucks: list of truck_ids
    returns: {cluster_index: [camp, ...]}
    """

    if not camps:
        return {}

    k = min(len(trucks), max(2, len(camps) // 2))

    points = [[c["x"], c["y"]] for c in camps]

    kmeans = KMeans(
        n_clusters=k,
        random_state=42,
        n_init=10
    )

    labels = kmeans.fit_predict(points)

    clusters = {i: [] for i in range(k)}
    for camp, label in zip(camps, labels):
        clusters[label].append(camp)

    return clusters
