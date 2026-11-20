# RPAScribe server

Receives meeting audio from the app and returns the transcript.
API keys live here, never in the app.

## Run locally
    cd server
    npm install
    GROQ_API_KEY=gsk_... APP_TOKEN=choose-a-long-secret npm start

## Deploy
Any Node 18+ host works (Render, Railway, Fly.io, a VPS). Set `APP_TOKEN` and
either `GROQ_API_KEY` (free tier) or `OPENAI_API_KEY`. The app needs an https URL.

Endpoints:
- GET  /health
- POST /transcribe  (header `x-app-token`, multipart field `audio`)
