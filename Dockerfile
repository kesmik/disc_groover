FROM python:3.12-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openscad \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

ENV QT_QPA_PLATFORM=offscreen \
    GROOVER_OUTPUT_DIR=/output \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY generate.py disc_groover.scad ./

ENTRYPOINT ["python", "/app/generate.py"]
