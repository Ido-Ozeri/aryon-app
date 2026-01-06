ARG BASE_IMAGE=python-base:latest
FROM ${BASE_IMAGE} AS builder

USER root

WORKDIR /app

COPY requirements.txt .

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-compile --target=/app/deps -r requirements.txt

FROM ${BASE_IMAGE}

USER root

COPY --from=builder /app/deps /usr/local/lib/python3.12/site-packages

COPY --chown=${APP_USER}:${APP_USER} app.py .

USER ${APP_USER}

CMD ["sh", "-c", "python app.py"]
