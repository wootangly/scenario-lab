# NCAA Football Viewer

A Flask web application that displays upcoming NCAA college football games using a self-hosted NCAA API.

## Architecture

```
┌─────────────────────┐      ┌──────────────────┐
│  Football Viewer    │─────▶│   NCAA API       │
│  (Flask/Python)     │      │  (Node.js)       │
│  Port: 5000         │      │  Port: 3000      │
└─────────────────────┘      └──────────────────┘
         │
         ▼
    Web Browser
```

## Features

- 📅 Shows games for the next 7 days
- 🏈 Beautiful, responsive UI
- 📺 TV network information
- 🔄 Live score updates
- 💪 Production-ready with Gunicorn
- 🏥 Health check endpoints

## Local Development

### Prerequisites

- Python 3.11+
- pip

### Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables (optional)
export NCAA_API_URL="http://localhost:3000"
export NCAA_API_KEY="your-api-key"

# Run development server
python src/main.py
```

Visit http://localhost:5000

### Run with Podman

```bash
# Build image
podman build -t football-viewer .

# Run container
podman run -p 5000:5000 \
  -e NCAA_API_URL=http://ncaa-api:3000 \
  football-viewer
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Main web UI |
| `GET /health` | Health check |
| `GET /api/games` | Get games as JSON |
| `GET /api/ncaa-status` | Check NCAA API connectivity |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NCAA_API_URL` | `http://ncaa-api:3000` | NCAA API service URL |
| `NCAA_API_KEY` | `""` | Optional API key for NCAA API |

## Production Deployment

See [Deployment Guide](../k8s/README.md) for Kubernetes deployment instructions.

## Project Structure

```
app/
├── Dockerfile              # Multi-stage production build
├── requirements.txt        # Python dependencies
└── src/
    ├── main.py            # Flask application
    └── webui/
        └── templates/
            └── index.html # Web UI template
```

## Dependencies

- **Flask 3.0.0**: Web framework
- **Gunicorn 21.2.0**: Production WSGI server
- **Requests 2.31.0**: HTTP client
- **python-dotenv 1.0.0**: Environment variable management
- **python-dateutil 2.8.2**: Date parsing utilities

## Health Checks

The application provides health check endpoints for Kubernetes liveness/readiness probes:

```bash
# Health check
curl http://localhost:5000/health

# NCAA API connectivity check
curl http://localhost:5000/api/ncaa-status
```

## Development Notes

- Uses Gunicorn with 2 workers for production
- Health checks run every 30 seconds
- Request timeout: 10 seconds for NCAA API calls
- Fetches games for 7 days ahead
- Automatically determines current football season

## Troubleshooting

### No games showing

Check NCAA API connectivity:
```bash
curl http://localhost:5000/api/ncaa-status
```

### Connection errors

Verify NCAA API is running:
```bash
# In Kubernetes
kubectl get pods -n scenario-lab
kubectl logs deployment/ncaa-api -n scenario-lab
```

## License

See root project LICENSE file.

