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
ARG OPENAI_API_KEY
ARG E2B_API_KEY
ARG FIRECRAWL_API_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY
ENV E2B_API_KEY=$E2B_API_KEY
ENV FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
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
