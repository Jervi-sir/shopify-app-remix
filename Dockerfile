FROM node:18-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production

RUN npm install --omit=dev
RUN npm remove @shopify/app @shopify/cli

RUN npm run build && npm cache clean --force

# You'll probably want to remove this in production, it's here to make it easier to test things!
RUN rm -f prisma/dev.sqlite

FROM base AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 remix
COPY --from=builder /app .
USER remix
EXPOSE 3000
ENV PORT 3000
CMD ["npm", "run", "docker-start"]