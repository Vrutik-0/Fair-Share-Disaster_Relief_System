def knapsack(items, capacity):
    n = len(items)
    dp = [[0]*(capacity+1) for _ in range(n+1)]

    for i in range(1, n+1):
        w = int(items[i-1]["weight"])
        v = items[i-1]["value"]

        for cap in range(capacity+1):
            if w <= cap:
                dp[i][cap] = max(dp[i-1][cap],
                                 v + dp[i-1][cap-w])
            else:
                dp[i][cap] = dp[i-1][cap]

    # backtrack
    selected = []
    cap = capacity
    for i in range(n, 0, -1):
        if dp[i][cap] != dp[i-1][cap]:
            selected.append(items[i-1])
            cap -= int(items[i-1]["weight"])

    return selected
