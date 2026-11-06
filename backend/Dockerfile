# ==============================================================================
# DayBook Backend Multi-Stage Production Dockerfile
# ==============================================================================

FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json tsconfig.json ./
RUN npm ci --ignore-scripts

COPY src/ ./src/
RUN npm run build

# --- Production Runner ---
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4000

# Security: run as unprivileged node user
USER node

COPY --chown=node:node package*.json ./
RUN npm ci --only=production --ignore-scripts && npm cache clean --force

COPY --chown=node:node --from=builder /app/dist ./dist

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/api/v1/health || exit 1

CMD ["node", "dist/main.js"]
