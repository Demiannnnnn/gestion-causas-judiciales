# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /install /usr/local
COPY ./app .

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

CMD ["flask", "run", "--host=0.0.0.0", "--port=8004"]
