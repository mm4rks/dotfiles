FROM node:22-slim

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN npm install -g opencode-ai opencode-gemini-auth opencode-anthropic-auth

ENTRYPOINT ["opencode"]
