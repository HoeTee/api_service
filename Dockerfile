# Base image with Playwright browsers preinstalled
FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

# Install Node.js 22 so the Playwright MCP CLI works
RUN apt-get update && apt-get install -y curl ca-certificates gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y nodejs \
 && node -v && npm -v \
 && rm -rf /var/lib/apt/lists/*

# Reuse the browsers that come with the base image
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# Install the Playwright MCP CLI globally (provides `playwright-mcp`)
RUN npm install -g @playwright/mcp@latest

# App setup
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 10000
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]
