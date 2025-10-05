# Use official Python image
FROM python:3.10-slim

# Install Node.js and npm
RUN apt-get update && apt-get install -y curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright MCP globally
RUN npm install -g @playwright/mcp@latest

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
