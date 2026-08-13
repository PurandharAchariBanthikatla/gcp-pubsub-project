FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY push_receiver.py .

ENV PORT=8080
CMD exec gunicorn --bind :$PORT --workers 2 --threads 4 push_receiver:app
