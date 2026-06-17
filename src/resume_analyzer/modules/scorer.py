"""
modules/scorer.py

Responsibilities:
- Load scorer_model.pkl once at import time
- Accept a feature dictionary from features.py
- Return a numeric score 0-100, grade label, summary, confidence, and missing sections

No Flask. No training. No file I/O beyond loading the model.
"""

import os
import pickle
import numpy as np
from pathlib import Path


# ── Paths ────────────────────────────────────────────────────────────────────
# Use pathlib for robust path resolution regardless of working directory
BASE_DIR = Path(__file__).resolve().parents[1]

def _find_models_dir() -> Path:
    """Search upward from this file for a `models/` directory containing model files.
    Returns the Path to the models directory or raises FileNotFoundError.
    """
    here = Path(__file__).resolve()
    for parent in here.parents:
        candidate = parent / "models"
        if candidate.is_dir():
            # ensure it contains at least one expected file
            for f in candidate.iterdir():
                if f.suffix in {".pkl", ".json"}:
                    return candidate
    raise FileNotFoundError("Could not locate models/ directory for scorer")

MODEL_DIR = _find_models_dir()
MODEL_PATH = str(MODEL_DIR / "scorer_model.pkl")


# ── Load model once at import time ────────────────────────────────────────────
with open(MODEL_PATH, "rb") as f:
    _PAYLOAD = pickle.load(f)

_MODEL = _PAYLOAD["model"]
_FEATURE_NAMES = _PAYLOAD["feature_names"]


# ── Grade definitions ─────────────────────────────────────────────────────────
GRADE_LABELS = {
    0: "Needs Work",
    1: "Average",
    2: "Strong",
}

GRADE_SUMMARIES = {
    0: "This resume needs significant improvement. Focus on stronger structure, clearer bullet points, and more measurable achievements.",
    1: "This resume is functional but still has room to improve. Strengthen impact, keyword coverage, and consistency.",
    2: "This is a strong resume overall. Minor polishing and role-specific improvements can make it even better.",
}


def _features_to_array(features: dict) -> np.ndarray:
    """
    Convert a feature dictionary to a numpy array
    in the exact column order the model was trained on.
    """
    return np.array([[features.get(name, 0) for name in _FEATURE_NAMES]])


def _grade_to_score(grade: int, features: dict) -> float:
    """
    Convert a 3-class grade to a 0-100 score using feature signals
    to place the score within the grade band.

    Grade bands:
        0 (weak)    →  0 – 39
        1 (average) → 40 – 69
        2 (strong)  → 70 – 100
    """
    bands = {
        0: (5, 39),
        1: (40, 69),
        2: (70, 98),
    }
    low, high = bands[grade]

    # Signals used only to place the score inside the grade band
    signals = [
        min(features.get("word_count", 0) / 600, 1.0),
        features.get("has_email", 0),
        features.get("has_phone", 0),
        features.get("has_linkedin", 0),
        min(features.get("section_count", 0) / 6, 1.0),
        min(features.get("bullet_count", 0) / 10, 1.0),
        min(features.get("action_verb_count", 0) / 10, 1.0),
        min(features.get("quantification_count", 0) / 5, 1.0),
        max(0, 1 - features.get("filler_count", 0) / 5),
        max(0, 1 - features.get("first_person_count", 0) / 5),
    ]

    signal_avg = sum(signals) / len(signals)
    score = low + signal_avg * (high - low)
    return round(float(score), 1)


def _get_missing_sections(features: dict) -> list:
    """
    Identify important missing resume sections.
    """
    missing_sections = []

    if not features.get("has_summary"):
        missing_sections.append("Summary or Objective section")
    if not features.get("has_experience"):
        missing_sections.append("Experience section")
    if not features.get("has_education"):
        missing_sections.append("Education section")
    if not features.get("has_skills"):
        missing_sections.append("Skills section")

    return missing_sections

   
def score_resume(features: dict) -> dict:
    """
    Takes a feature dictionary from extract_features().
    Returns a dict with score, grade, grade_label, summary, confidence, and missing sections.
    """
    X = _features_to_array(features)
    grade = int(_MODEL.predict(X)[0])
    proba = _MODEL.predict_proba(X)[0]

    score = _grade_to_score(grade, features)
    grade_label = GRADE_LABELS[grade]
    summary = GRADE_SUMMARIES[grade]
    confidence = round(float(proba[grade]), 3)
    missing_sections = _get_missing_sections(features)

    return {
        "score": score,
        "grade": grade,
        "grade_label": grade_label,
        "summary": summary,
        "confidence": confidence,
        "missing_sections": missing_sections,
    }