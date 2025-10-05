# 1) Base image with Playwright browsers preinstalled (Ubuntu 22.04)
FROM mcr.microsoft.com/playwright:v1.48.0-jammy

# 2) Install Python 3 + pip
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
 && ln -sf /usr/bin/python3 /usr/bin/python \
 && ln -sf /usr/bin/pip3 /usr/bin/pip \
 && rm -rf /var/lib/apt/lists/*

# 3) Install the Playwright MCP server globally
RUN npm install -g @playwright/mcp@latest

# (Safety) Allow old binary name if your code uses it
RUN ln -sf /usr/local/bin/mcp-server-playwright /usr/local/bin/playwright-mcp

# 4) Workdir
WORKDIR /app

# 5) Install Python deps first (cache-friendly)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6) Copy the app code
COPY . .

# 7) Env + port
ENV PYTHONUNBUFFERED=1
EXPOSE 10000

# 8) Start FastAPI
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]
