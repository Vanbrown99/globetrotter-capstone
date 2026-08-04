# Recommendation Service

Minimal recommendation service for Phase 2. Runs on port 5300 by default.

Endpoints:
- GET / -> service info
- GET /health -> health check
- GET /recommendations -> returns top destinations from ../data/destinations.json

Run: `python app.py`