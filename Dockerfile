FROM node:20-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install

COPY . .

RUN python3 -m pip install --break-system-packages --upgrade pip
RUN python3 -m pip install --break-system-packages -r src/resume_analyzer/requirements.txt

EXPOSE 8080

CMD sh -c "cd src/resume_analyzer && python3 app.py & cd /app && node server.js"