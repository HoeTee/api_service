# Use official Python image
FROM python:3.10-slim

# Install Node.js 22 (meets npm@11 engine requirement)
RUN apt-get update && apt-get install -y curl gnupg ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y nodejs \
 && node -v && npm -v

# Install Playwright MCP globally
RUN npm install -g @playwright/mcp@latest
RUN npx -y playwright@1.48.0 install --with-deps chromium

# Set working directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy all app code
COPY . .

# Expose port for Render
EXPOSE 10000

# Start FastAPI server
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]


