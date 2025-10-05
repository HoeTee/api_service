# Use a lightweight Python image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Copy dependency file and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all source code
COPY . .

# Expose port
EXPOSE 10000

# Start the FastAPI server
CMD ["uvicorn", "api_mcp_service_OWUI:app", "--host", "0.0.0.0", "--port", "10000"]
