import os
import json
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix

import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras import layers, models, callbacks

# -------------------------------------------------------------
# USER CONFIG
# -------------------------------------------------------------
DATASET_ROOT = "diseasedataset"      # <<< CHANGE THIS
MODEL_OUTPUT = "plant_model.h5"
CLASS_MAP_JSON = "class_map.json"
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 15
SEED = 42
# -------------------------------------------------------------


# -------------------------------------------------------------
# Step 1 — Build DataFrame from Folder Structure
# -------------------------------------------------------------
def build_dataframe_from_structure(root_dir):
    rows = []
    root = Path(root_dir)

    if not root.exists():
        raise FileNotFoundError(f"Dataset folder not found: {root_dir}")

    for plant_dir in root.iterdir():
        if not plant_dir.is_dir():
            continue

        plant_name = plant_dir.name

        # Healthy
        healthy_dir = plant_dir / "Healthy"
        if healthy_dir.exists():
            for img in healthy_dir.glob("*"):
                if img.suffix.lower() in [".jpg", ".jpeg", ".png"]:
                    rows.append({
                        "filepath": str(img),
                        "label": f"{plant_name}__Healthy"
                    })

        # unHealthy -> disease folders
        unhealthy_dir = plant_dir / "unHealthy"
        if unhealthy_dir.exists():
            for disease_dir in unhealthy_dir.iterdir():
                if not disease_dir.is_dir():
                    continue
                disease = disease_dir.name
                for img in disease_dir.glob("*"):
                    if img.suffix.lower() in [".jpg", ".jpeg", ".png"]:
                        rows.append({
                            "filepath": str(img),
                            "label": f"{plant_name}__{disease}"
                        })

    df = pd.DataFrame(rows)
    print("Dataset Loaded Successfully!")
    print(df.head())
    print("\nTotal images:", len(df))
    print("Total classes:", df['label'].nunique())
    return df


df = build_dataframe_from_structure(DATASET_ROOT)

# -------------------------------------------------------------
# Step 2 — Train/Validation/Test Split
# -------------------------------------------------------------
train_df, test_df = train_test_split(
    df, test_size=0.15, stratify=df['label'], random_state=SEED)

train_df, val_df = train_test_split(
    train_df, test_size=0.15, stratify=train_df['label'], random_state=SEED)

print("\nSplit Results:")
print("Train:", len(train_df))
print("Val:", len(val_df))
print("Test:", len(test_df))


# -------------------------------------------------------------
# Step 3 — Image Generators
# -------------------------------------------------------------
train_gen = ImageDataGenerator(
    preprocessing_function=preprocess_input,
    rotation_range=20,
    width_shift_range=0.1,
    height_shift_range=0.1,
    zoom_range=0.2,
    horizontal_flip=True
)

val_gen = ImageDataGenerator(preprocessing_function=preprocess_input)
test_gen = ImageDataGenerator(preprocessing_function=preprocess_input)

train_flow = train_gen.flow_from_dataframe(
    train_df, x_col="filepath", y_col="label",
    target_size=IMG_SIZE, batch_size=BATCH_SIZE,
    class_mode="categorical", shuffle=True
)

val_flow = val_gen.flow_from_dataframe(
    val_df, x_col="filepath", y_col="label",
    target_size=IMG_SIZE, batch_size=BATCH_SIZE,
    class_mode="categorical", shuffle=False
)

test_flow = test_gen.flow_from_dataframe(
    test_df, x_col="filepath", y_col="label",
    target_size=IMG_SIZE, batch_size=BATCH_SIZE,
    class_mode="categorical", shuffle=False
)

# Save class mapping
class_map = train_flow.class_indices
with open(CLASS_MAP_JSON, "w") as f:
    json.dump(class_map, f, indent=2)

print("\nClass map saved ->", CLASS_MAP_JSON)


# -------------------------------------------------------------
# Step 4 — Build CNN Model (EfficientNet)
# -------------------------------------------------------------
base = EfficientNetB0(
    include_top=False,
    input_shape=(*IMG_SIZE, 3),
    weights="imagenet",
    pooling="avg"
)

base.trainable = False

model = models.Sequential([
    base,
    layers.Dropout(0.3),
    layers.Dense(256, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(len(class_map), activation="softmax")
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-3),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()


# -------------------------------------------------------------
# Step 5 — Train Model
# -------------------------------------------------------------
checkpoint = callbacks.ModelCheckpoint(
    "best_model_temp.h5", save_best_only=True, monitor="val_accuracy"
)

early_stop = callbacks.EarlyStopping(
    monitor="val_loss", patience=5, restore_best_weights=True
)

history = model.fit(
    train_flow,
    validation_data=val_flow,
    epochs=EPOCHS,
    callbacks=[checkpoint, early_stop]
)


# -------------------------------------------------------------
# Step 6 — Fine Tune (Unfreeze last layers)
# -------------------------------------------------------------
base.trainable = True

for layer in base.layers[:-40]:  # train last 40 layers
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-5),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

ft_history = model.fit(
    train_flow,
    validation_data=val_flow,
    epochs=EPOCHS//2,
    callbacks=[checkpoint, early_stop]
)


# -------------------------------------------------------------
# Step 7 — Evaluate Model
# -------------------------------------------------------------
print("\nEvaluating on Test Data…")

test_loss, test_acc = model.evaluate(test_flow)
print(f"\nTest Accuracy: {test_acc:.4f}")
print(f"Test Loss: {test_loss:.4f}")

# Predictions
y_true = test_flow.classes
y_pred = np.argmax(model.predict(test_flow), axis=1)

# Classification Report
print("\nClassification Report:")
labels = list(class_map.keys())
print(classification_report(y_true, y_pred, target_names=labels))

# Confusion Matrix
print("\nConfusion Matrix:")
print(confusion_matrix(y_true, y_pred))


# -------------------------------------------------------------
# Step 8 — Save Final Model
# -------------------------------------------------------------
model.save(MODEL_OUTPUT)
print("\nModel saved as:", MODEL_OUTPUT)
