FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY application.py .
COPY tests/ ./tests/

# Gunicorn binds 0.0.0.0:8000
ENV PYTHONUNBUFFERED=1
CMD ["gunicorn", "-w", "3", "-b", "0.0.0.0:8000", "application:app"]
