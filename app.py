from flask import Flask, jsonify
import os
from prometheus_client import Counter, Histogram, generate_latest
import time

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration', ['endpoint'])

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    REQUEST_COUNT.labels(method='GET', endpoint='/health').inc()
    return jsonify({'status': 'ok', 'service': 'gitops-app'})

@app.route('/data', methods=['GET'])
def get_data():
    """Return dummy data"""
    start = time.time()
    REQUEST_COUNT.labels(method='GET', endpoint='/data').inc()
    
    data = {
        'message': 'Hello from GitOps App!',
        'version': os.getenv('APP_VERSION', '1.0.0'),
        'environment': os.getenv('ENVIRONMENT', 'production'),
        'items': [
            {'id': 1, 'name': 'Item 1', 'value': 100},
            {'id': 2, 'name': 'Item 2', 'value': 200},
            {'id': 3, 'name': 'Item 3', 'value': 300}
        ]
    }
    
    REQUEST_DURATION.labels(endpoint='/data').observe(time.time() - start)
    return jsonify(data)

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)