FROM python:3.11-slim

WORKDIR /app

# התקן גרסאות עדכניות ותואמות של Flask-SocketIO ותלויות
RUN pip install --no-cache-dir     Flask==3.0.3     Flask-SocketIO==5.3.6     eventlet==0.36.1     python-socketio==5.14.0     gunicorn==22.0.0

COPY . .

ENV FLASK_APP=chat.py
ENV FLASK_ENV=production

# השתמש ב-eventlet כ-WebSocket server (חובה ל-SocketIO)
CMD ["flask", "socketio", "run", "--host=0.0.0.0", "--port=5000"]
