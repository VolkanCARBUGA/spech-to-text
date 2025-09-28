from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from faster_whisper import WhisperModel
import shutil
import os
import uuid

app = FastAPI()

model = WhisperModel("small", device="cpu", compute_type="int8")

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    file_id = str(uuid.uuid4())
    temp_file = f"temp_{file_id}.mp3"

    with open(temp_file, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    segments, info = model.transcribe(temp_file, beam_size=3, vad_filter=True)

    text_result = " ".join([s.text for s in segments])

    os.remove(temp_file)

    return JSONResponse({
        "language": info.language,
        "language_probability": round(info.language_probability, 2),
        "transcription": text_result.strip()
    })

@app.get("/")
def root():
    return {"message": "Speech to Text API çalışıyor!"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
