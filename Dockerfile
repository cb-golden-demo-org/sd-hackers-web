FROM node:lts AS builder
WORKDIR /app
RUN apk add --no-cache jq
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN ./vulnerable-packages.sh

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/vulnerable_modules /app/node_modules
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

USER appuser

ENTRYPOINT ["/entrypoint.sh"]
