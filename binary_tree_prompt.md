# Binary Tree Component — Build Prompt

## Overview
Build a production-ready MLM binary tree visualization in Flutter. The tree displays members in a left/right binary structure exactly as stored in the database via `placement_path`.

## Data Model

### MemberNode (from API)
```dart
class MemberNode {
  String id, memberId, fullName, role, status;
  String placementPath;    // e.g. "root", "root.L", "root.L.R"
  int depth;
  String? leg;             // "LEFT" or "RIGHT"
  String? profileImage;
  double bvTotal, bvLeftLeg, bvRightLeg;
  int teamSize;
  DateTime? createdAt;
  // ... other fields
}
```

### MemberTree (from API)
```dart
class MemberTree {
  MemberNode root;
  List<MemberNode> nodes;     // flat list of ALL nodes
  int depthLimit;
  
  Map<String, MemberNode> toPathMap();   // placementPath → MemberNode
}
```

Database path convention (from `Tree.php`):
- Root: `"root"`
- Left child: `parentPath + ".L"` (e.g. `"root.L"`)
- Right child: `parentPath + ".R"` (e.g. `"root.R"`)

## Layout Algorithm (Reingold-Tilford style)

Use a **two-pass coordinate-based algorithm** (NOT recursive Column/Row nesting):

### Step 1: Build layout tree
Recursively build `_LayoutNode` tree from the flat `pathMap` using placement path suffixes:
- If `pathMap[node.placementPath + '.L']` exists → assign as `left` child
- If `pathMap[node.placementPath + '.R']` exists → assign as `right` child
- Respect `maxDepth` — don't build children beyond it

### Step 2: Calculate subtree widths (bottom-up pass)
For each node, compute the total width needed by its subtree:
- If below max depth and left child missing → reserve `_nodeWidth` for empty slot
- If below max depth and right child missing → reserve `_nodeWidth` for empty slot
- If both left and right spaces exist → `subtreeW = leftW + _hGap + rightW`
- If only one side exists → `subtreeW = that side's width`
- If no children → `subtreeW = _nodeWidth`
- Always: `subtreeW = max(_nodeWidth, calculated_width)`

### Step 3: Assign Y positions (top-down)
- Root Y = 0
- Each child Y = parent Y + `_nodeHeight` + `_vGap`

### Step 4: Assign X positions (top-down)
- Root X = 0 (centered)
- For each node:
  - Compute `leftW` = (left child exists ? left.subtreeW : emptySlot ? _nodeWidth : 0)
  - Compute `rightW` = (right child exists ? right.subtreeW : emptySlot ? _nodeWidth : 0)
  - If both > 0: `span = leftW + _hGap + rightW`, then:
    - Left child X = parentX - span/2 + leftW/2
    - Right child X = parentX + span/2 - rightW/2
  - If only one side: center that child under parent (child X = parentX)

### Step 5: Collect empty slot positions
Use same width/spacing logic as Step 2 & 4 to compute where "Open Left" / "Open Right" placeholders go:
- Only create slots where real child is null AND below max depth
- Position must match where a real child would be placed (symmetric with opposite child)

## Layout Constants
```dart
const double _nodeWidth = 144;    // All nodes same width
const double _nodeHeight = 106;   // All nodes same height
const double _hGap = 48;          // Horizontal gap between siblings
const double _vGap = 64;          // Vertical gap between levels
const double _padding = 48;       // Padding around the tree
```

## Rendering

### Container
- `InteractiveViewer` with `minScale: 0.1, maxScale: 3.0`
- `constrained: false` (allow overflow for large trees)
- `boundaryMargin: EdgeInsets.all(200)`

### Tree Canvas
Use a `SizedBox` with calculated `totalW` and `treeH` containing a `Stack`:
1. **Layer 1 (z=1):** `CustomPaint` with `_TreeConnectorPainter` — draws elbow connectors
2. **Layer 2 (z=10):** `Positioned` widgets for each real `_MemberNodeCard`
3. **Layer 3 (z=20):** `Positioned` widgets for each `_EmptySlot`

Bounding box must include BOTH node positions AND slot positions.

### Connector Lines (elbow style)
For each parent-child connection:
```
Parent Bottom Center
        |
        | (vertical line down to midpoint)
        |
   -----+----- (horizontal line)
        |        |
        |        |
  (vertical)  (vertical)
        |        |
  Child Top  Child Top
  Center     Center
```
- Start: `(parent.x, parent.y + _nodeHeight)`
- Midpoint Y: `parentBottom + (childTop - parentBottom) / 2`
- End: `(child.x, child.y)`
- Three line segments: vertical down, horizontal across, vertical down

### Member Node Card (144 × 106 fixed)
- Rounded rectangle with status-based color (green=active, yellow=pending, gray=other)
- 32×32 avatar (profile image or gradient initials fallback)
- Member ID (small, single line)
- Member name (bold, max 2 lines)
- Tap → navigate to member detail screen
- `InkWell` with `borderRadius: 16`

### Empty Slot (144 × 106 fixed — SAME SIZE as member card)
- Dashed border with primary color
- Person-add icon + "Open Left" / "Open Right" text
- Tap → navigate to registration screen with sponsor ID

### Stats Panel (below the tree)
- Total count, Left count, Right count, Total BV
- Color-coded tiles

## Performance
- Layout calculation is O(n) — fast for thousands of nodes
- Use flat `Stack` with `Positioned` widgets (NOT recursive nesting)
- Widgets outside viewport are not painted by Flutter

## Key Behaviors
- Zoom In/Out buttons (+ scale percentage display)
- Pull-to-refresh reloads tree from API
- Tree always centered horizontally (root at top-center)
- Left subtree balanced on left, right subtree on right
- Empty slots participate in all width/position calculations
- No node overlap, no connector overlap with node content
