# ---------- Stage 1: Build ----------
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files first for caching
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build admin panel
RUN npm run build


# ---------- Stage 2: Runtime ----------
FROM node:18-alpine

WORKDIR /app

ENV NODE_ENV=production

# install only production deps
COPY package*.json ./
RUN npm install --production

# Copy built app
COPY --from=build /app /app

EXPOSE 1337

CMD ["npm", "run", "start"]




