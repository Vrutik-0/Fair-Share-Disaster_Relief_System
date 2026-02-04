from sklearn.cluster import KMeans
import numpy as np

def cluster_camps(camps, num_trucks=5):
    """
    camps = [
      {"camp_id": 1, "x": 120, "y": 340},
      ...
    ]
    """

    if not camps:
        return {}

    coords = np.array([[c["x"], c["y"]] for c in camps])

    k = min(num_trucks, len(camps))

    model = KMeans(n_clusters=k, random_state=42, n_init=10)
    labels = model.fit_predict(coords)

    clusters = {}
    for camp, label in zip(camps, labels):
        clusters.setdefault(label, []).append(camp)

    return clusters
