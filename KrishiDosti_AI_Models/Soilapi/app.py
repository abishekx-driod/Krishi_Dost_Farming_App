import io
import tensorflow as tf
import numpy as np
import os
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
try:
    import cv2
    _USE_CV2 = True
except Exception:
    from PIL import Image
    _USE_CV2 = False

model = tf.keras.models.load_model("soil_detection_model.h5")


IMG_SIZE = 224


DATASET_PATH = "Soil"
labels = sorted(os.listdir(DATASET_PATH))

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def predict_soil_from_bytes(image_bytes):
    if _USE_CV2:
        file_bytes = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
        if img is None:
            return "Failed to read image"
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        img = img.astype(np.float32) / 255.0

    else:
        try:
            img_pil = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        except:
            return "Failed to read image"
        img_pil = img_pil.resize((IMG_SIZE, IMG_SIZE))
        img = np.asarray(img_pil).astype(np.float32) / 255.0
    img = np.expand_dims(img, axis=0)
    predictions = model.predict(img)
    index = int(np.argmax(predictions))
    predicted_label = labels[index]
    if predicted_label.lower() == "not_soil":
        return "Invalid Image — No Soil Detected"
    return predicted_label
@app.get("/")
def home():
    return {"message": "Soil Prediction Model API Running"}
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    image_bytes = await file.read()
    print("FILE SIZE RECEIVED:", len(image_bytes))  
    result = predict_soil_from_bytes(image_bytes)
    print("PREDICTION:", result)
    return {
        "soil": result,
        "confidence": 1.0
    }
if _name_ == "_main_":
    uvicorn.run(app, host="0.0.0.0", port=5000)