param(
    [string]$BaseUrl = "http://127.0.0.1:3000",
    [string]$Key = "X",
    [string]$CasesPath = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($CasesPath)) {
    $CasesPath = Join-Path $PSScriptRoot "..\tests\reverse-regression-cases.json"
}

if (-not (Test-Path $CasesPath)) {
    throw "Cases file not found: $CasesPath"
}

$BaseUrl = $BaseUrl.TrimEnd("/")
$casesDoc = Get-Content -Raw -Encoding UTF8 $CasesPath | ConvertFrom-Json
$failures = 0

function Get-AddressFieldValue($Address, [string]$Field) {
    if ($null -eq $Address) { return $null }
    $prop = $Address.PSObject.Properties[$Field]
    if ($null -eq $prop) { return $null }
    return [string]$prop.Value
}

foreach ($case in $casesDoc.cases) {
    $lat = [string]$case.lat
    $lon = [string]$case.lon
    $url = "$BaseUrl/reverse?lat=$lat&lon=$lon&key=$Key"

    Write-Host "`n==== $($case.name) ===="
    Write-Host "$lat,$lon"

    try {
        $result = Invoke-RestMethod -Uri $url -TimeoutSec 10
        $address = $result.address

        Write-Host "display_name: $($result.display_name)"
        Write-Host "city: $(Get-AddressFieldValue $address 'city')"
        Write-Host "state: $(Get-AddressFieldValue $address 'state')"
        Write-Host "suburb: $(Get-AddressFieldValue $address 'suburb')"

        if ($null -ne $case.expected) {
            foreach ($expectedProp in $case.expected.PSObject.Properties) {
                $field = $expectedProp.Name
                $expected = [string]$expectedProp.Value
                $actual = Get-AddressFieldValue $address $field

                if ($actual -ne $expected) {
                    Write-Host "FAIL $field: expected '$expected', got '$actual'" -ForegroundColor Red
                    $failures++
                }
            }
        }

        if ($null -ne $case.not_expected) {
            foreach ($notExpectedProp in $case.not_expected.PSObject.Properties) {
                $field = $notExpectedProp.Name
                $notExpected = [string]$notExpectedProp.Value
                $actual = Get-AddressFieldValue $address $field

                if ($actual -eq $notExpected) {
                    Write-Host "FAIL $field: got forbidden value '$notExpected'" -ForegroundColor Red
                    $failures++
                }
            }
        }
    } catch {
        Write-Host "FAIL request: $_" -ForegroundColor Red
        $failures++
    }
}

Write-Host "`n=============================="

if ($failures -gt 0) {
    Write-Host "REGRESSION FAILED: $failures failure(s)" -ForegroundColor Red
    exit 1
}

Write-Host "REGRESSION PASSED" -ForegroundColor Green
exit 0
