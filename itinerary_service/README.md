# Itinerary Service

Minimal itinerary service for Phase 2. Runs on port 5200 by default.

Endpoints:
- GET / -> service info
- GET /health -> health check
- GET /itineraries -> list from ../data/itineraries.json
- POST /itineraries -> append itinerary to file

Run: `python app.py`