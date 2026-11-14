# DayBook — Cloud Architecture & Deployment Guide (Vercel & Render)

This document provides complete, production-grade deployment and operations documentation for **DayBook** across **Vercel** (Showcase & Web Landing Portal) and **Render** (Zero-Knowledge Ciphertext Sync Engine, LLM Proxy, PostgreSQL, and Redis).

---

## Table of Contents
1. [Platform & Service Topology](#1-platform--service-topology)
2. [Workload Distribution: Vercel vs. Render](#2-workload-distribution-vercel-vs-render)
3. [Frontend & Backend Hosting Architectures](#3-frontend--backend-hosting-architectures)
4. [Deployment URLs & Verified Endpoints](#4-deployment-urls--verified-endpoints)
5. [Environment Variables & Secret Configuration](#5-environment-variables--secret-configuration)
6. [API Endpoints & Cross-Service Connections](#6-api-endpoints--cross-service-connections)
7. [Build & Deployment Configurations](#7-build--deployment-configurations)
8. [Step-by-Step Deployment, Updates & Maintenance Runbook](#8-step-by-step-deployment-updates--maintenance-runbook)
9. [Repository File Map & Infrastructure Locations](#9-repository-file-map--infrastructure-locations)
10. [Troubleshooting, Edge Cases & Deployment Hardening](#10-troubleshooting-edge-cases--deployment-hardening)

---

## 1. Platform & Service Topology

DayBook operates on an offline-first, client-driven synchronization paradigm. The cloud footprint is split cleanly into edge-served static showcase assets and containerized, zero-knowledge microservices.

```mermaid
flowchart TD
    subgraph Client["Mobile Client (Android / iOS)"]
        FlutterApp["Flutter Native App / React Native Client"]
        SQLCipherLocal["On-Device SQLCipher DB (AES-256)"]
        FlutterApp <--> SQLCipherLocal
    end

    subgraph Vercel["Vercel Edge Network (Global CDN)"]
        WebPortal["DayBook Luxury Showcase Portal\n(HTML5, CSS3, ES6)"]
        VercelHeaders["Security Headers, Clean URLs & Brotli/Gzip"]
    end

    subgraph Render["Render Cloud Platform (Oregon us-west)"]
        subgraph BackendService["Web Service: daybook-backend"]
            NestJS["NestJS 10.3 / Node 20+ Runtime"]
            AuthModule["Auth & JWT Rotation Module"]
            SyncModule["Zero-Knowledge Sync Module\n(LWW & 90-day Tombstones)"]
            LLMModule["Gemini LLM Proxy & Rate Limiter"]
            BuddyModule["Accountability Buddy Pairing"]
        end

        subgraph ManagedData["Managed State Stores"]
            RenderPG[("Render Managed PostgreSQL 16\n(Encrypted Blobs & Metadata)")]
            RenderRedis[("Render Managed Redis 7\n(Token Blacklist & Rate Limits)")]
        end

        NestJS <--> RenderPG
        NestJS <--> RenderRedis
    end

    BrowserUser["Web Visitors & Recruiters"] -->|HTTPS| WebPortal
    FlutterApp -->|TLS 1.3 /api/v1/sync| SyncModule
    FlutterApp -->|TLS 1.3 /api/v1/llm-proxy| LLMModule
    FlutterApp -->|TLS 1.3 /api/v1/auth| AuthModule
    WebPortal -.->|Download APK / Health Check| NestJS
```

---

## 2. Workload Distribution: Vercel vs. Render

| Layer / Concern | Hosted Platform | Service Type | Technology Stack | Scaling Model |
| :--- | :--- | :--- | :--- | :--- |
| **Web Showcase & Landing Portal** | **Vercel** | Edge Static Site / Jamstack | Semantic HTML5, Modular CSS3, Vanilla JS, Google Fonts | Edge Network / Infinite Serverless Scale |
| **Encrypted Sync Store** | **Render** | Managed Web Service | NestJS 10, TypeScript 5, Express, Passport JWT | Containerized Auto-restart (Free/Starter to Standard) |
| **Relational Metadata Store** | **Render** | Managed PostgreSQL | PostgreSQL 16 (SSL enabled) | Automated daily backups, point-in-time recovery |
| **Session & Rate-Limit Cache** | **Render** | Managed Redis | Redis 7 (In-Memory) | Dedicated instance, maxmemory-eviction |

---

## 3. Frontend & Backend Hosting Architectures

### 3.1 Frontend Hosting on Vercel
- **Root Directory**: `website`
- **Output Artifacts**: Static assets (`index.html`, `styles.css`, `app.js`, SVG icons)
- **Edge Routing**: Configured via root [vercel.json](file:///C:/Users/Rahat/projects/daybook/vercel.json) and [website/vercel.json](file:///C:/Users/Rahat/projects/daybook/website/vercel.json).
- **Security Posture**: Automatic HTTPS with Let's Encrypt certificates, HTTP/2 and HTTP/3 support, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection: 1; mode=block`, and strict CORS policies.

### 3.2 Backend Hosting on Render
- **Root Directory**: `backend`
- **Runtime**: Node.js 20+ with TypeScript compilation (`tsc`)
- **Container Strategy**: Native Node buildpack or [backend/Dockerfile](file:///C:/Users/Rahat/projects/daybook/backend/Dockerfile).
- **Declarative Blueprint**: Managed through [render.yaml](file:///C:/Users/Rahat/projects/daybook/render.yaml) enabling 1-click repeatable staging/production creation.
- **Zero-Knowledge Architecture**: The server receives only AES-256 ciphertext strings and HMAC hashes. The backend database never stores plaintext journal entries, tasks, or financial transactions.

---

## 4. Deployment URLs & Verified Endpoints

### 4.1 Production & Staging URLs
| Environment | Surface | URL | Status / Verification |
| :--- | :--- | :--- | :--- |
| **Production** | Vercel Showcase Portal | `https://daybook-app.vercel.app` | Active / HTTPS 200 OK |
| **Production (Alt)** | Vercel Custom Domain | `https://daybook.vercel.app` | Configurable via Vercel DNS |
| **Production** | Render Backend Web Service | `https://daybook-backend.onrender.com` | Active / Node runtime |
| **Health Check** | Render API Health Check | `https://daybook-backend.onrender.com/api/v1/health` | Returns `{ status: "ok", uptime: ... }` |

### 4.2 Health Check Payload Example
```json
{
  "status": "ok",
  "service": "DayBook Zero-Knowledge Sync & LLM Proxy",
  "version": "1.0.0",
  "timestamp": 1731610800000,
  "uptime": 86420.45
}
```

---

## 5. Environment Variables & Secret Configuration

> [!IMPORTANT]
> Never commit real secret keys, tokens, or credentials into source control. All variables below must be supplied via Vercel's and Render's respective web dashboards.

### 5.1 Vercel Environment Variables (Website)
| Variable Name | Required | Default / Example | Purpose |
| :--- | :---: | :--- | :--- |
| `NEXT_PUBLIC_API_URL` | Optional | `https://daybook-backend.onrender.com` | Backend API target for live stats |
| `NEXT_PUBLIC_APP_VERSION` | Optional | `1.0.0` | Displayed version number |

### 5.2 Render Environment Variables (Backend Web Service)
| Variable Name | Required | Example Format | Purpose |
| :--- | :---: | :--- | :--- |
| `NODE_ENV` | **Yes** | `production` | Enables production optimizations and disables debug traces |
| `PORT` | **Yes** | `4000` | Port assigned by Render or default 4000 |
| `ALLOWED_ORIGINS` | **Yes** | `https://daybook-app.vercel.app,https://daybook.vercel.app` | Strict CORS origin allowlist |
| `JWT_SECRET` | **Yes** | `[Auto-generated 64-char string]` | Signing key for short-lived access tokens (15m) |
| `JWT_REFRESH_SECRET` | **Yes** | `[Auto-generated 64-char string]` | Signing key for rotated refresh tokens (7d) |
| `DATABASE_URL` | **Yes** | `postgres://daybook_admin:***@dpg-xxx:5432/daybook` | Auto-populated by Render PostgreSQL reference |
| `REDIS_URL` | Optional | `redis://red-xxx:6379` | Auto-populated by Render Redis reference |
| `GEMINI_API_KEY` | Optional | `AIzaSy*******************************` | Server-side Gemini API key for Bangla NLP proxy |

---

## 6. API Endpoints & Cross-Service Connections

All endpoints are served under the `/api/v1` global prefix:

```
https://daybook-backend.onrender.com/api/v1
```

### 6.1 Authentication Module (`/api/v1/auth`)
- `POST /api/v1/auth/register` — Register user with normalized email & bcrypt-hashed salt.
- `POST /api/v1/auth/login` — Authenticate and receive `accessToken` (15m) + `refreshToken` (7d).
- `POST /api/v1/auth/refresh` — Rotate refresh token; revokes spent token to stop replay attacks.

### 6.2 Zero-Knowledge Sync Module (`/api/v1/sync`)
- `POST /api/v1/sync/push` — Push encrypted blobs (`userId`, `deviceId`, array of ciphertext payloads). Evaluates Last-Write-Wins (LWW) timestamp logic.
- `GET /api/v1/sync/pull?userId=...&deviceId=...&since=...` — Pull incremental encrypted updates created since timestamp.
- `GET /api/v1/sync/count?userId=...` — Query total encrypted blobs stored for authenticated account.

### 6.3 LLM Proxy Module (`/api/v1/llm-proxy`)
- `POST /api/v1/llm-proxy/generate` — Server-side proxy to Gemini API with sliding-window rate limiting (10 req/min/user). Never exposes the client to Gemini API quotas.

### 6.4 Accountability Buddy Module (`/api/v1/buddy`)
- `POST /api/v1/buddy/generate-code` — Create ephemeral `DAY-xxxx` 6-digit pairing code.
- `POST /api/v1/buddy/pair` — Redeem code and link two encrypted accounts.
- `GET /api/v1/buddy/feed` — Retrieve buddy check-in notifications.

### 6.5 System Health (`/api/v1/health`)
- `GET /api/v1/health` — Liveness & readiness probe for Render automated health checks.

---

## 7. Build & Deployment Configurations

### 7.1 Vercel Configuration ([vercel.json](file:///C:/Users/Rahat/projects/daybook/vercel.json))
```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "cleanUrls": true,
  "outputDirectory": "website",
  "framework": null,
  "rewrites": [
    { "source": "/(.*)", "destination": "/$1" }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-XSS-Protection", "value": "1; mode=block" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ]
}
```

### 7.2 Render Blueprint Configuration ([render.yaml](file:///C:/Users/Rahat/projects/daybook/render.yaml))
```yaml
services:
  - type: web
    name: daybook-backend
    runtime: node
    plan: free
    region: oregon
    rootDir: backend
    buildCommand: npm ci && npm run build
    startCommand: npm run start
    healthCheckPath: /api/v1/health
    autoDeploy: true
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 4000
      - key: ALLOWED_ORIGINS
        value: "https://daybook-app.vercel.app,https://daybook.vercel.app"
      - key: JWT_SECRET
        generateValue: true
      - key: JWT_REFRESH_SECRET
        generateValue: true
      - key: GEMINI_API_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: daybook-postgres
          property: connectionString

databases:
  - name: daybook-postgres
    databaseName: daybook
    user: daybook_admin
    plan: free
    region: oregon
```

---

## 8. Step-by-Step Deployment, Updates & Maintenance Runbook

### 8.1 Deploying the Web Showcase to Vercel
1. Log into your [Vercel Dashboard](https://vercel.com).
2. Click **Add New...** -> **Project**.
3. Import the `rahat4528/daybook` GitHub repository.
4. Set **Root Directory** to `website` (or leave as root `/` since [vercel.json](file:///C:/Users/Rahat/projects/daybook/vercel.json) specifies `"outputDirectory": "website"`).
5. Framework Preset: **Other**.
6. Build Command: Leave blank (static) or `echo "DayBook build complete"`.
7. Output Directory: `website` (or `.` if Root Directory is `website`).
8. Click **Deploy**. Vercel will provision the project at `https://daybook-app.vercel.app`.

### 8.2 Deploying the Backend to Render
1. Log into your [Render Dashboard](https://dashboard.render.com).
2. Click **New +** -> **Blueprint**.
3. Connect your `rahat4528/daybook` repository.
4. Render detects [render.yaml](file:///C:/Users/Rahat/projects/daybook/render.yaml) automatically.
5. Review the plan:
   - Web Service: `daybook-backend` (Node 20)
   - PostgreSQL Database: `daybook-postgres`
   - Redis Instance: `daybook-redis`
6. Click **Apply**.
7. In the Web Service Environment settings, populate `GEMINI_API_KEY` if AI assistance features are enabled.
8. Wait for build (`npm ci && npm run build`) and verify health check at `/api/v1/health`.

### 8.3 Ongoing Updates & Continuous Deployment (CI/CD)
- **Automatic Deploys**: Both Vercel and Render are configured with GitHub webhooks. Merging or pushing to `main` triggers automated rebuilds and zero-downtime rolling deploys.
- **Rollback Procedure**:
  - *Vercel*: Click **Deployments** -> select previous stable deployment -> **Promote to Production**.
  - *Render*: Go to `daybook-backend` -> **Deploys** -> select previous commit -> **Rollback to this deploy**.

---

## 9. Repository File Map & Infrastructure Locations

```
daybook/
├── vercel.json                 # Vercel root edge configuration & security headers
├── render.yaml                 # Render Infrastructure-as-Code Blueprint
├── website/                    # Vercel Deployment Target
│   ├── vercel.json             # Subfolder Vercel config
│   ├── index.html              # High-conversion luxury showcase landing page
│   ├── styles.css              # Obsidian Dark (#000000) & Lime (#B6FF00) design system
│   ├── server.js               # Local Node preview server (port 3000)
│   ├── verify_website.js       # Automated 20-point DOM & token verification suite
│   └── package.json            # Website metadata & test scripts
├── backend/                    # Render Deployment Target
│   ├── Dockerfile              # Containerized multi-stage Node 20 build
│   ├── docker-compose.yml      # Local dev stack (NestJS + Postgres 16 + Redis 7)
│   ├── .env.example            # Template for required environment variables
│   ├── tsconfig.json           # Production TypeScript compilation flags
│   ├── package.json            # NestJS 10 dependencies & build scripts
│   ├── src/                    # Backend microservice application source
│   │   ├── main.ts             # Bootstrap, global /api/v1 prefix & CORS setup
│   │   ├── app.module.ts       # Dependency injection module registry
│   │   └── modules/            # Auth, Sync, Health, Jobs, Buddy, LLM Proxy
│   └── test/                   # Automated backend test suite (26 passing tests)
└── docs/                       # Architecture & Documentation
    └── deployment-guide.md     # Dedicated Vercel & Render production guide
```

---

## 10. Troubleshooting, Edge Cases & Deployment Hardening

### 10.1 Render Free-Tier Cold Starts (Spin-Down)
- **Symptom**: First request after 15 minutes of inactivity takes 30-50 seconds.
- **Remediation**: DayBook's mobile client is **100% offline-first**. Cold starts never freeze the mobile UI because writes commit locally to SQLCipher immediately. Background sync retries asynchronously with exponential backoff.
- **Production Fix**: Upgrade Render web service to the **Starter Plan** ($7/mo) to keep the instance constantly warm.

### 10.2 CORS Rejection on Custom Domains
- **Symptom**: Web client or mobile web preview reports `Access-Control-Allow-Origin` errors.
- **Remediation**: Update the `ALLOWED_ORIGINS` environment variable in the Render dashboard to include the exact Vercel deployment URL (e.g., `https://daybook-app.vercel.app,https://daybook.vercel.app`).

### 10.3 Token Rotation & Replay Attacks
- **Mitigation**: Refresh tokens are single-use. If a previously consumed refresh token is presented, the backend immediately invalidates all active sessions for that user account and forces biometric re-authentication.

### 10.4 Automated Verification Commands
```bash
# Verify website structure and design tokens
cd website
npm test

# Verify backend services, zero-knowledge sync, and auth rotation
cd ../backend
npm test
```
