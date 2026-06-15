FROM node:lts AS builder
WORKDIR /app
RUN apt update && apt install jq -y
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN ./vulnerable-packages.sh

FROM nginx:stable-alpine3.21
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/vulnerable_modules /app/node_modules
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
