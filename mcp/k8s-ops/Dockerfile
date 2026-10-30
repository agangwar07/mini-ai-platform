FROM python:3.12-slim
RUN useradd --system --uid 10001 mcp
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server.py .
USER 10001
EXPOSE 8000
CMD ["python", "server.py"]
