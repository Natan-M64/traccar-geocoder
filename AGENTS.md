# Traccar Geocoder

A fast, self-hosted reverse geocoding service built from OpenStreetMap data. It provides street-level reverse geocoding and admin boundary resolution with sub-millisecond latency.

## Project Overview

The project is split into two primary components:
1.  **Builder (C++):** A high-performance indexer that parses OSM PBF files and creates a compact binary spatial index using S2 geometry.
2.  **Server (Rust):** A high-performance web server that memory-maps the binary index files and serves geocoding requests via HTTP/HTTPS.

### Key Technologies
-   **C++17:** Used for the builder, leveraging `libosmium` and `s2geometry`.
-   **Rust:** Used for the server, leveraging `axum`, `tokio`, and `memmap2`.
-   **S2 Geometry:** Used for efficient spatial indexing and lookup.
-   **Docker:** Multi-stage build for easy deployment.

## Directory Structure

-   `builder/`: Source code for the C++ indexer.
    -   `src/build_index.cpp`: Main entry point for the indexer.
    -   `src/address_levels.hpp`: Logic for address level mapping.
-   `server/`: Source code for the Rust web server.
    -   `src/main.rs`: Main entry point for the server, handling query logic and memory mapping.
    -   `src/auth.rs`: Authentication and API key management.
    -   `src/web/`: HTML templates for the dashboard.
-   `docs/`: Project documentation and protocols.
    -   `merge-release-protocol.md`: Validation steps for merging and releases.
    -   `regression-cases.md`: Detailed notes on specific regression scenarios.
-   `tests/`: Test suites and regression cases.
    -   `reverse-regression-cases.json`: Critical reverse-geocoding test data.
-   `scripts/`: Utility scripts for maintenance and testing.
    -   `check-reverse-regression.sh`: Bash script for running regression tests.
    -   `check-reverse-regression.ps1`: PowerShell script for running regression tests.
-   `Dockerfile` & `docker-compose.yml`: Containerization and orchestration.
-   `entrypoint.sh`: Orchestrates PBF download, index building, and server startup in Docker.

## Building and Running

### Manual Build

**Builder (C++):**
```bash
mkdir build && cd build
cmake ../builder
make
```

**Server (Rust):**
```bash
cd server
cargo build --release
```

### Running

**Building the Index:**
```bash
./build/build-index <data-dir>/index <input.osm.pbf>
```

**Starting the Server:**
```bash
./server/target/release/query-server <data-dir> [bind-address]
```

### Testing

**Running Regression Tests:**
```bash
# Using Bash
./scripts/check-reverse-regression.sh --base-url http://localhost:3000 --key YOUR_KEY

# Using PowerShell
.\scripts\check-reverse-regression.ps1 -BaseUrl http://localhost:3000 -Key YOUR_KEY
```

### Docker

Use Docker Compose for a quick start:
```bash
docker compose up
```

Environment variables like `PBF_URLS`, `DOMAIN`, and `BIND_ADDR` can be used to configure the service.

## Development Conventions

-   **Performance:** The server relies on memory-mapping (`memmap2`) for fast access to large index files.
-   **Spatial Index:** S2 cells are used throughout for indexing streets, addresses, and admin boundaries.
-   **Authentication:** Includes a built-in dashboard for API key management, with optional environment-based bootstrapping.
-   **Multi-stage Docker:** The `Dockerfile` carefully separates the C++ and Rust build stages to produce a lean runtime image.
-   **Regression Testing:** Always run the reverse regression scripts before a release to ensure accuracy in critical areas.

## Key Files for Reference
-   `README.md`: Comprehensive usage and API documentation.
-   `builder/src/build_index.cpp`: Core indexing logic.
-   `server/src/main.rs`: Core query and serving logic.
-   `entrypoint.sh`: Logic for automated Docker deployments.
-   `docs/merge-release-protocol.md`: Essential reading for contributors before submitting PRs.
