# Swar Mangal backend (Next.js RPC gateway) + Google Sheets mirror worker.
# One image, two commands: `npm start` (app) and `node sync/worker.mjs` (mirror).
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.ts ./next.config.ts
COPY --from=build /app/db ./db
COPY --from=build /app/sync ./sync
USER node
EXPOSE 3000
# prestart applies the schema and one-time migrations before the server starts
CMD ["npm", "start"]
