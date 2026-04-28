FROM python:3.12-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml /app/
COPY uv.lock /app/

# Install Python dependencies using uv
RUN uv sync --frozen --no-dev --no-cache-dir

# Copy the application code
COPY memobase_server /app/memobase_server
COPY api.py /app/

# Expose port 8000 (FastAPI default)
EXPOSE 8000

# Wait-for-PG script
COPY wait_for_pg.py /app/wait_for_pg.py

# Wrapper entrypoint: wait for PG → start uvicorn
RUN printf '#!/bin/bash\nset -e\nif [ -n "$DATABASE_URL" ]; then\n  echo "Waiting for PostgreSQL..."\n  /app/.venv/bin/python3 /app/wait_for_pg.py\nfi\nexec /app/.venv/bin/uvicorn api:app --host 0.0.0.0 --port 8000\n' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["/app/entrypoint.sh"]

