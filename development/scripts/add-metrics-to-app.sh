#!/bin/bash

# Add Prometheus metrics support to the Flask chat application

set -e

APP_DIR="Flask-SocketIO-Chat"
REQUIREMENTS_FILE="${APP_DIR}/requirements.txt"
CHAT_PY="${APP_DIR}/chat.py"

echo "Adding Prometheus metrics support to chat application..."

# Add prometheus dependencies to requirements.txt
if ! grep -q "prometheus-flask-exporter" "$REQUIREMENTS_FILE"; then
    echo "# Prometheus metrics" >> "$REQUIREMENTS_FILE"
    echo "prometheus-flask-exporter==0.23.0" >> "$REQUIREMENTS_FILE"
    echo "✅ Added prometheus-flask-exporter to requirements.txt"
else
    echo "✅ Prometheus metrics already in requirements.txt"
fi

# Update the main application file to include metrics
if [ -f "$CHAT_PY" ]; then
    # Check if metrics are already added
    if ! grep -q "PrometheusMetrics" "$CHAT_PY"; then
        # Add import after Flask import
        sed -i '/from flask import Flask/a from prometheus_flask_exporter import PrometheusMetrics' "$CHAT_PY"

        # Add metrics initialization after app creation
        sed -i '/app = create_app/a metrics = PrometheusMetrics(app)' "$CHAT_PY"

        echo "✅ Added Prometheus metrics to chat.py"
    else
        echo "✅ Prometheus metrics already configured in chat.py"
    fi
else
    echo "❌ chat.py not found"
    exit 1
fi

echo ""
echo "Metrics setup complete!"
echo "The application will now expose metrics at /metrics endpoint"
echo ""
echo "Rebuild the container after making these changes:"
echo "  ./scripts/build-and-push.sh"
