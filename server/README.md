# RPAScribe server

Receives meeting audio from the app and returns the transcript.
API keys live here, never in the app.

## Run locally
    cd server
    npm install
    OPENAI_API_KEY=sk-... APP_TOKEN=choose-a-long-secret npm start

## Deploy
Any Node 18+ host works (Render, Railway, Fly.io, a VPS). Set the two
environment variables above. The app needs an https URL.

Endpoints:
- GET  /health
- POST /transcribe  (header `x-app-token`, multipart field `audio`)
