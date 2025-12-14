import base64
import json
import requests
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
import uvicorn


PLANT_ID_KEY = "itPidvT4larBtFAMBvAqp7u0OF5TSvQwctn4mb4nypVmylUVRy"
GEMINI_KEY = "AIzaSyCnREf0Zf4Ut5tVmut6HS8lJ70wS8TGNCw"

genai.configure(api_key=GEMINI_KEY)
gemini_model = genai.GenerativeModel("gemini-2.0-flash")   # SAFE MODEL



app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def encode(img):
    return base64.b64encode(img).decode()


def contains_leaf(image_bytes):
    """Use Gemini to check if the image contains a plant or leaf."""
    try:
        result = gemini_model.generate_content([
            "Does this image contain a plant/leaf? Respond only YES or NO.",
            {"mime_type": "image/jpeg", "data": image_bytes}
        ])

        txt = result.text.strip().lower()
        return "yes" in txt

    except Exception as e:
        print("Leaf detection failed:", e)
        return True   # fail-safe: allow processing


def call_plant_id(img_b64):
    url = "https://plant.id/api/v3/identification"

    payload = {
        "api_key": PLANT_ID_KEY,
        "images": [img_b64],
        "classification_level": "species",
        "health": "all",
    }

    try:
        r = requests.post(url, json=payload, timeout=30)
        if r.status_code != 200:
            return None
        return r.json()
    except:
        return None


def summarize_plant_id(data):
    """Extract plant name + top disease from plant.id."""
    if not data:
        return {"plant_name": None, "top_disease": None}

    result = data.get("result", {})

    # plant name
    plant_sug = result.get("classification", {}).get("suggestions", [])
    plant_name = (
        max(plant_sug, key=lambda x: x["probability"])["name"]
        if plant_sug else None
    )

    # disease
    dis_sug = result.get("disease", {}).get("suggestions", [])
    top_disease = None
    if dis_sug:
        best = max(dis_sug, key=lambda x: x["probability"])
        top_disease = {
            "name": best.get("name"),
            "prob": best.get("probability", 0),
        }

    return {
        "plant_name": plant_name,
        "top_disease": top_disease,
    }


def doctor_analysis(image_bytes):
    prompt = """
You are a plant doctor.

Analyze the plant leaf and return STRICT JSON:

{
  "plant_name": "",
  "disease_name": "",
  "severity": "",
  "summary": "",
  "prevention": "",
  "solutions": "",
  "fertilizers": ""
}

If the leaf is healthy:
- disease_name: "None"
- severity: "healthy"
- summary: "The plant appears healthy."

If NO plant is present:
- Return exactly: {"error": "NO_PLANT"}

Use farmer-friendly English.
"""

    try:
        res = gemini_model.generate_content([
            prompt,
            {"mime_type": "image/jpeg", "data": image_bytes}
        ])

        txt = res.text.strip()

        # find JSON inside
        start = txt.find("{")
        end = txt.rfind("}") + 1
        obj = json.loads(txt[start:end])

        return obj

    except Exception as e:
        print("Gemini doctor error:", e)
        return {"disease_name": "", "severity": "unknown"}


def fuse_logic(plant_id, doctor):
    """Combine Plant.ID and Gemini results cleanly."""

    # if Gemini detected NO PLANT
    if doctor.get("error") == "NO_PLANT":
        return {
            "status": "no_plant",
            "message": "No plant detected in the image. Please upload a clear image of a plant leaf."
        }

    # if doctor says healthy
    if doctor.get("severity") == "healthy":
        return {
            "status": "healthy",
            "message": "The plant appears healthy. No disease detected.",
            "summary": doctor.get("summary", "")
        }

    # disease from Gemini
    return {
        "status": "disease",
        "plant_name": doctor.get("plant_name") or plant_id.get("plant_name"),
        "disease_name": doctor.get("disease_name"),
        "severity": doctor.get("severity"),
        "summary": doctor.get("summary"),
        "prevention": doctor.get("prevention"),
        "solutions": doctor.get("solutions"),
        "fertilizers": doctor.get("fertilizers"),
    }


@app.post("/analyze")
async def analyze(image: UploadFile = File(...)):
    img_bytes = await image.read()
    img_b64 = encode(img_bytes)

    # first detect plant
    if not contains_leaf(img_bytes):
        return {
            "status": "no_plant",
            "message": "No plant detected in the image. Please upload a clear image of a plant leaf."
        }

    plant_raw = call_plant_id(img_b64)
    plant_summary = summarize_plant_id(plant_raw)

    doctor = doctor_analysis(img_bytes)

    final = fuse_logic(plant_summary, doctor)

    return final


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7000)