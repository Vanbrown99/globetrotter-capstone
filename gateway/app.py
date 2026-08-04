from flask import Flask, request, jsonify, make_response
import requests
from urllib.parse import urljoin

app = Flask(__name__)

# Backend service mapping
SERVICES = {
    'user': 'http://127.0.0.1:5100',
    'itinerary': 'http://127.0.0.1:5200',
    'recommendation': 'http://127.0.0.1:5300',
}

# Rudimentary routing rules (map leading path segment to service)
USER_PREFIXES = {'register', 'login', 'me', 'forgot-password', 'reset-password', 'users'}
ITINERARY_PREFIXES = {'itineraries'}
RECOMMENDATION_PREFIXES = {'recommendations'}

HOP_BY_HOP = {
    'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization',
    'te', 'trailer', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length'
}


def choose_service(path_segment: str):
    if path_segment in USER_PREFIXES:
        return SERVICES['user']
    if path_segment in ITINERARY_PREFIXES:
        return SERVICES['itinerary']
    if path_segment in RECOMMENDATION_PREFIXES:
        return SERVICES['recommendation']
    # default: try user service for auth-like endpoints, else recommendation
    return SERVICES['user']


@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    return response


@app.route('/')
def index():
    return jsonify({
        'service': 'api-gateway',
        'routes': {
            'user': list(USER_PREFIXES),
            'itinerary': list(ITINERARY_PREFIXES),
            'recommendation': list(RECOMMENDATION_PREFIXES),
        }
    })


@app.route('/api/<path:path>', methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'])
def proxy(path):
    # Determine target service by the first path segment
    first_segment = path.split('/')[0] if path else ''
    target_base = choose_service(first_segment)
    target_url = urljoin(target_base + '/', path)

    # Build headers, strip hop-by-hop
    out_headers = {k: v for k, v in request.headers.items() if k.lower() not in HOP_BY_HOP}

    # Forward the request
    try:
        resp = requests.request(
            method=request.method,
            url=target_url,
            headers=out_headers,
            params=request.args,
            json=request.get_json(silent=True) if request.method in ('POST', 'PUT', 'PATCH') else None,
            timeout=5,
        )
    except requests.RequestException as e:
        return jsonify({'error': 'upstream request failed', 'details': str(e)}), 502

    # Build Flask response
    response = make_response(resp.content, resp.status_code)
    for k, v in resp.headers.items():
        if k.lower() in HOP_BY_HOP:
            continue
        response.headers[k] = v
    return response


if __name__ == '__main__':
    app.run(port=5400, host='0.0.0.0')
