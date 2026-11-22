# syntax=docker/dockerfile:1

# --- deps: install exactly what package-lock.json pins, on Node 22 ---
FROM node:22-alpine AS deps
WORKDIR /app
# .npmrc carries legacy-peer-deps=true, which this lockfile needs.
COPY package.json package-lock.json .npmrc ./
RUN npm ci

# --- builder: produce a traced Next.js standalone server ---
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# NEXT_PUBLIC_* values are inlined into the client bundle at BUILD time. They
# are build args, never runtime secrets; rebuilding changes their value.
ARG NEXT_PUBLIC_SITE_URL=""
ENV NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL}
# next.config.ts honours TN_DIST_DIR, but the runtime stage below uses the
# default `.next`, so leave TN_DIST_DIR unset here.
RUN npm run build

# --- runtime: only the standalone server and its traced dependencies ---
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    NEXT_TELEMETRY_DISABLED=1

COPY --from=builder /app/.next/standalone ./
# Standalone output intentionally omits these two directories; Next serves
# them at /_next/static and /<public file> respectively.
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Let the unprivileged user write ISR/cache files under .next/cache.
RUN chown -R node:node /app
USER node

EXPOSE 3000

# /api/status is a cheap in-process capability report: no upstream calls.
# Node 22 has global fetch, so no curl/wget is needed in the runtime image.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:' + (process.env.PORT || '3000') + '/api/status').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

CMD ["node", "server.js"]
