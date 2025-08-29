import os
import uuid
import logging
import io
from fastapi import FastAPI, File, UploadFile, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from typing import List
from PIL import Image
from docx2pdf import convert
from PyPDF2 import PdfMerger
import uvicorn

# Настройка логирования
logging.basicConfig(level=logging.INFO)

# Инициализация FastAPI
app = FastAPI()

# Настройка для статических файлов и шаблонов
output_dir = "static/output"
os.makedirs(output_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")


@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    """Отдает главную страницу."""
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/api/v1/convert-jpg")
async def convert_jpg_to_pdf_api(files: List[UploadFile] = File(...)):
    """API для конвертации нескольких JPG в один PDF."""
    if not files:
        raise HTTPException(status_code=400, detail="Файлы не были загружены.")

    images = []
    try:
        for file in files:
            if not file.content_type.startswith('image/'):
                continue
            contents = await file.read()
            img = Image.open(io.BytesIO(contents)).convert("RGB")
            images.append(img)
    except Exception as e:
        logging.error(f"Ошибка при обработке изображений: {e}")
        raise HTTPException(status_code=500, detail="Не удалось обработать изображения.")

    if not images:
        raise HTTPException(status_code=400, detail="Не найдено подходящих изображений для конвертации.")

    unique_id = uuid.uuid4()
    output_filename = f"{unique_id}.pdf"
    output_path = os.path.join(output_dir, output_filename)

    try:
        images[0].save(output_path, save_all=True, append_images=images[1:])
    except Exception as e:
        logging.error(f"Ошибка при сохранении PDF: {e}")
        raise HTTPException(status_code=500, detail="Ошибка при создании PDF файла.")

    logging.info(f"Файл {output_filename} успешно создан.")
    return JSONResponse({
        "message": "Файлы успешно сконвертированы!",
        "filename": output_filename,
        "download_url": f"/static/output/{output_filename}"
    })


@app.post("/api/v1/convert-word")
async def convert_word_to_pdf_api(files: List[UploadFile] = File(...)):
    """API для конвертации нескольких DOCX в один PDF."""
    if not files:
        raise HTTPException(status_code=400, detail="Пожалуйста, загрузите файлы формата .doc или .docx.")

    unique_id = uuid.uuid4()
    temp_files_to_clean = []
    temp_pdfs_to_merge = []

    try:
        for file in files:
            if not (file.filename.endswith('.docx') or file.filename.endswith('.doc')):
                continue

            # Сохраняем загруженный DOCX во временный файл
            temp_docx_filename = f"{unique_id}_{file.filename}"
            temp_docx_path = os.path.join(output_dir, temp_docx_filename)
            temp_files_to_clean.append(temp_docx_path)

            with open(temp_docx_path, "wb") as buffer:
                buffer.write(await file.read())

            # Конвертируем DOCX в PDF
            temp_pdf_path = temp_docx_path.replace(".docx", ".pdf").replace(".doc", ".pdf")
            convert(temp_docx_path, temp_pdf_path)
            temp_pdfs_to_merge.append(temp_pdf_path)
            temp_files_to_clean.append(temp_pdf_path)

        if not temp_pdfs_to_merge:
            raise HTTPException(status_code=400, detail="Не найдено подходящих Word файлов для конвертации.")

        # Объединяем PDF файлы
        merger = PdfMerger()
        for pdf in temp_pdfs_to_merge:
            merger.append(pdf)

        output_pdf_filename = f"{unique_id}_merged.pdf"
        output_pdf_path = os.path.join(output_dir, output_pdf_filename)

        merger.write(output_pdf_path)
        merger.close()

        logging.info(f"Файл {output_pdf_filename} успешно создан.")
        return JSONResponse({
            "message": "Файлы успешно сконвертированы!",
            "filename": output_pdf_filename,
            "download_url": f"/static/output/{output_pdf_filename}"
        })

    except Exception as e:
        logging.error(f"Ошибка конвертации DOCX в PDF: {e}")
        raise HTTPException(status_code=500,
                            detail=f"Ошибка при конвертации файла. Убедитесь, что у вас установлен MS Word или LibreOffice. Ошибка: {e}")
    finally:
        # Очистка временных файлов
        for file_path in temp_files_to_clean:
            if os.path.exists(file_path):
                os.remove(file_path)


if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)

