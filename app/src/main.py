"""
NCAA College Football Game Viewer
Displays upcoming football games for the week using self-hosted NCAA API
"""

import os
import requests
from datetime import datetime, timedelta
from flask import Flask, render_template, jsonify
from dateutil import parser

app = Flask(__name__)

# Configuration
NCAA_API_URL = os.getenv('NCAA_API_URL', 'http://ncaa-api:3000')
NCAA_API_KEY = os.getenv('NCAA_API_KEY', '')

def get_api_headers():
    """Return headers for NCAA API requests"""
    headers = {}
    if NCAA_API_KEY:
        headers['x-ncaa-key'] = NCAA_API_KEY
    return headers

def get_current_season():
    """Get the current football season year"""
    now = datetime.now()
    # Football season typically runs Aug-Jan, so if we're in Jan-July, use previous year
    if now.month < 8:
        return now.year - 1
    return now.year

def get_upcoming_games():
    """Fetch upcoming football games from NCAA API"""
    try:
        season = get_current_season()
        # NCAA API format for football schedule: /scoreboard/football/fbs/YYYY/MM/DD
        
        games = []
        # Get games for the next 7 days
        for i in range(7):
            date = datetime.now() + timedelta(days=i)
            date_str = date.strftime('%Y/%m/%d')
            
            url = f"{NCAA_API_URL}/scoreboard/football/fbs/{date_str}"
            response = requests.get(url, headers=get_api_headers(), timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if 'games' in data:
                    for game in data['games']:
                        games.append({
                            'date': date.strftime('%A, %B %d, %Y'),
                            'time': game.get('startTime', 'TBD'),
                            'home_team': game.get('home', {}).get('names', {}).get('short', 'TBD'),
                            'away_team': game.get('away', {}).get('names', {}).get('short', 'TBD'),
                            'home_score': game.get('home', {}).get('score', ''),
                            'away_score': game.get('away', {}).get('score', ''),
                            'status': game.get('gameState', 'scheduled'),
                            'network': game.get('network', 'N/A'),
                            'game_id': game.get('gameID', ''),
                        })
        
        return games
    except requests.RequestException as e:
        app.logger.error(f"Error fetching games: {e}")
        return []

@app.route('/')
def index():
    """Main page displaying upcoming games"""
    games = get_upcoming_games()
    return render_template('index.html', games=games, total=len(games))

@app.route('/api/games')
def api_games():
    """API endpoint to get games as JSON"""
    games = get_upcoming_games()
    return jsonify({
        'total': len(games),
        'games': games
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/ncaa-status')
def ncaa_status():
    """Check if NCAA API is accessible"""
    try:
        response = requests.get(f"{NCAA_API_URL}/", headers=get_api_headers(), timeout=5)
        return jsonify({
            'status': 'ok' if response.status_code == 200 else 'error',
            'ncaa_api_url': NCAA_API_URL,
            'response_code': response.status_code
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e),
            'ncaa_api_url': NCAA_API_URL
        }), 503

if __name__ == '__main__':
    # Development server
    app.run(host='0.0.0.0', port=5000, debug=True)

