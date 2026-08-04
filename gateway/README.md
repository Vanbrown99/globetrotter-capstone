# API Gateway

Simple gateway that proxies requests to the microservices:

- User service: http://127.0.0.1:5100
- Itinerary service: http://127.0.0.1:5200
- Recommendation service: http://127.0.0.1:5300

Gateway listens on port 5400 and exposes `/api/<path>` which routes to the appropriate backend.

Run locally:

```bash
python app.py
```

Example: `http://127.0.0.1:5400/api/register` will forward to the user service.
