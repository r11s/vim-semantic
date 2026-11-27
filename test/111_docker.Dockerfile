# syntax=docker/dockerfile:1
# Formen-Rechner als Image. TODO: kleinere Basis
ARG VERSION=3.12
FROM python:${VERSION}-slim AS bauen

LABEL org.opencontainers.image.title="Formen-Rechner" \
      version="1.0"
MAINTAINER team@example.org
ENV PATH="/opt/formen/bin:$PATH" DEBUG=0
WORKDIR /opt/formen

COPY --chown=app:app requirements.txt ./
ADD ["daten.tar.gz", "/opt/daten/"]
RUN apt-get update && apt-get install -y --no-install-recommends gcc \
    # Kommentar in der Fortsetzung
    && pip install -r requirements.txt \
    && rm -rf "/var/lib/apt/lists/*"
RUN if [ "$DEBUG" = "1" ]; then echo 'Debug an'; fi; for f in *.py; do python -m py_compile "$f"; done
RUN ["python", "-c", "print(42)"]

from alpine:3.20
copy --from=bauen /opt/formen /opt/formen
USER 1000:1000
VOLUME ["/daten"]
EXPOSE 8080/tcp
SHELL ["/bin/ash", "-c"]
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8080/ || exit 1
ONBUILD RUN echo "gebaut"
ENTRYPOINT ["/opt/formen/start.sh"]
CMD python app.py --port 8080 # kein Kommentar
