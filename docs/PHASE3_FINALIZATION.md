# Phase 3 Implementation and Verification Guide

This document maps the submitted code to the KJS-CES-01 Phase 3 finalization requirements. Phase 3 is treated as a finalization phase: existing project scope and the Java rule-based heatwave feature are retained.

## 1. Requirement-to-code mapping

| Phase 3 requirement | Existing implementation |
|---|---|
| React → Spring Boot → MongoDB → intelligent result workflow | `frontend/src/pages/Observations.jsx`, `frontend/src/pages/GenerateAdvisory.jsx`, `frontend/src/api.js`; backend observation/advisory controllers and services; MongoDB repositories |
| Login and JWT issuance | `controller/AuthController.java`, `service/AuthService.java`, `auth/LoginRequest.java`, `auth/RegisterRequest.java`, `auth/AuthResponse.java` |
| Password encoding | `config/SecurityConfig.java` (`BCryptPasswordEncoder`) |
| JWT signing and validation | `config/SecurityConfig.java` (`JwtEncoder`, `JwtDecoder`, stateless resource-server filter chain) |
| Initial administrator | `config/BootstrapAdminInitializer.java`; credentials supplied with environment variables |
| Protected routes and roles | `config/SecurityConfig.java`; operator/admin role claim is included in the JWT |
| Frontend session and protected pages | `frontend/src/auth/AuthContext.jsx`, `frontend/src/auth/RequireAuth.jsx`, `frontend/src/pages/Login.jsx`, `frontend/src/pages/Register.jsx` |
| Bearer token on API calls | `frontend/src/api.js` |
| Swagger/OpenAPI and Authorize scheme | `config/OpenApiConfig.java`, `pom.xml`, controller `@SecurityRequirement` annotations |
| Input validation | Jakarta validation annotations on request/document fields plus service-level consistency checks |
| Consistent failures | `exception/GlobalExceptionHandler.java`, `dto/ApiError.java` |
| Intelligent feature | `engine/HeatwaveDecisionEngine.java`, `config/HeatwaveModelConfig.java`, `service/AdvisoryService.java` |
| Persistent result/history | `repository/HeatwaveAdvisoryRepository.java`, `document/HeatwaveAdvisoryDocument.java`, advisory controller/service |
| Unit tests | `src/test/java/.../HeatwaveDecisionEngineTest.java`, `RegionServiceConflictTest.java` |

## 2. Local startup — Windows PowerShell

Prerequisites: Java 21, Node 22.12+ (or a supported newer Node 22 release), MongoDB Community Server, and network access for first-time Maven/npm dependency downloads.

### One-time JWT secret setup

Run this once in PowerShell. It stores a randomly generated signing key in the current Windows user's environment; keep it private and do not put it in Git or screenshots.

```powershell
$bytes = New-Object byte[] 32
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$secret = [Convert]::ToBase64String($bytes)
[Environment]::SetEnvironmentVariable("JWT_SECRET", $secret, "User")
$env:JWT_SECRET = $secret
$rng.Dispose()
```

### Start MongoDB

```powershell
Get-Service MongoDB
# If stopped, run PowerShell as Administrator:
net start MongoDB
```

### Start backend — Terminal 1

Open a new PowerShell terminal so the saved `JWT_SECRET` is available:

```powershell
cd path\to\heatwave-advisory-2\backend
$env:JWT_SECRET = [Environment]::GetEnvironmentVariable("JWT_SECRET", "User")
$env:APP_ADMIN_USERNAME = "admin"
$env:APP_ADMIN_PASSWORD = "UseYourOwnStrongPassword123"
.\mvnw.cmd spring-boot:run
```

Use a private password of at least 10 characters. Set `APP_ADMIN_USERNAME` and `APP_ADMIN_PASSWORD` before the first startup where an administrator is needed. The bootstrap code does not promote an existing operator account to admin. Do not commit these values.

### Start frontend — Terminal 2

```powershell
cd path\to\heatwave-advisory-2\frontend
npm install
npm run dev
```

Open `http://localhost:5173`. Backend API base URL defaults to `http://localhost:8080/api`.

## 3. Authentication workflow

- Register an operator at `POST http://localhost:8080/api/auth/register` using `{"username":"field.operator","password":"UseAUniquePassword123"}`.
- Or sign in as the configured admin at `POST /api/auth/login` using the username and password set above.
- The response contains `accessToken`, `tokenType`, `expiresInSeconds` and user roles.
- The React API helper attaches the token to protected API calls.
- In Swagger UI, call `POST /api/auth/login`, copy `accessToken`, click **Authorize**, and paste the token into the Bearer field.

Swagger UI: `http://localhost:8080/swagger-ui/index.html` (the `/swagger-ui.html` path may redirect). OpenAPI JSON: `http://localhost:8080/v3/api-docs`.

## 4. Required verification cases

Run the supplied PowerShell script from the repository root after backend and MongoDB are running:

```powershell
.\scripts\phase3-smoke-test.ps1
```

The script creates a uniquely named temporary operator account and checks public Swagger docs, missing-token rejection, valid-token access, invalid observation input, and rejection of an operator's admin-only write. It does not create any project observation or advisory data.

Also manually demonstrate the complete domain workflow:

1. Sign in with the configured admin account.
2. Create or select a region and monitoring zone.
3. Sign in as an operator (or continue with the admin account).
4. Create a manual weather observation for the zone.
5. Generate an advisory from the saved observation.
6. Open the advisory detail/history and confirm the saved result.
7. Inspect the corresponding observation/advisory documents in MongoDB Compass.
8. Restart the backend and confirm the records remain.

## 5. Expected HTTP results

| Scenario | Expected response |
|---|---:|
| Register a valid operator | 201 |
| Login with correct password | 200 |
| Login with incorrect password | 401 |
| GET a protected dashboard endpoint without a token | 401 |
| GET a protected endpoint with a valid operator token | 200 |
| Operator attempts POST/PUT/DELETE on a region or zone | 403 |
| Invalid observation body (for example `{}`) with valid token | 400 |
| Unknown observation/zone/region ID | 404 |
| Delete region with dependent zones | 409 |
| Valid persisted observation generates advisory | 201 |

## 6. Evidence to capture for submission

Capture real screenshots after running the application locally. Do not use fabricated or sample screenshots as runtime evidence.

1. Main React dashboard after login.
2. Observation entry and saved observation/history.
3. Generated advisory detail showing status, applied reasoning and recommendations.
4. MongoDB Compass showing the relevant observation and advisory records.
5. Unauthorized request without a token showing HTTP 401.
6. Authorized request with a Bearer token showing a successful response.
7. Operator attempting an admin-only region/zone write showing HTTP 403.
8. Swagger UI endpoint list and Authorize dialog (mask the token).
9. Swagger UI successful request to a protected endpoint after authorization.
10. Test script output and final Git commit/push.

## 7. Current limitations to disclose

- Meteorological inputs are manually entered; no live IMD/weather API, satellite feed or IoT sensor is connected.
- The intelligent component is a deterministic, explainable Java rule engine, not a trained machine-learning model.
- Thresholds and the simplified Heat Index estimate are academic demonstration parameters and must not be represented as official warnings.
- Browser access tokens are stored in `localStorage` for this academic prototype. A production system should use stronger token lifecycle and browser security controls, HTTPS, rate limiting and audit logging.
- Deployment is local; cloud hosting and container orchestration are outside the Phase 3 requirement.

## 8. Verification status of this handoff

The source has been inspected and the Phase 3 implementation points above are present in the uploaded project. The automated Maven test suite and the Vite production build were **not re-run successfully in the handoff environment**: Maven could not be bootstrapped because outbound DNS access was unavailable, and the included `node_modules` tree did not contain the platform-specific Rollup binary. Run `backend\\mvnw.cmd test` and `frontend\\npm ci && npm run build` on the Windows development machine with internet access before claiming those checks passed. Run the smoke-test script against the live local backend and MongoDB, then record the observed output.
