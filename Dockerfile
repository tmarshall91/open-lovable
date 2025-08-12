# Install dependencies
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install --no-frozen-lockfile

# Build the app
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# ---- ADD THIS LINE ----
ARG OPENAI_API_KEY
# This line tells the builder to expect a build-time argument named OPENAI_API_KEY.
# ---- ADD THIS LINE ----
ENV OPENAI_API_KEY=$OPENAI_API_KEY
# This line sets that argument as an environment variable that the build script can use.
RUN npm install -g pnpm && pnpm build

# Run the app
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
