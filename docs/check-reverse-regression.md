# Reverse regression command notes

Run the reverse endpoint against a candidate geocoder before production.

PowerShell example:

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:3000/reverse?lat=LAT&lon=LON&key=KEY"
```

Bash example:

```bash
curl -fsS "http://127.0.0.1:3000/reverse?lat=LAT&lon=LON&key=KEY"
```

Expected areas are documented in `docs/regression-cases.md`.
