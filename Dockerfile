# Python + Node + Playwright browsers preinstalled (needed for Playwright MCP)
FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

WORKDIR /app

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install the Playwright MCP server globally so we don't npx-install at runtime
RUN npm install -g @playwright/mcp@latest

# Your app code
COPY . .

# Render maps its own port; default to 10000 for local
ENV PORT=10000

# Start FastAPI (change module name if your file differs)
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]
