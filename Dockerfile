# Playwright image (Python + Node + browsers preinstalled)
FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Playwright MCP server (Node already available in this image)
RUN npm install -g @playwright/mcp@latest

# Your app code
COPY . .

EXPOSE 10000
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]
