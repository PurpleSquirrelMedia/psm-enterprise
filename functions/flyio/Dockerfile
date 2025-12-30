# PSM Enterprise - Fly.io Gateway Container
FROM node:20-alpine

WORKDIR /app

# Copy gateway code
COPY unified-api.js ./

# Install dependencies if needed
RUN npm init -y

ENV NODE_ENV=production
ENV PORT=3002

EXPOSE 3002

CMD ["node", "unified-api.js"]
