# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
    gcc \
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /install /usr/local
COPY ./app .

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5001
CMD ["flask", "run", "--host=0.0.0.0", "--port=5001"]