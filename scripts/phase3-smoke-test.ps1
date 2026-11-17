[CmdletBinding()]
param(
    [string]$BaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"
$script:Passed = 0
$script:Failed = 0
$client = [System.Net.Http.HttpClient]::new()

function Invoke-ApiRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Token,
        [string]$JsonBody
    )

    $request = [System.Net.Http.HttpRequestMessage]::new(
        [System.Net.Http.HttpMethod]::new($Method),
        "$BaseUrl$Path"
    )
    $request.Headers.Accept.ParseAdd("application/json")
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $request.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $Token)
    }
    if ($PSBoundParameters.ContainsKey("JsonBody")) {
        $request.Content = [System.Net.Http.StringContent]::new(
            $JsonBody,
            [System.Text.Encoding]::UTF8,
            "application/json"
        )
    }

    try {
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Content = $content
        }
    }
    finally {
        $request.Dispose()
        if ($null -ne $response) { $response.Dispose() }
    }
}

function Assert-Status {
    param([string]$Name, $Result, [int]$Expected)
    if ($Result.StatusCode -eq $Expected) {
        Write-Host "PASS  $Name (HTTP $($Result.StatusCode))" -ForegroundColor Green
        $script:Passed++
    }
    else {
        Write-Host "FAIL  $Name (expected HTTP $Expected, received HTTP $($Result.StatusCode))" -ForegroundColor Red
        if ($Result.Content) { Write-Host "      $($Result.Content)" }
        $script:Failed++
    }
}

try {
    Write-Host "Phase 3 smoke tests against $BaseUrl" -ForegroundColor Cyan

    $health = Invoke-ApiRequest -Method GET -Path "/api/health"
    Assert-Status -Name "Public health endpoint" -Result $health -Expected 200

    $openApi = Invoke-ApiRequest -Method GET -Path "/v3/api-docs"
    Assert-Status -Name "OpenAPI document is public and available" -Result $openApi -Expected 200

    $unauthorized = Invoke-ApiRequest -Method GET -Path "/api/dashboard/summary"
    Assert-Status -Name "Protected dashboard rejects missing JWT" -Result $unauthorized -Expected 401

    $username = "phase3test" + (Get-Date -Format "yyMMddHHmmss")
    $password = "Phase3-Test-Password-2026!"
    $registrationBody = @{ username = $username; password = $password } | ConvertTo-Json -Compress
    $registration = Invoke-ApiRequest -Method POST -Path "/api/auth/register" -JsonBody $registrationBody
    Assert-Status -Name "Public operator registration" -Result $registration -Expected 201

    if ($registration.StatusCode -eq 201) {
        $auth = $registration.Content | ConvertFrom-Json
        $token = [string]$auth.accessToken
        if ([string]::IsNullOrWhiteSpace($token)) {
            Write-Host "FAIL  Registration response did not contain accessToken" -ForegroundColor Red
            $script:Failed++
        }
        else {
            $dashboard = Invoke-ApiRequest -Method GET -Path "/api/dashboard/summary" -Token $token
            Assert-Status -Name "Valid operator JWT accesses dashboard" -Result $dashboard -Expected 200

            $invalidObservation = Invoke-ApiRequest -Method POST -Path "/api/observations" -Token $token -JsonBody "{}"
            Assert-Status -Name "Invalid observation is rejected by validation" -Result $invalidObservation -Expected 400

            $adminOnlyWrite = Invoke-ApiRequest -Method POST -Path "/api/regions" -Token $token -JsonBody "{}"
            Assert-Status -Name "Operator is blocked from administrator-only region write" -Result $adminOnlyWrite -Expected 403
        }
    }
    else {
        Write-Host "SKIP  Token-dependent checks because registration did not succeed." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "ERROR  $($_.Exception.Message)" -ForegroundColor Red
    $script:Failed++
}
finally {
    $client.Dispose()
}

Write-Host ""
Write-Host "Smoke test summary: $script:Passed passed; $script:Failed failed."
if ($script:Failed -gt 0) { exit 1 }
