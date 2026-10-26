FROM openscad/openscad:dev.2026-10-20

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

ENV QT_QPA_PLATFORM=offscreen \
    GROOVER_OUTPUT_DIR=/output \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY generate.py disc_groover.scad ./

ENTRYPOINT ["python3", "/app/generate.py"]