import express from "express";
import multer from "multer";

const { OPENAI_API_KEY, APP_TOKEN, PORT = 3000 } = process.env;
if (!OPENAI_API_KEY || !APP_TOKEN) {
  console.error("Set OPENAI_API_KEY and APP_TOKEN environment variables.");
  process.exit(1);
}

const app = express();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 }, // Whisper API limit
});

function auth(req, res, next) {
  if (req.get("x-app-token") !== APP_TOKEN) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
}

app.get("/health", (_req, res) => res.json({ ok: true }));

app.post("/transcribe", auth, upload.single("audio"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No audio file" });
  try {
    const form = new FormData();
    form.append(
      "file",
      new Blob([req.file.buffer]),
      req.file.originalname || "meeting.m4a"
    );
    form.append("model", "whisper-1");
    form.append("response_format", "json");

    const r = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
      body: form,
    });
    const data = await r.json();
    if (!r.ok) {
      console.error("Transcription failed", data);
      return res.status(502).json({ error: "Transcription failed" });
    }
    res.json({ text: data.text });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
});

app.use((err, _req, res, _next) => {
  if (err.code === "LIMIT_FILE_SIZE") {
    return res.status(413).json({ error: "Recording is over 25 MB" });
  }
  console.error(err);
  res.status(500).json({ error: "Server error" });
});

app.listen(PORT, () => console.log(`RPAScribe server on :${PORT}`));
