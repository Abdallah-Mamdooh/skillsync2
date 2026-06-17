"""
training/train_career.py

Responsibilities:
- Read data/manual_gold_dataset.csv as the primary labeled dataset
  and fall back to data/labeled_resumes.csv if needed
- Train TF-IDF + Logistic Regression career field classifier
  on the career_label column (tech / business / creative / other)
- Save models/career_model.pkl
- Save models/career_classes.pkl

Column contract (matches manual_gold_dataset.csv):
    cv_text        — resume plain text
    career_label   — target: tech | business | creative | other
    quality_label  — (unused by this script)
"""

import os
import pickle
import re

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline

# ── Paths ────────────────────────────────────────────────────────────────────
BASE_DIR     = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTO_PATH    = os.path.join(BASE_DIR, "data", "labeled_resumes.csv")
GOLD_PATH    = os.path.join(BASE_DIR, "data", "manual_gold_dataset.csv")
MODEL_DIR    = os.path.join(BASE_DIR, "models")
RESULTS_PATH = os.path.join(BASE_DIR, "CAREER_EVALUATION_RESULTS.md")

os.makedirs(MODEL_DIR, exist_ok=True)


# ── Simple text cleaning ──────────────────────────────────────────────────────
def clean_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"http\S+", " ", text)        # remove URLs
    text = re.sub(r"[^a-z0-9\s]", " ", text)   # remove symbols
    text = re.sub(r"\s+", " ", text)             # normalize spaces
    return text.strip()


# ── Load data ─────────────────────────────────────────────────────────────────
print("Loading data...")

if os.path.exists(GOLD_PATH):
    source_path = GOLD_PATH
    source_encoding = "latin-1"
    print(f"  Using gold labels from: {os.path.basename(GOLD_PATH)}")
elif os.path.exists(AUTO_PATH):
    source_path = AUTO_PATH
    source_encoding = "utf-8"
    print(f"  Gold dataset not found, falling back to: {os.path.basename(AUTO_PATH)}")
else:
    raise FileNotFoundError(
        f"Neither {GOLD_PATH} nor {AUTO_PATH} exists."
    )

df = pd.read_csv(source_path, dtype=str, encoding=source_encoding, on_bad_lines="skip")
df.columns = df.columns.str.strip()
df = df[["cv_text", "career_label"]].copy()

# ── Clean ─────────────────────────────────────────────────────────────────────
df = df.dropna(subset=["cv_text", "career_label"])
df["cv_text"] = df["cv_text"].astype(str).str.strip()
df = df[df["cv_text"].str.len() > 50]

df["career_label"] = df["career_label"].str.strip().str.lower()
valid_labels = {"tech", "business", "creative", "other"}
df = df[df["career_label"].isin(valid_labels)]

df["clean_text"] = df["cv_text"].apply(clean_text)

print(f"Rows after cleaning: {len(df)}")
print("\nCareer label distribution:")
print(df["career_label"].value_counts().to_string())

# ── Train/Test split ──────────────────────────────────────────────────────────
X_train, X_test, y_train, y_test = train_test_split(
    df["clean_text"],
    df["career_label"],
    test_size=0.20,
    random_state=42,
    stratify=df["career_label"],
)

# ── Pipeline ──────────────────────────────────────────────────────────────────
pipeline = Pipeline([
    ("tfidf", TfidfVectorizer(
        max_features=7000,
        ngram_range=(1, 2),
        sublinear_tf=True,
        min_df=2,         # lowered from 3 to handle small classes (creative/other)
        max_df=0.9,
        stop_words="english",
    )),
    ("clf", LogisticRegression(
        max_iter=600,
        C=4.0,
        solver="lbfgs",
        class_weight="balanced",  # handles imbalance (creative/other are tiny)
        random_state=42,
    )),
])

# ── Train ─────────────────────────────────────────────────────────────────────
print("\nTraining career classifier...")
pipeline.fit(X_train, y_train)

# ── Evaluate ──────────────────────────────────────────────────────────────────
y_pred = pipeline.predict(X_test)

accuracy       = accuracy_score(y_test, y_pred)
macro_f1       = f1_score(y_test, y_pred, average="macro")
macro_precision = precision_score(y_test, y_pred, average="macro")
macro_recall   = recall_score(y_test, y_pred, average="macro")

classes = sorted(pipeline.classes_)
per_class_f1       = f1_score(y_test, y_pred, average=None, labels=classes)
per_class_precision = precision_score(y_test, y_pred, average=None, labels=classes)
per_class_recall   = recall_score(y_test, y_pred, average=None, labels=classes)

print("\n==============================")
print(f"Accuracy:        {accuracy:.4f}")
print(f"Macro F1:        {macro_f1:.4f}")
print(f"Macro Precision: {macro_precision:.4f}")
print(f"Macro Recall:    {macro_recall:.4f}")
print("==============================\n")

print("Per-class metrics:")
for i, cls in enumerate(classes):
    print(f"  {cls:<12}  precision={per_class_precision[i]:.3f}  "
          f"recall={per_class_recall[i]:.3f}  f1={per_class_f1[i]:.3f}")

print("\nClassification Report:")
print(classification_report(y_test, y_pred, labels=classes))

print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred, labels=classes))

# ── Save evaluation report ────────────────────────────────────────────────────
with open(RESULTS_PATH, "w", encoding="utf-8") as f:
    f.write("# Career Model Evaluation\n\n")
    f.write(f"Accuracy:        {accuracy:.4f}\n")
    f.write(f"Macro F1:        {macro_f1:.4f}\n")
    f.write(f"Macro Precision: {macro_precision:.4f}\n")
    f.write(f"Macro Recall:    {macro_recall:.4f}\n\n")
    f.write("## Per-class metrics\n")
    for i, cls in enumerate(classes):
        f.write(f"  {cls:<12}  precision={per_class_precision[i]:.3f}  "
                f"recall={per_class_recall[i]:.3f}  f1={per_class_f1[i]:.3f}\n")
    f.write("\n## Classification Report\n")
    f.write(classification_report(y_test, y_pred, labels=classes))
    f.write("\n## Confusion Matrix\n")
    f.write(str(confusion_matrix(y_test, y_pred, labels=classes)))

print(f"\nSaved evaluation results: {RESULTS_PATH}")

# ── Save model ────────────────────────────────────────────────────────────────
model_path   = os.path.join(MODEL_DIR, "career_model.pkl")
classes_path = os.path.join(MODEL_DIR, "career_classes.pkl")

with open(model_path, "wb") as f:
    pickle.dump(pipeline, f)

with open(classes_path, "wb") as f:
    pickle.dump(list(pipeline.classes_), f)

print(f"\nSaved: {model_path}")
print(f"Saved: {classes_path}")
print(f"Classes: {list(pipeline.classes_)}")
