FROM alpine:latest

ARG GITHUB_AUTH
ARG FILE_DIR
ARG PATH_HELM
ARG IMAGE_NAME
ARG SSO_SHARED_SECRET=""

RUN apk update && \
    apk add --no-cache \
    git \
    yq

RUN git clone https://$GITHUB_AUTH@github.com/picap-inc/secrets.git /app
WORKDIR /app/$FILE_DIR

RUN yq -i ".image.repository = \"$IMAGE_NAME\"" $PATH_HELM
RUN if [ -n "$SSO_SHARED_SECRET" ]; then yq -i ".env.SSO_SHARED_SECRET = \"$SSO_SHARED_SECRET\"" $PATH_HELM; fi

RUN git config --global user.email "it@picap.co" && \
    git config --global user.name "It Picap"

RUN git add . && \
    git commit -m "New image version $IMAGE_NAME" && \
    git pull --rebase origin main && \
    git push origin main

RUN apk del git yq && \
    rm -rf /var/cache/apk/* \
    rm -rf /app/*

CMD ["sh"]
