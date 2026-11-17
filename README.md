# Heatwave Alert & Advisory Portal

**Academic use case:** KJS-CES-01 — Climate Intelligence for Heatwave Monitoring, Prediction and Early Warning  
**Institute:** K J Somaiya School of Engineering · Full Stack Development Laboratory (Java) · AY 2026–27  
**Application vertical:** Climate, Energy & Sustainability

A full-stack academic prototype for managing regions and heat-vulnerable monitoring zones, recording manually entered meteorological observations, and generating explainable heatwave alerts and civic advisories.

> **Important:** This is an academic decision-support prototype. It is not an official warning service and is not a substitute for India Meteorological Department (IMD) bulletins or instructions from disaster-management and public-health authorities. Its thresholds and derived heat index are demonstration parameters that require validation before any real-world use.

---

## 1. What is implemented

- Dashboard with counts derived from MongoDB, recent observations/advisories, latest zone status, pending acknowledgements and a severity chart.
- Region / district authority CRUD with search and protection against deleting a region that still owns zones.
- Monitoring-zone CRUD with region, land-use, vulnerability, population, area, baseline temperature and cooling infrastructure. Filters are available for region, land use, vulnerability and latest alert status.
- Manual observation recording with server and client validation; chronological history, update and safe delete. The UI explicitly labels records as manual, not live IoT or satellite data.
- Deterministic Spring Boot rule engine with explainable Heat Index, temperature departure, terrain threshold, nighttime recovery, vulnerability and consecutive-hot-day logic.
- Advisory history saved as separate MongoDB documents. Each advisory stores its input snapshot and model version. Acknowledgement is a separate civic review state.
- Climate reports with live severity distribution, region-wise and zone-wise risk summaries, maximum temperature vs. derived Heat Index chart, and CSV export of actual retrieved observations.
- Model transparency page and detailed model documentation.
- JUnit 5 tests for all five decision outcomes, Heat Index calculation, priority behavior and region-deletion conflict protection.

## 2. Technology stack

| Layer | Technology |
|---|---|
| Frontend | React 19, JavaScript, Vite 7, React Router, Recharts, Lucide React, plain CSS |
| Backend | Java 21, Spring Boot 4.1.2, Spring Web MVC, Spring Data MongoDB, Jakarta Bean Validation, Actuator, Lombok, Maven |
| Database | MongoDB Community Server (local) |
| API | REST + JSON, documented with Swagger / OpenAPI |
| Security | Spring Security, stateless JWT Bearer authentication, BCrypt password hashing, operator/admin authorization |

Java 21 is compatible with the selected Spring Boot line. Vite requires Node 20.19+ or 22.12+; Node 22 is suitable for this project. First-time dependency resolution requires internet access to Maven Central and npm registry. If you prefer, you can install Maven and use `mvn`; the included `mvnw` bootstrap script can also download Maven 3.9.11 if it is not already installed.

## 3. Project structure

```text
heatwave-advisory-portal/
├── backend/
│   ├── .mvn/wrapper/maven-wrapper.properties
│   ├── src/main/java/com/example/heatwaveadvisory/
│   │   ├── auth/            # Login/register request and response records
│   │   ├── config/          # CORS, JWT security, OpenAPI, model properties, seed data
│   │   ├── controller/      # REST endpoints
│   │   ├── document/        # MongoDB documents and enums
│   │   ├── dto/             # API response/request records
│   │   ├── engine/          # Explainable heatwave decision engine
│   │   ├── exception/       # Consistent API errors
│   │   ├── repository/      # Spring Data MongoDB repositories
│   │   └── service/         # Application workflows and aggregation
│   ├── src/test/java/       # JUnit 5 engine and service-conflict tests
│   ├── src/main/resources/application.yml
│   ├── pom.xml
│   ├── mvnw / mvnw.cmd
│   └── README.md (this guide is at repository root)
├── frontend/
│   ├── src/components/      # Shared UI components
│   ├── src/layouts/         # Application shell / navigation
│   ├── src/pages/           # Dashboard, CRUD, observations, alerts, reports, model
│   ├── src/api.js           # Real Fetch API client
│   ├── src/styles.css
│   └── package.json
├── scripts/
│   └── phase3-smoke-test.ps1
└── docs/
    ├── PHASE3_FINALIZATION.md
    ├── architecture.md
    ├── api-reference.md
    ├── heatwave-model.md
    └── security-and-openapi.md
```

## 4. Prerequisites

Install the following on your own machine:

1. **Java Development Kit 21** (`java -version` should show 21).
2. **Node.js 22.12+** and npm (`node -v`, `npm -v`).
3. **MongoDB Community Server** running on `mongodb://localhost:27017`.
4. Maven 3.9+ is recommended. It is not required if you use the included `backend/mvnw` bootstrapper and can download Maven on first use.

No Docker, cloud database, paid service, external identity provider or third-party weather service is required. JWT authentication is handled by the Spring Boot application.

### MongoDB setup

Install MongoDB Community Server for your operating system and start the MongoDB service.

- Windows: start the **MongoDB Server** Windows service, or run `mongod --dbpath C:\data\db` after creating that folder.
- macOS (Homebrew): `brew services start mongodb-community` (after installing the MongoDB Community package).
- Linux: start the `mongod` system service using your distribution's service manager.

The application creates and uses database **`heatwave_advisory_db`** automatically. You do not need to create collections manually.

Default connection:

```text
mongodb://localhost:27017/heatwave_advisory_db
```

To use another MongoDB URI, set `MONGODB_URI` before starting the backend.

## 5. Run the application locally

Open two terminal windows after MongoDB has started.

### Terminal 1 — Spring Boot backend

**Windows PowerShell:**

Create and store `JWT_SECRET` once (skip this if you have already followed `docs/security-and-openapi.md`):

```powershell
$bytes = New-Object byte[] 32
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$secret = [Convert]::ToBase64String($bytes)
[Environment]::SetEnvironmentVariable("JWT_SECRET", $secret, "User")
$env:JWT_SECRET = $secret
$rng.Dispose()
```

In a new terminal, load the same secret and set the initial admin credentials before starting the backend:

```powershell
cd heatwave-advisory-portal\backend
$env:JWT_SECRET = [Environment]::GetEnvironmentVariable("JWT_SECRET", "User")
$env:APP_ADMIN_USERNAME = "admin"
$env:APP_ADMIN_PASSWORD = "UseYourOwnStrongPassword123"
.\mvnw.cmd spring-boot:run
```

**macOS / Linux:**

Generate a JWT secret once with `openssl rand -base64 32`, then keep that value in a secure local shell environment/profile (never in Git). In each backend terminal, load the same value and start the service:

```bash
cd heatwave-advisory-portal/backend
export JWT_SECRET="<your-saved-private-secret>"
export APP_ADMIN_USERNAME="admin"
export APP_ADMIN_PASSWORD="UseYourOwnStrongPassword123"
./mvnw spring-boot:run
```

Or, when Maven is installed:

```bash
cd backend
mvn spring-boot:run
```

The API starts at `http://localhost:8080`. Set `JWT_SECRET` before launching the backend; the value must contain at least 32 UTF-8 bytes. For a stable login across backend restarts, keep using the same private secret value; changing it invalidates previously issued tokens. Set `APP_ADMIN_USERNAME` and `APP_ADMIN_PASSWORD` to create an administrator on first startup (password must be at least 10 characters). If that username already exists as an OPERATOR, choose a different admin username; bootstrap does not silently promote an existing account. Swagger UI is available at `http://localhost:8080/swagger-ui/index.html` (the `/swagger-ui.html` path may redirect), and the OpenAPI JSON document is at `http://localhost:8080/v3/api-docs`. Register or sign in through `/api/auth/register` or `/api/auth/login`, then use the returned JWT as a Bearer token in Swagger's **Authorize** dialog. All application APIs other than health and authentication require a valid token. Only administrators can create, update or delete regions and monitoring zones. On first startup, the optional `DataInitializer` inserts sample records only when the `regions` collection is empty.

Disable automatic seed data by setting `SEED_DATA_ENABLED=false` before launching the backend. The seeder will not overwrite an existing database.

### Terminal 2 — React frontend

```bash
cd heatwave-advisory-portal/frontend
npm install
```

Copy `.env.example` to `.env` if you need to override the API URL. The default is already `http://localhost:8080/api`.

```bash
npm run dev
```

Open **http://localhost:5173** in your browser.

### Verify service connectivity

- Frontend: `http://localhost:5173`
- Backend health: `http://localhost:8080/api/health`
- Model configuration: `http://localhost:8080/api/model/config`
- Dashboard JSON: `http://localhost:8080/api/dashboard/summary`

The `/api/health` endpoint returns application status plus MongoDB connectivity. The frontend top bar also displays connection status.

## 6. Build and test

Run backend unit tests. **Windows PowerShell / CMD:**

```powershell
cd backend
.\mvnw.cmd test
```

**macOS / Linux:**

```bash
cd backend
./mvnw test
```

Build the React frontend (from `frontend/`):

```bash
npm ci
npm run build
```

Create the executable Spring Boot JAR (from `backend/`):

```powershell
.\mvnw.cmd clean package
```

On macOS / Linux use `./mvnw clean package`. The UI build output is written to `frontend/dist/`; the backend JAR is written to `backend/target/`.

**Handoff verification note:** the project source and tests are included, but the Maven test suite and Vite production build could not be rerun in the handoff environment. Maven was not installed and its wrapper could not download Maven because outbound DNS was unavailable. The ZIP's pre-existing `node_modules` tree was platform-incomplete (the Linux-specific Rollup optional package was absent), so it is intentionally excluded from the cleaned delivery; run `npm ci` on your Windows machine to install the lockfile-defined platform dependencies. Do not report the Maven/JUnit or frontend build as passing until you have run the commands locally.

## 7. Authentication and API documentation

- `POST /api/auth/register` creates an operator account. Public registration cannot assign the `ADMIN` role.
- `POST /api/auth/login` verifies the password hash and returns a short-lived JWT access token.
- Send the token on protected API calls using `Authorization: Bearer <token>`.
- Region and monitoring-zone changes require the `ADMIN` role. Other application resources require an authenticated user.
- Passwords are stored as BCrypt hashes; raw passwords are never stored. The JWT signing key is loaded from `JWT_SECRET` and is not stored in the repository.
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`; OpenAPI JSON: `http://localhost:8080/v3/api-docs`. The Swagger UI includes a JWT Bearer authorization scheme.

For a detailed explanation of account setup, role permissions, the Bearer header, Swagger authorization steps and expected security tests, see [`docs/security-and-openapi.md`](docs/security-and-openapi.md).

## 8. REST API overview

All endpoints are prefixed with `/api`. Detailed request and response descriptions are in [`docs/api-reference.md`](docs/api-reference.md).

| Module | Endpoints |
|---|---|
| System | `GET /health`, `GET /model/config` |
| Dashboard / reports | `GET /dashboard/summary`, `GET /reports/summary` |
| Regions | `GET/POST /regions`, `GET/PUT/DELETE /regions/{id}`, `GET /regions/{id}/zones` |
| Zones | `GET/POST /zones`, `GET/PUT/DELETE /zones/{id}` |
| Observations | `GET/POST /observations`, `GET/PUT/DELETE /observations/{id}` |
| Advisories | `POST /advisories/generate`, `GET /advisories`, `GET /advisories/{id}`, `PATCH /advisories/{id}/acknowledge` |

## 9. Data lifecycle

```mermaid
flowchart TD
    A[Region / District] --> B[Monitoring Zone]
    B --> C[Manual Weather Observation]
    C --> D[Persist observation in MongoDB]
    D --> E[Generate Advisory API]
    E --> F[Load saved observation + current zone + region]
    F --> G[Calculate Heat Index and temperature departure]
    G --> H[Evaluate rules in priority order]
    H --> I[Build reasoning and sector actions]
    I --> J[Save immutable input snapshot + advisory]
    J --> K[Dashboard / Reports / Acknowledgement]
```

An advisory is never overwritten by a later generation. Its input snapshot records the zone baseline and raw observation data used at generation time. Changing an observation or zone later does not rewrite the historical advisory snapshot.


## 10. Important design decisions

- JWT authentication and role-based authorization protect application APIs. Swagger/OpenAPI documents the secured endpoints. No external identity provider or external weather API is required.
- Region deletion is blocked while child zones exist.
- Zone deletion is blocked while observation or advisory history exists, protecting the audit trail.
- Observation deletion is blocked after an advisory references it.
- Updating source observations or zone baselines does not mutate already generated advisory snapshots.
- All severity classification happens in the backend `HeatwaveDecisionEngine`.
- Operational outputs are clearly labelled illustrative estimates.
- The UI provides empty states for a fresh database and displays API errors instead of faking successful saves.

## 11. Phase 3 finalization and evidence

The submitted project includes the Phase 3 security, API documentation, validation and error-handling implementation. Use these supporting guides before the final demonstration:

- [`docs/architecture.md`](docs/architecture.md) — final React → Spring Security → Spring Boot → MongoDB / decision-engine architecture and request flow.
- [`docs/PHASE3_FINALIZATION.md`](docs/PHASE3_FINALIZATION.md) — requirement-to-source mapping, Windows setup, verification cases, evidence checklist and known limitations.
- [`docs/security-and-openapi.md`](docs/security-and-openapi.md) — JWT account setup, roles, protected endpoints and Swagger Bearer authorization.
- [`scripts/phase3-smoke-test.ps1`](scripts/phase3-smoke-test.ps1) — PowerShell smoke tests for public health/OpenAPI, unauthorized access, valid JWT access, invalid observation input and operator/admin authorization. Run it after starting the backend and MongoDB:

```powershell
.\scripts\phase3-smoke-test.ps1
```

The script creates a temporary operator account. It does not create or delete regions, zones, observations or advisories. Capture actual screenshots from your running app; do not use documentation examples as runtime evidence.

## 12. Troubleshooting

**Backend refuses to start with a JWT_SECRET message**  
Set `JWT_SECRET` in the same terminal before starting Spring Boot. It must contain at least 32 UTF-8 bytes.

**Swagger returns 401 for an API call**  
Open Swagger UI, select **Authorize**, paste the token returned by `/api/auth/login` (or registration), and authorize. The token expires after the configured duration.

**Cannot create or edit a region/zone**  
Those write operations require an `ADMIN` account. Set `APP_ADMIN_USERNAME` and `APP_ADMIN_PASSWORD` before first startup to bootstrap one. A newly registered account has the `OPERATOR` role.

**Backend reports MongoDB disconnected / refuses to start**  
Start the MongoDB service, verify port `27017`, and check `MONGODB_URI`. MongoDB must be reachable before the seed runner can initialize the database.

**Port 8080 is already in use**  
Set `SERVER_PORT=8081`, then change the frontend `.env` to `VITE_API_BASE_URL=http://localhost:8081/api`.

**Frontend cannot reach backend**  
Ensure the backend is listening on port 8080 and check `frontend/.env`. CORS allows `http://localhost:5173` and `http://127.0.0.1:5173` by default.

**No sample data**  
Check that `SEED_DATA_ENABLED` is not `false` and that the `regions` collection is empty. The seeder intentionally runs only once on an empty database.

**Maven or npm dependency download fails**  
Check the internet connection and retry. The initial build needs access to Maven Central and the npm registry.
