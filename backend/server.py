from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json
import math
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR) if os.path.basename(BASE_DIR) == 'backend' else BASE_DIR
app = Flask(__name__)
CORS(app)

DEALERS = [
    {
        'id': '1',
        'name': 'Kisumu Agrovet',
        'phone': '+254712345678',
        'email': 'info@kisumuagrovet.co.ke',
        'address': 'Kisumu, Kenya',
        'latitude': -0.1022,
        'longitude': 34.7617,
        'products': ['Seeds', 'Fertilizer', 'Pesticides'],
        'is_verified': True,
        'is_sponsored': True,
        'is_active': True,
    },
    {
        'id': '2',
        'name': 'Nakuru Farm Inputs',
        'phone': '+254723456789',
        'email': 'info@nakurufarm.co.ke',
        'address': 'Nakuru, Kenya',
        'latitude': -0.3031,
        'longitude': 36.0663,
        'products': ['Seeds', 'Chemicals', 'Tools'],
        'is_verified': True,
        'is_sponsored': False,
        'is_active': True,
    },
    {
        'id': '3',
        'name': 'Eldoret Seeds & Chemicals',
        'phone': '+254734567890',
        'email': 'info@eldoretseeds.co.ke',
        'address': 'Eldoret, Kenya',
        'latitude': 0.5143,
        'longitude': 35.2698,
        'products': ['Seeds', 'Herbicides', 'Fungicides'],
        'is_verified': False,
        'is_sponsored': True,
        'is_active': True,
    },
]

SCANS = []
FEEDBACKS = []


def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


@app.route('/health')
def health():
    return jsonify({
        'status': 'ok',
        'timestamp': '2026-07-23T19:00:00Z',
        'version': '1.0.0'
    })


@app.route('/')
def index():
    return send_from_directory(PROJECT_ROOT, 'index.html')


@app.route('/<path:path>')
def static_files(path):
    return send_from_directory(PROJECT_ROOT, path)


@app.route('/api/dealers', methods=['GET'])
def get_dealers():
    lat = request.args.get('lat', type=float)
    lng = request.args.get('lng', type=float)
    radius = request.args.get('radius', 50, type=float)

    if lat is None or lng is None:
        return jsonify({'error': 'Latitude and longitude required'}), 400

    results = []
    for dealer in DEALERS:
        dist = haversine(lat, lng, dealer['latitude'], dealer['longitude'])
        if dist <= radius:
            entry = dict(dealer)
            entry['distance_km'] = round(dist, 2)
            results.append(entry)

    results.sort(key=lambda x: (x.get('distance_km', 9999), not x.get('is_sponsored', False)))

    return jsonify({
        'success': True,
        'count': len(results),
        'radius_km': radius,
        'dealers': results
    })


@app.route('/api/dealers/<dealer_id>', methods=['GET'])
def get_dealer_by_id(dealer_id):
    for dealer in DEALERS:
        if dealer['id'] == dealer_id:
            return jsonify({'success': True, 'dealer': dealer})
    return jsonify({'error': 'Dealer not found'}), 404


@app.route('/api/dealers', methods=['POST'])
def register_dealer():
    data = request.get_json() or {}
    required = ['name', 'phone', 'email', 'address', 'latitude', 'longitude']
    if not all(field in data for field in required):
        return jsonify({'error': 'Missing required fields'}), 400
    new_dealer = {
        'id': str(len(DEALERS) + 1),
        'name': data['name'],
        'phone': data['phone'],
        'email': data['email'],
        'address': data['address'],
        'latitude': float(data['latitude']),
        'longitude': float(data['longitude']),
        'products': data.get('products', []),
        'is_verified': False,
        'is_sponsored': False,
        'is_active': True,
    }
    DEALERS.append(new_dealer)
    return jsonify({'success': True, 'message': 'Dealer registered successfully', 'dealer': new_dealer}), 201


@app.route('/api/dealers/<dealer_id>', methods=['PUT'])
def update_dealer(dealer_id):
    data = request.get_json() or {}
    for dealer in DEALERS:
        if dealer['id'] == dealer_id:
            allowed = ['name', 'phone', 'email', 'address', 'latitude', 'longitude', 'products', 'is_active']
            for key in allowed:
                if key in data:
                    dealer[key] = data[key]
            return jsonify({'success': True, 'dealer': dealer})
    return jsonify({'error': 'Dealer not found'}), 404


@app.route('/api/diagnose/log', methods=['POST'])
def log_diagnosis():
    data = request.get_json() or {}
    required = ['scan_id', 'disease', 'confidence']
    if not all(field in data for field in required):
        return jsonify({'error': 'Missing required fields'}), 400

    scan = {
        'scan_id': data['scan_id'],
        'user_id': data.get('user_id'),
        'disease_name': data['disease'],
        'confidence': float(data['confidence']),
        'confidence_tier': data.get('confidence_tier', 'high' if float(data['confidence']) >= 0.75 else 'uncertain'),
        'severity': data.get('severity'),
        'crop_type': data.get('crop_type', 'Unknown'),
        'latitude': data.get('lat'),
        'longitude': data.get('lng'),
        'scanned_at': data.get('timestamp'),
        'created_at': '2026-07-23T19:00:00Z'
    }
    SCANS.append(scan)
    return jsonify({'success': True, 'message': 'Scan logged successfully', 'data': scan}), 201


@app.route('/api/diagnose/feedback', methods=['POST'])
def submit_feedback():
    data = request.get_json() or {}
    if 'scan_id' not in data or 'was_correct' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    feedback = {
        'scan_id': data['scan_id'],
        'user_id': data.get('user_id'),
        'was_correct': bool(data['was_correct']),
        'correct_disease': data.get('correct_disease'),
        'submitted_at': '2026-07-23T19:00:00Z'
    }
    FEEDBACKS.append(feedback)
    return jsonify({'success': True, 'message': 'Feedback recorded', 'data': feedback}), 201


@app.route('/api/diagnose/stats', methods=['GET'])
def get_regional_stats():
    county = request.args.get('county')
    days = request.args.get('days', 30, type=int)

    stats = {}
    for scan in SCANS:
        name = scan['disease_name']
        crop = scan['crop_type']
        key = (name, crop)
        if key not in stats:
            stats[key] = {
                'disease_name': name,
                'crop_type': crop,
                'total_cases': 0,
                'avg_confidence': 0.0,
                'affected_farmers': set()
            }
        stats[key]['total_cases'] += 1
        stats[key]['avg_confidence'] += scan['confidence']
        if scan.get('user_id'):
            stats[key]['affected_farmers'].add(scan['user_id'])

    result = []
    for item in stats.values():
        result.append({
            'disease_name': item['disease_name'],
            'crop_type': item['crop_type'],
            'total_cases': item['total_cases'],
            'avg_confidence': round(item['avg_confidence'] / item['total_cases'], 2) if item['total_cases'] else 0.0,
            'affected_farmers': len(item['affected_farmers'])
        })

    result.sort(key=lambda x: x['total_cases'], reverse=True)
    return jsonify({'success': True, 'data': result[:20]})


@app.route('/api/diagnose/heatmap', methods=['GET'])
def get_heatmap():
    region = request.args.get('region')
    crop = request.args.get('crop')
    days = request.args.get('days', 30, type=int)

    filtered = SCANS
    if region:
        filtered = [s for s in filtered if (s.get('latitude') and s.get('longitude'))]
    if crop:
        filtered = [s for s in filtered if s['crop_type'] == crop]

    aggregated = {}
    for scan in filtered:
        if scan.get('latitude') is None or scan.get('longitude') is None:
            continue
        key = (scan['latitude'], scan['longitude'], scan['disease_name'], scan['crop_type'])
        if key not in aggregated:
            aggregated[key] = {
                'latitude': scan['latitude'],
                'longitude': scan['longitude'],
                'disease_name': scan['disease_name'],
                'crop_type': scan['crop_type'],
                'case_count': 0,
                'avg_confidence': 0.0
            }
        aggregated[key]['case_count'] += 1
        aggregated[key]['avg_confidence'] += scan['confidence']

    result = []
    for item in aggregated.values():
        if item['case_count'] >= 3:
            item['avg_confidence'] = round(item['avg_confidence'] / item['case_count'], 2)
            result.append(item)

    result.sort(key=lambda x: x['case_count'], reverse=True)
    return jsonify({'success': True, 'count': len(result), 'data': result})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=False)
