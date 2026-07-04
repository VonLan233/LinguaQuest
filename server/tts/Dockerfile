FROM python:3.12-slim
RUN pip install --no-cache-dir edge-tts aiohttp
COPY server.py /app/server.py
WORKDIR /app
EXPOSE 5002
CMD ["python", "server.py"]
