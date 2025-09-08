# ===== GEREKLİ KÜTÜPHANELERİ İMPORT EDİYORUZ =====
from fastapi import FastAPI, File, UploadFile  # FastAPI: REST API oluşturmak için ana kütüphane, File/UploadFile: Dosya yükleme işlemleri için
from fastapi.responses import JSONResponse      # JSON formatında HTTP cevabı döndürmek için
from faster_whisper import WhisperModel        # OpenAI'nin Whisper modelini kullanarak ses dosyalarını metne çevirmek için
import shutil                                  # Dosya kopyalama işlemleri için (shutil.copyfileobj)
import os                                      # İşletim sistemi işlemleri için (dosya silme, yol işlemleri)
import uuid                                    # Benzersiz tanımlayıcılar (UUID) oluşturmak için

# ===== FASTAPI UYGULAMASINI BAŞLATIYORUZ =====
app = FastAPI()                               # Yeni bir FastAPI uygulaması oluşturuyoruz

# ===== WHISPER MODELİNİ YÜKLÜYORUZ =====
# Model sadece bir kez yüklenir, sonraki isteklerde tekrar yüklenmez (performans için)
model = WhisperModel("small", device="cpu", compute_type="int8")  # "small" modeli: Türkçe dahil çok dilli, CPU'da çalışır, 8-bit hesaplama

# ===== SES DOSYASINI METNE ÇEVİREN ANA ENDPOINT =====
@app.post("/transcribe")                      # POST isteği ile /transcribe adresine gelen istekleri karşılar
async def transcribe_audio(file: UploadFile = File(...)):  # async fonksiyon: Dosya yükleme işlemi asenkron yapılır
    # ===== GEÇİCİ DOSYA OLUŞTURMA =====
    file_id = str(uuid.uuid4())               # Benzersiz bir dosya adı oluşturuyoruz (örn: "550e8400-e29b-41d4-a716-446655440000")
    temp_file = f"temp_{file_id}.mp3"         # Geçici dosya adını oluşturuyoruz (örn: "temp_550e8400-e29b-41d4-a716-446655440000.mp3")

    # ===== YÜKLENEN DOSYAYI DISKE KAYDETME =====
    with open(temp_file, "wb") as buffer:     # Geçici dosyayı binary write modunda açıyoruz
        shutil.copyfileobj(file.file, buffer) # Yüklenen dosyayı geçici dosyaya kopyalıyoruz (chunk by chunk)

    # ===== SES DOSYASINI METNE ÇEVİRME =====
    segments, info = model.transcribe(temp_file, beam_size=3, vad_filter=True)  # Whisper modeli ile ses dosyasını metne çeviriyoruz
    # beam_size=3: Daha iyi sonuç için beam search kullanıyoruz, vad_filter=True: Ses olmayan kısımları filtreliyoruz

    # ===== SONUÇLARI BİRLEŞTİRME =====
    text_result = " ".join([s.text for s in segments])  # Modelin döndürdüğü tüm metin parçalarını birleştiriyoruz

    # ===== TEMİZLİK =====
    os.remove(temp_file)                      # Geçici dosyayı siliyoruz (disk alanı tasarrufu için)

    # ===== SONUCU DÖNDÜRME =====
    return JSONResponse({                     # JSON formatında HTTP cevabı döndürüyoruz
        "language": info.language,            # Modelin algıladığı dil kodunu döndürüyoruz (örn: "tr" = Türkçe)
        "language_probability": round(info.language_probability, 2),  # Dil algılama güven oranını 2 ondalık basamakla döndürüyoruz (örn: 0.95)
        "transcription": text_result.strip()  # Nihai metni döndürüyoruz (başındaki ve sonundaki boşlukları temizliyoruz)
    })

# ===== ANA SAYFA ENDPOINT'İ =====
@app.get("/")                                 # GET isteği ile ana sayfaya gelen istekleri karşılar
def root():                                   # Senkron fonksiyon: Basit bir mesaj döndürür, async gerekmez
    return {"message": "Speech to Text API çalışıyor!"}  # API'nin çalıştığını belirten basit bir mesaj

# ===== UYGULAMAYI BAŞLATMA =====
if __name__ == "__main__":                    # Bu dosya doğrudan çalıştırıldığında (python main.py)
    import uvicorn                            # Uvicorn ASGI sunucusunu import ediyoruz
    uvicorn.run(app, host="0.0.0.0", port=8000)  # Uygulamayı 8000 portunda, tüm IP adreslerinden erişilebilir şekilde başlatıyoruz
