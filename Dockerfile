# Base has Python + Playwright browsers preinstalled (Chromium/WebKit/Firefox)
FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

# Sanity check Node/NPM (image ships with Node >= 20)
RUN node -v && npm -v

# Install Playwright MCP CLI globally (so no npx at runtime)
RUN npm install -g @playwright/mcp@latest

# App setup
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your server & agent code
COPY . .

# Render port
ENV PORT=10000
EXPOSE 10000

# Start FastAPI
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]
