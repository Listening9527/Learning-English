# 算法整理（Swift 模板 + 例子）

## 使用说明

- 目标：给出常见算法的可复用模板，并附最小示例。
- 语言：Swift 5+
- 风格：优先易读，便于面试和刷题快速改写。

---

## 0. 常用基础模板

### 0.1 交换与打印

```swift
import Foundation

func swapAt<T>(_ arr: inout [T], _ i: Int, _ j: Int) {
	arr.swapAt(i, j)
}

func printArray(_ arr: [Int]) {
	print(arr.map(String.init).joined(separator: " "))
}
```

### 0.2 快速幂（$O(\log n)$）

```swift
import Foundation

func fastPow(_ x: Int, _ n: Int, _ mod: Int) -> Int {
	var base = x % mod
	var exp = n
	var ans = 1 % mod
	while exp > 0 {
		if exp & 1 == 1 { ans = ans * base % mod }
		base = base * base % mod
		exp >>= 1
	}
	return ans
}

// 示例
print(fastPow(2, 10, 1_000_000_007)) // 1024
```

---

## 1. 二分查找

### 模板（找第一个 >= target 的下标）

```swift
func lowerBound(_ nums: [Int], _ target: Int) -> Int {
	var left = 0
	var right = nums.count // 左闭右开
	while left < right {
		let mid = left + (right - left) / 2
		if nums[mid] < target {
			left = mid + 1
		} else {
			right = mid
		}
	}
	return left
}
```

### 例子

```swift
let a = [1, 2, 4, 4, 7]
print(lowerBound(a, 4)) // 2
print(lowerBound(a, 5)) // 4
```

---

## 2. 双指针

### 模板（左右夹逼）

```swift
func twoSumSorted(_ nums: [Int], _ target: Int) -> (Int, Int)? {
	var i = 0
	var j = nums.count - 1
	while i < j {
		let s = nums[i] + nums[j]
		if s == target { return (i, j) }
		if s < target {
			i += 1
		} else {
			j -= 1
		}
	}
	return nil
}
```

### 例子

```swift
let b = [1, 2, 4, 6, 10]
print(twoSumSorted(b, 8) as Any) // Optional((1, 3))
```

---

## 3. 滑动窗口

### 模板（固定右端，收缩左端）

```swift
func minSubArrayLen(_ target: Int, _ nums: [Int]) -> Int {
	var left = 0
	var sum = 0
	var ans = Int.max

	for right in 0..<nums.count {
		sum += nums[right]
		while sum >= target {
			ans = min(ans, right - left + 1)
			sum -= nums[left]
			left += 1
		}
	}
	return ans == Int.max ? 0 : ans
}
```

### 例子

```swift
print(minSubArrayLen(7, [2, 3, 1, 2, 4, 3])) // 2
```

---

## 4. 前缀和

### 模板

```swift
func buildPrefixSum(_ nums: [Int]) -> [Int] {
	var pre = Array(repeating: 0, count: nums.count + 1)
	for i in 0..<nums.count {
		pre[i + 1] = pre[i] + nums[i]
	}
	return pre
}

func rangeSum(_ pre: [Int], _ l: Int, _ r: Int) -> Int {
	pre[r + 1] - pre[l]
}
```

### 例子

```swift
let c = [3, 1, 4, 1, 5]
let pre = buildPrefixSum(c)
print(rangeSum(pre, 1, 3)) // 1 + 4 + 1 = 6
```

---

## 5. DFS（回溯）

### 模板（全排列）

```swift
func permute(_ nums: [Int]) -> [[Int]] {
	var nums = nums
	var ans = [[Int]]()

	func backtrack(_ first: Int) {
		if first == nums.count {
			ans.append(nums)
			return
		}
		for i in first..<nums.count {
			nums.swapAt(first, i)
			backtrack(first + 1)
			nums.swapAt(first, i)
		}
	}

	backtrack(0)
	return ans
}
```

### 例子

```swift
print(permute([1, 2, 3]).count) // 6
```

---

## 6. BFS（最短步数）

### 模板（网格最短路，四方向）

```swift
func shortestPathInGrid(_ grid: [[Int]]) -> Int {
	let m = grid.count
	guard m > 0 else { return -1 }
	let n = grid[0].count
	guard n > 0 else { return -1 }
	guard grid[0][0] == 0, grid[m - 1][n - 1] == 0 else { return -1 }

	var dist = Array(repeating: Array(repeating: -1, count: n), count: m)
	var q = [(Int, Int)]()
	var head = 0

	q.append((0, 0))
	dist[0][0] = 0

	let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
	while head < q.count {
		let (x, y) = q[head]
		head += 1

		if x == m - 1, y == n - 1 {
			return dist[x][y]
		}

		for (dx, dy) in dirs {
			let nx = x + dx
			let ny = y + dy
			if nx >= 0, nx < m, ny >= 0, ny < n,
			   grid[nx][ny] == 0, dist[nx][ny] == -1 {
				dist[nx][ny] = dist[x][y] + 1
				q.append((nx, ny))
			}
		}
	}

	return -1
}
```

### 例子

```swift
let grid = [
	[0, 0, 0],
	[1, 1, 0],
	[0, 0, 0]
]
print(shortestPathInGrid(grid)) // 4
```

---

## 7. 动态规划（DP）

### 模板（线性 DP：爬楼梯）

```swift
func climbStairs(_ n: Int) -> Int {
	if n <= 2 { return n }
	var a = 1
	var b = 2
	for _ in 3...n {
		let c = a + b
		a = b
		b = c
	}
	return b
}
```

### 例子

```swift
print(climbStairs(5)) // 8
```

---

## 8. 并查集（Union-Find）

### 模板

```swift
struct UnionFind {
	var parent: [Int]
	var rank: [Int]

	init(_ n: Int) {
		parent = Array(0..<n)
		rank = Array(repeating: 0, count: n)
	}

	mutating func find(_ x: Int) -> Int {
		if parent[x] != x {
			parent[x] = find(parent[x])
		}
		return parent[x]
	}

	mutating func union(_ x: Int, _ y: Int) {
		let rx = find(x)
		let ry = find(y)
		if rx == ry { return }

		if rank[rx] < rank[ry] {
			parent[rx] = ry
		} else if rank[rx] > rank[ry] {
			parent[ry] = rx
		} else {
			parent[ry] = rx
			rank[rx] += 1
		}
	}

	mutating func isConnected(_ x: Int, _ y: Int) -> Bool {
		find(x) == find(y)
	}
}
```

### 例子

```swift
var uf = UnionFind(5)
uf.union(0, 1)
uf.union(1, 2)
print(uf.isConnected(0, 2)) // true
print(uf.isConnected(0, 4)) // false
```

---

## 9. 单调栈

### 模板（下一个更大元素）

```swift
func nextGreaterElements(_ nums: [Int]) -> [Int] {
	var ans = Array(repeating: -1, count: nums.count)
	var stack = [Int]() // 存下标，保证对应值单调递减

	for i in 0..<nums.count {
		while let last = stack.last, nums[i] > nums[last] {
			ans[last] = nums[i]
			stack.removeLast()
		}
		stack.append(i)
	}
	return ans
}
```

### 例子

```swift
print(nextGreaterElements([2, 1, 2, 4, 3])) // [4, 2, 4, -1, -1]
```

---

## 10. 堆（优先队列，最小堆）

### 模板

```swift
struct MinHeap {
	private var data = [Int]()

	var isEmpty: Bool { data.isEmpty }
	var peek: Int? { data.first }

	mutating func push(_ x: Int) {
		data.append(x)
		siftUp(data.count - 1)
	}

	mutating func pop() -> Int? {
		guard !data.isEmpty else { return nil }
		data.swapAt(0, data.count - 1)
		let res = data.removeLast()
		if !data.isEmpty { siftDown(0) }
		return res
	}

	private mutating func siftUp(_ i: Int) {
		var child = i
		while child > 0 {
			let p = (child - 1) / 2
			if data[p] <= data[child] { break }
			data.swapAt(p, child)
			child = p
		}
	}

	private mutating func siftDown(_ i: Int) {
		var p = i
		while true {
			let l = p * 2 + 1
			let r = p * 2 + 2
			var t = p
			if l < data.count, data[l] < data[t] { t = l }
			if r < data.count, data[r] < data[t] { t = r }
			if t == p { break }
			data.swapAt(p, t)
			p = t
		}
	}
}
```

### 例子

```swift
var heap = MinHeap()
heap.push(5)
heap.push(2)
heap.push(8)
print(heap.pop() as Any) // Optional(2)
print(heap.pop() as Any) // Optional(5)
```

---

## 11. 拓扑排序（Kahn）

### 模板

```swift
func topoSort(_ n: Int, _ edges: [[Int]]) -> [Int] {
	var g = Array(repeating: [Int](), count: n)
	var indeg = Array(repeating: 0, count: n)

	for e in edges {
		let u = e[0], v = e[1]
		g[u].append(v)
		indeg[v] += 1
	}

	var q = [Int]()
	var head = 0
	for i in 0..<n where indeg[i] == 0 { q.append(i) }

	var order = [Int]()
	while head < q.count {
		let u = q[head]
		head += 1
		order.append(u)
		for v in g[u] {
			indeg[v] -= 1
			if indeg[v] == 0 { q.append(v) }
		}
	}

	return order.count == n ? order : []
}
```

### 例子

```swift
let order = topoSort(4, [[0, 1], [0, 2], [1, 3], [2, 3]])
print(order) // 一种可能: [0, 1, 2, 3]
```

---

## 12. 复杂度速查

- 二分查找：时间 $O(\log n)$，空间 $O(1)$
- 双指针：时间 $O(n)$，空间 $O(1)$
- 滑动窗口：时间 $O(n)$，空间 $O(1)$ 或 $O(k)$
- DFS/BFS：时间 $O(V + E)$，空间 $O(V)$
- 并查集：均摊近似 $O(\alpha(n))$
- 堆操作：单次 $O(\log n)$
- 拓扑排序：时间 $O(V + E)$，空间 $O(V)$

## 13. 刷题建议（按顺序）

1. 二分 -> 双指针 -> 滑动窗口
2. 前缀和 -> DFS/BFS
3. DP（线性 -> 背包 -> 区间）
4. 并查集 -> 单调栈 -> 堆 -> 拓扑排序



