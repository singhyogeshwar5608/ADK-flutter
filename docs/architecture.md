---
layout: default
title: MLM Platform Architecture
---

# MLM Binary Network Platform – Architecture Overview

## 1. High-Level System Design

```
┌──────────────┐    HTTPS / WebSockets    ┌────────────┐
│ React Admin  │◀────────────────────────▶│  API GW &  │
│ Dashboard    │                          │  Services  │
└──────────────┘                          └─────┬──────┘
                                               │
┌──────────────┐    HTTPS / REST              ▼
│ Flutter App  │◀─────────────────────────────┤
└──────────────┘                             │
                                             │   Real-time events
                                             ▼
                                      ┌────────────┐
                                      │ MongoDB    │
                                      └────────────┘
```

* **Shared Backend** – Node.js/Express service exposing REST + Socket.IO events for both web and Flutter clients. JWT auth with access/refresh tokens and role-based guards.
* **MongoDB Cluster** – Sharded cluster (members, orders, products collections) with compound indexes for tree traversal and BV reporting.
* **Redis (optional extension)** – For caching hot queries (tree paths, dashboard aggregates) and session throttling. Stubbed in config for future integration.
* **Message/Job Queue (BullMQ optional)** – For commission payout, BV recomputations, and email notifications.

## 2. Backend Module Layout (`backend/src`)

| Folder | Purpose |
|--------|---------|
| `config` | env loading, database bootstrap, logger, redis + queue clients |
| `middlewares` | auth, error handler, rate limiting, request validation |
| `types` | global TypeScript declarations, request context types |
| `utils` | helpers for hashing passwords, building tree paths, pagination |
| `modules/auth` | auth controllers + services + routes, JWT issuance, RBAC |
| `modules/members` | member schema (binary tree pointers, BV stats), services, controllers, tree visualization DTOs |
| `modules/products` | CRUD with BV assignments, stock operations |
| `modules/orders` | order workflows, BV distribution, coupon application |
| `modules/coupons` | coupon CRUD, activation windows, BV discount rules |
| `modules/reports` | analytics aggregations, CSV/Excel exports |
| `modules/notifications` | Socket.IO events + activity log writer |

Additional cross-cutting layers:

* **`services/cache`** – abstraction for caching + invalidation hooks.
* **`services/queue`** – background job scheduling for commission payouts.
* **`services/tree`** – BFS/DFS traversal helpers with lazy loading & pagination for 100k+ members.

## 3. Database Modeling (MongoDB)

### Members Collection (`members`)

```ts
{
  _id: ObjectId,
  memberId: string,            // public identifier (short uuid)
  sponsorId: ObjectId | null,  // parent reference
  leg: 'LEFT' | 'RIGHT' | null,
  placementPath: string,       // materialized path for fast subtree queries
  depth: number,
  fullName: string,
  email: string,
  phone: string,
  role: 'ADMIN' | 'MEMBER',
  passwordHash: string,
  status: 'ACTIVE' | 'SUSPENDED' | 'PENDING',
  wallet: { balance: number, totalEarned: number },
  bv: {
    total: number,
    leftLeg: number,
    rightLeg: number,
    carryForwardLeft: number,
    carryForwardRight: number
  },
  stats: {
    teamSize: number,
    directRefs: number,
    lastLoginAt: Date
  },
  createdAt: Date,
  updatedAt: Date
}
```

*Indexes*: `memberId` (unique), `sponsorId`, `placementPath`, compound on `{ depth: 1, status: 1 }` for pagination.

### Products Collection (`products`)

Contains name, description, price, BV, stock, categories, gallery assets.

### Orders Collection (`orders`)

Stores line items with snapshot of BV per product, member reference, status, payment info, shipping, history log.

*Indexes*: `memberId`, `status`, `createdAt`, `teamPath` (via member’s placementPath) for subtree aggregations.

### Coupons & Offers

`coupons` collection with metadata + `constraints` document describing BV thresholds, expiry, usage counts.

### Activity Logs & Notifications

`activities` collection storing admin/member actions (CRUD events, tree modifications) for auditing and real-time feeds.

## 4. API Surface

| Module | Key Endpoints |
|--------|---------------|
| Auth | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/invite` |
| Members | `GET /members`, `POST /members`, `GET /members/:id`, `PATCH /members/:id`, `DELETE /members/:id`, `POST /members/:id/move`, `GET /members/:id/tree`, `GET /members/:id/bv` |
| Products | `GET/POST/PATCH/DELETE /products`, `POST /products/:id/images` |
| Orders | `GET /orders`, `POST /orders`, `PATCH /orders/:id/status`, `POST /orders/:id/refund` |
| BV & Commission | `POST /bv/distribute`, `GET /bv/summary`, `GET /commission/reports` |
| Coupons | `GET/POST/PATCH/DELETE /coupons`, `POST /coupons/:code/apply` |
| Reports | `GET /reports/dashboard`, `GET /reports/team-growth`, `GET /reports/export?format=csv|xlsx` |
| Notifications | `GET /notifications`, `PATCH /notifications/:id/read`, Socket.IO channel `events` |

## 5. Frontend (React + Vite + Tailwind)

Folder `web-admin/` (created separately from Flutter web) containing:

* `src/main.tsx` – app bootstrap with theme provider (dark/light) and React Router.
* `src/layouts/DashboardLayout.tsx` – shell with side nav, top bar, notifications panel.
* `src/pages` – pages for dashboard, members, tree, products, orders, analytics, coupons, settings.
* `src/components/charts` – wrappers around Recharts for KPI cards, stacked bars, radial charts.
* `src/components/tree` – zoomable binary tree using `react-d3-tree` with lazy node loader.
* `src/state/queryClient.ts` – TanStack Query for cached API calls.
* `src/services/api.ts` – Axios instance with JWT interceptor shared with Flutter by honoring same auth schema.

## 6. Shared Auth Strategy

* Access token (15m) + refresh token (7d). Flutter stores refresh token securely (Keychain/Keystore), React keeps it in httpOnly cookie.
* `x-client` header differentiates admin web vs member Flutter clients for rate limits + audit logs.
* RBAC middleware ensures Admin-only endpoints; member endpoints enforce ownership via `req.user.id`.

## 7. Performance & Scaling Notes

* Materialized path (`placementPath`) ensures subtree queries via prefix search.
* Aggregations use `$graphLookup` only for rare detailed tree renderings; dashboards rely on cached summaries.
* `GET /members` & `GET /orders` include cursor-based pagination (createdAt + _id tie-breaker).
* Tree visualization API supports lazy loading: `GET /members/:id/tree?depth=2&cursor=...`.
* Rate limiting via `express-rate-limit` + optional Redis store.

## 8. Integration with Existing Flutter App

* Flutter continues using `/api/v1` endpoints with the same JWT tokens.
* Shared DTOs documented in `docs/api-schema.yaml` (to be extended).
* Real-time notifications: Flutter subscribes to Socket.IO namespace `/members` for order updates, React uses `/admin` namespace.

## 9. Deployment Considerations

* Containerized via Docker (multi-stage build). Nginx handles TLS termination + static asset serving for React build.
* CI pipeline: lint + test + build + deploy to Kubernetes/VM.
* Environment separation (dev/stage/prod) with `.env` templates stored under `backend/.env.example` & `web-admin/.env.example`.

## 10. Next Steps

1. Implement backend modules incrementally (auth → members → products → orders → reports).
2. Build React UI with reusable widgets + Chakra/Tailwind tokens.
3. Connect Flutter services to new endpoints (update `lib/services/...`).
4. Add automated tests (Jest + Supertest) and Cypress for frontend flows.
