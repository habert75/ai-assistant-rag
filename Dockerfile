FROM python:3.13-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app.py .
COPY simplified_rag/ simplified_rag/
COPY .streamlit .streamlit

# Create docs directory for runtime uploads
RUN mkdir -p docs

# Expose the configured port
EXPOSE 8503

# Run the application
CMD ["streamlit", "run", "app.py", "--server.address", "0.0.0.0"]
