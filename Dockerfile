FROM node:lts-alpine AS builder
WORKDIR /app
RUN apk add --no-cache jq
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN ./vulnerable-packages.sh

FROM nginx:stable-alpine
RUN addgroup -g 101 -S nginx-app && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx-app nginx-app
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/vulnerable_modules /app/node_modules
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown -R nginx-app:nginx-app /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d

USER nginx-app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
