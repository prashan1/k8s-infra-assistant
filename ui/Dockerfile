# Build context is the ui/ folder:  docker build -t rag-ui ./ui

# ---------- Stage 1: builder ----------
FROM python:3.11-slim-bookworm AS builder
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --prefer-binary -r requirements.txt

# ---------- Stage 2: runtime ----------
FROM python:3.11-slim-bookworm AS runtime
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

WORKDIR /app
COPY --chown=appuser:appuser app.py .

USER appuser
EXPOSE 8501

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8501/_stcore/health', timeout=4).status==200 else 1)"

# headless: no "open browser" prompt. Listens on all interfaces so the Service can reach it.
CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501", "--server.headless=true"]
