FROM python:3.7.4-alpine3.10

ADD requirements.txt /app/requirements.txt

RUN set -ex \
    && python -m venv /env \
    && /env/bin/pip install --upgrade pip \
    && /env/bin/pip install --no-cache-dir -r /app/requirements.txt \
    && runDeps="$(scanelf --needed --nobanner --recursive /env \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u)" \
    && apk add --virtual rundeps $runDeps

ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

ADD th3-server.py /app
WORKDIR /app

EXPOSE 8080

CMD [ "python3", "th3-server.py" ]
