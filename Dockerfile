# ---------- Stage 1: builder (has compilers; never shipped) ----------
FROM python:3.11-slim-bookworm AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends gcc g++ \
    && rm -rf /var/lib/apt/lists/*

# Isolated venv so the runtime stage can copy one self-contained folder
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Requirements first: this layer is cached until requirements-prod.txt changes
COPY requirements-prod.txt .
RUN pip install --prefer-binary -r requirements-prod.txt

# Bake ML models into the image so pods never download them at startup
ENV FASTEMBED_CACHE_PATH=/opt/models/fastembed
RUN python -c "from flashrank import Ranker; Ranker(cache_dir='/opt/models/flashrank')" \
    && python -c "from fastembed import TextEmbedding; TextEmbedding('sentence-transformers/all-MiniLM-L6-v2')"


# ---------- Stage 2: runtime (slim, non-root, no compilers) ----------
FROM python:3.11-slim-bookworm AS runtime

# libgomp1 = OpenMP runtime needed by onnxruntime; OS patches applied
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/models /opt/models

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASHRANK_CACHE_DIR=/opt/models/flashrank \
    FASTEMBED_CACHE_PATH=/opt/models/fastembed

WORKDIR /app
COPY --chown=appuser:appuser app/ ./app/

USER appuser
EXPOSE 8080

# No curl in slim image; use Python. Kubernetes probes will replace this later.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=4).status==200 else 1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
