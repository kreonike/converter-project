import os
import uuid
from typing import List
from fastapi import FastAPI, File, UploadFile, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from PIL import Image
import docx2pdf
from PyPDF2 import PdfMerger
import io
import uvicorn

app = FastAPI()

# --- Конфигурация ---
# Изменяем путь для сохранения файлов
output_dir = "downloads"
os.makedirs(output_dir, exist_ok=True)

templates = Jinja2Templates(directory="templates")
# Указываем FastAPI, что файлы из папки 'downloads' доступны по URL /downloads
app.mount("/downloads", StaticFiles(directory=output_dir), name="downloads")


# --- Главная страница ---
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


# --- API для конвертации JPG ---
@app.post("/api/v1/convert-jpg")
async def convert_jpg_to_pdf(files: List[UploadFile] = File(...)):
    if not files:
        return {"error": "Файлы не были загружены."}

    try:
        images = []
        for file in files:
            contents = await file.read()
            img = Image.open(io.BytesIO(contents)).convert("RGB")
            images.append(img)

        if not images:
            return {"error": "Не удалось обработать изображения."}

        pdf_filename = f"{uuid.uuid4()}.pdf"
        pdf_path = os.path.join(output_dir, pdf_filename)

        images[0].save(pdf_path, save_all=True, append_images=images[1:])

        return {"download_url": f"/downloads/{pdf_filename}"}
    except Exception as e:
        return {"error": f"Произошла ошибка: {e}"}


# --- API для конвертации Word ---
@app.post("/api/v1/convert-word")
async def convert_word_to_pdf(files: List[UploadFile] = File(...)):
    if not files:
        return {"error": "Файлы не были загружены."}

    try:
        pdf_paths = []
        merger = PdfMerger()

        for file in files:
            temp_docx_path = os.path.join(output_dir, f"temp_{uuid.uuid4()}_{file.filename}")
            with open(temp_docx_path, "wb") as buffer:
                buffer.write(await file.read())

            temp_pdf_path = temp_docx_path.replace(".docx", ".pdf")
            docx2pdf.convert(temp_docx_path, temp_pdf_path)
            pdf_paths.append(temp_pdf_path)
            os.remove(temp_docx_path)

        for pdf_path in pdf_paths:
            merger.append(pdf_path)

        final_pdf_filename = f"{uuid.uuid4()}.pdf"
        final_pdf_path = os.path.join(output_dir, final_pdf_filename)
        merger.write(final_pdf_path)
        merger.close()

        # Удаляем временные PDF файлы
        for path in pdf_paths:
            os.remove(path)

        return {"download_url": f"/downloads/{final_pdf_filename}"}
    except Exception as e:
        return {"error": f"Произошла ошибка: {e}"}


# --- Запуск сервера для локальной разработки ---
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

