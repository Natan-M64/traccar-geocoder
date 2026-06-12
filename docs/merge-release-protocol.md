# Merge and release protocol

This document defines the minimum validation flow before deploying a custom geocoder build.

Core rule:

> Merge is not a release. A build is not production. Production happens only after staging and reverse-geocoding regression checks.

## Required flow

1. Keep each PR focused on a single change.
2. Review critical files before merging.
3. Run Rust checks.
4. Start the candidate geocoder locally or in staging.
5. Run the reverse regression scripts.
6. Deploy only after the exact candidate image passes.

## Critical files

```text
server/src/main.rs
builder/src/build_index.cpp
Dockerfile
docker-compose.yml
server/Cargo.toml
server/Cargo.lock
```

## Basic checks

```bash
cargo fmt --check --manifest-path server/Cargo.toml
cargo check --manifest-path server/Cargo.toml
cargo test --manifest-path server/Cargo.toml
```

## Reverse regression scripts

Cases are stored in:

```text
tests/reverse-regression-cases.json
```

Run with PowerShell:

```powershell
.\scripts\check-reverse-regression.ps1 -BaseUrl "http://127.0.0.1:3000" -Key "X"
```

Run with Bash:

```bash
./scripts/check-reverse-regression.sh --base-url "http://127.0.0.1:3000" --key "X"
```

## Pre-merge checklist

```text
[ ] PR has a single scope
[ ] Critical files were reviewed
[ ] Rust checks passed
[ ] Candidate server started locally or in staging
[ ] Reverse regression passed
```

## Pre-production checklist

```text
[ ] Image uses an immutable tag
[ ] Staging runs the exact image planned for production
[ ] Reverse regression passed in staging
[ ] Rollback image tag is documented
[ ] Production deployment window is clear
```

## Post-production checklist

```text
[ ] Reverse regression passed against production URL
[ ] Container logs were checked
[ ] A real Traccar reverse-geocoded position was validated
```

## Rollback rule

Always record the previous image tag before deployment. Rollback means returning the stack to the previous immutable image tag and recreating the container.
