# Stage 1: Build
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

# Create non-root user for security
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /root/.local /home/appuser/.local
COPY app.py .

# Set environment variables
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=1.0.0
ENV ENVIRONMENT=production

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health').read()"

EXPOSE 5000

CMD ["python", "-u", "app.py"]




# # dockerfile 
# # Stage 1: Build stage
# FROM python:3.11-slim AS builder
# WORKDIR /app
# COPY requirements.txt .
# RUN pip install --user --no-cache-dir -r requirements.txt

# # Stage 2: Runtime stage
# FROM python:3.11-slim
# WORKDIR /app
# COPY --from=builder /root/.local /root/.local
# COPY app.py .
# ENV PATH=/root/.local/bin:$PATH
# ENV PYTHONUNBUFFERED=1
# ENV APP_VERSION=1.0.0
# ENV ENVIRONMENT=production
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#     CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health').read()"
# EXPOSE 5000
# CMD ["python", "-u", "app.py"]
