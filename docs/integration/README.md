# Shared Backend + Flutter Integration Guide

This document explains how the Node.js backend, the React admin (web-admin), and the Flutter mobile app share the same infrastructure, authentication flow, and deployment steps.

## 1. Repository Layout

```
NetShopFlutter/
├─ backend/        # Node.js + Express + MongoDB API
├─ web-admin/      # Vite + React admin console (this repo)
├─ lib/            # Flutter mobile app (NetShopFlutter)
└─ docs/           # Documentation (this file lives under docs/integration)
```

## 2. Environment Configuration

All apps point to the same backend API (default `http://localhost:8080/api/v1`).

### Backend `.env`
```
NODE_ENV=development
PORT=8080
MONGODB_URI=mongodb://127.0.0.1:27017
MONGODB_DB_NAME=mlm_dev
JWT_ACCESS_SECRET=replace-with-64-char-secret
JWT_REFRESH_SECRET=replace-with-64-char-secret
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
PASSWORD_SALT_ROUNDS=10
CLIENT_WEB_ORIGIN=http://localhost:5173
CLIENT_FLUTTER_ORIGIN=http://localhost:8081 # change if using different port for Flutter dev server
```

### Web Admin `.env`
```
VITE_API_BASE_URL=http://localhost:8080/api/v1
```

### Flutter app `lib/config.dart` (sample)
```
class AppConfig {
  static const apiBaseUrl = 'http://localhost:8080/api/v1';
}
```
Make sure the Flutter app reads this constant before calling any API.

> **Production:** replace the localhost URLs with your deployed backend domain.

## 3. Authentication & Tokens

- Backend issues JWT access + refresh tokens.
- Tokens are stored in localStorage (web admin) and secure storage (Flutter). Each client attaches the access token as `Authorization: Bearer <token>`.
- On `401` responses, both clients call `POST /auth/refresh` with the refresh token and swap the tokens.

### Endpoints recap
| Method | Path | Description |
| --- | --- | --- |
| POST | `/auth/register` | Admin creates members (backend seeding or UI) |
| POST | `/auth/login` | Returns `{ accessToken, refreshToken, member }` |
| POST | `/auth/refresh` | Returns new tokens |
| GET | `/auth/me` | Current member profile |

The admin user seeded via `npm run dev` (backend) uses:
- **Email:** `admin@mlm.com`
- **Password:** `Admin@123`

## 4. Running Everything Locally

### Backend
```bash
cd backend
npm install
npm run dev  # seeds admin automatically via seed-admin.ts hook
```
This starts the API at `http://localhost:8080` and runs the Socket.IO namespaces (`/admin`, `/members`).

### Web Admin (React)
```bash
cd web-admin
npm install
npm run dev
```
Visit `http://localhost:5173`. Login using the seeded admin credentials.

### Flutter App
```bash
flutter pub get
flutter run -d <device>
```
Ensure the device/emulator can reach `http://localhost:8080` (use `10.0.2.2` for Android emulator, or your LAN IP).

## 5. Deployment Overview

1. **Backend:**
   - Build: `npm run build` → outputs to `backend/dist`.
   - Deploy the compiled `dist` bundle plus `.env` onto a Node 18+ server.
   - Use PM2 or systemd to keep the server running.
   - Configure MongoDB Atlas or another managed Mongo cluster.

2. **Web Admin:**
   - Build: `npm run build` (in `web-admin`).
   - Deploy `dist/` to any static host (Vercel, Netlify, S3+CloudFront).
   - Set `VITE_API_BASE_URL` at build time to your production API URL.

3. **Flutter App:**
   - For Android: `flutter build apk` or `appbundle`.
   - For iOS: `flutter build ios` (requires macOS + Xcode).
   - Update `AppConfig.apiBaseUrl` to production API before building release.

## 6. Shared Considerations

- **CORS:** backend allows `CLIENT_WEB_ORIGIN` and `CLIENT_FLUTTER_ORIGIN`. Update these env values to match production domains.
- **Socket.IO:** both admin and Flutter can listen on `/members`/`/admin` namespaces; ensure origins are whitelisted.
- **Members/Products/Orders APIs:** both frontend apps hit the same endpoints. Keep pagination + query params consistent.
- **Coupons & Reports:** Admin UI uses protected endpoints (admin role). Flutter app should either hide those screens or call the same endpoints with admin token.

## 7. Verification Checklist

- [ ] Backend `npm run dev` → "📦 MongoDB connected" + "Seed admin created/exists".
- [ ] React admin login works with seeded credentials.
- [ ] Flutter app shows dashboards backed by the same API data.
- [ ] Refresh tokens rotate correctly (inspect network logs).
- [ ] Production environment uses HTTPS + distinct domain.

## 8. Troubleshooting

| Issue | Fix |
| --- | --- |
| `401 Unauthorized` in clients | Check tokens stored, ensure clock skew < 1 min, verify `JWT_*` env secrets |
| Flutter emulator can’t reach backend | Use `10.0.2.2:8080` or machine IP instead of `localhost` |
| Admin seed fails because root already exists | Delete duplicate admin or set credentials manually via Mongo shell |
| Socket.IO CORS error | Update `CLIENT_WEB_ORIGIN` / `CLIENT_FLUTTER_ORIGIN` envs |

## 9. Next Steps

- Automate seeding via CI/CD if necessary.
- Document additional CRUD flows (members/products/orders) for Flutter parity.
- Add screenshots or Loom video for onboarding teammates.
