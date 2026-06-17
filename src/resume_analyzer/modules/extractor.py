"""
modules/extractor.py

Responsibilities:
- Extract raw text from PDF files using PyMuPDF
- OCR fallback for scanned PDFs using pytesseract
- Extract raw text from DOCX files using python-docx
- Clean the extracted text (normalize whitespace, remove junk characters)
- Normalize text for keyword matching (lowercase, strip punctuation, expand abbreviations)

No Flask. No ML. Just text extraction.
"""

import re
import fitz          # PyMuPDF
from docx import Document
from docx.oxml.ns import qn

# Minimum word count from PyMuPDF before we assume the PDF is scanned
_OCR_FALLBACK_THRESHOLD = 20

# Common abbreviation expansions for resume keyword matching
_VARIANTS = {
    r"\bml\b": "machine learning",
    r"\bdl\b": "deep learning",
    r"\bai\b": "artificial intelligence",
    r"\bnlp\b": "natural language processing",
    r"\bcv\b": "computer vision",
    r"\bjs\b": "javascript",
    r"\bts\b": "typescript",
    r"\bpy\b": "python",
    r"\bk8s\b": "kubernetes",
    r"\bkube\b": "kubernetes",
    r"\baws\b": "amazon web services",
    r"\bgcp\b": "google cloud",
    r"\bci/cd\b": "cicd",
    r"\bcicd\b": "ci cd",
    r"\boop\b": "object oriented",
    r"\bapi\b": "application programming interface",
    r"\bdb\b": "database",
    r"\bui\b": "user interface",
    r"\bux\b": "user experience",
    r"\bqa\b": "quality assurance",
    r"\bpm\b": "project management",
    r"\bcrm\b": "customer relationship management",
    r"\berp\b": "enterprise resource planning",
    r"\bseo\b": "search engine optimization",
    r"\bsem\b": "search engine marketing",
    r"\broi\b": "return on investment",
    r"\bkpi\b": "key performance indicator",
    r"\bokr\b": "objectives and key results",
    r"\bp&l\b": "profit and loss",
}


def normalize_text(text: str) -> str:
    """
    Normalize text for keyword matching:
    - Lowercase
    - Remove punctuation (keep alphanumeric and spaces)
    - Collapse whitespace
    - Expand common abbreviations to their full forms
    """
    text = text.lower()
    # Remove punctuation except word-internal characters useful for matching (keep / for ci/cd etc.)
    text = re.sub(r"[^\w\s/]", " ", text)
    # Collapse whitespace
    text = re.sub(r"\s+", " ", text)
    # Expand abbreviations
    for pattern, replacement in _VARIANTS.items():
        text = re.sub(pattern, replacement, text)
    return text.strip()


def extract_text(file_path: str) -> tuple[str, bool]:
    """
    Detect file type and extract plain text.
    Returns (text, ocr_used) where ocr_used is True if pytesseract was needed.
    Raises ValueError for unsupported file types.
    """
    path = file_path.strip().lower()

    if path.endswith(".pdf"):
        raw, ocr_used = _extract_pdf(file_path)
    elif path.endswith(".docx"):
        raw = _extract_docx(file_path)
        ocr_used = False
    else:
        raise ValueError(f"Unsupported file type: {file_path}")

    return clean_text(raw), ocr_used


def _extract_pdf(file_path: str) -> tuple[str, bool]:
    """
    Extract text from all pages of a PDF.
    Falls back to pytesseract OCR if the PDF appears to be scanned (too little text).
    Returns (text, ocr_used).
    """
    text_parts = []
    with fitz.open(file_path) as doc:
        for page in doc:
            text_parts.append(page.get_text())
    raw = "\n".join(text_parts)

    word_count = len(raw.split())
    if word_count >= _OCR_FALLBACK_THRESHOLD:
        return raw, False

    # Too little text — attempt OCR
    ocr_text = _ocr_pdf(file_path)
    if ocr_text and len(ocr_text.split()) > word_count:
        return ocr_text, True

    return raw, False


def _ocr_pdf(file_path: str) -> str:
    """
    Render each PDF page as an image and run pytesseract OCR on it.
    Returns empty string if pytesseract is not installed or fails.
    """
    try:
        import pytesseract
        from PIL import Image
        import os
        # Default Windows install path; no-op if already on PATH
        win_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
        if os.path.exists(win_path):
            pytesseract.pytesseract.tesseract_cmd = win_path
    except ImportError:
        return ""

    text_parts = []
    try:
        with fitz.open(file_path) as doc:
            for page in doc:
                pix = page.get_pixmap(dpi=200)
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                text_parts.append(pytesseract.image_to_string(img))
    except Exception:
        return ""

    return "\n".join(text_parts)


def _extract_docx(file_path: str) -> str:
    """Extract text from all paragraphs of a DOCX file."""
    doc = Document(file_path)
    paragraphs = []

    for para in doc.paragraphs:
        parts = []
        for child in para._p:
            if child.tag.endswith("}hyperlink"):
                rel_id = child.get(qn("r:id"))
                if rel_id and rel_id in para.part.rels:
                    target = para.part.rels[rel_id].target_ref
                    if target:
                        parts.append(target)
                hyperlink_text = "".join(
                    node.text for node in child.iter() if getattr(node, "text", None)
                )
                if hyperlink_text.strip():
                    parts.append(hyperlink_text)
            elif child.tag.endswith("}r"):
                run_text = "".join(
                    node.text for node in child.iter() if getattr(node, "text", None)
                )
                if run_text.strip():
                    parts.append(run_text)

        paragraph_text = " ".join(parts).strip()
        if paragraph_text:
            paragraphs.append(paragraph_text)

    return "\n".join(paragraphs)


def clean_text(text: str) -> str:
    """
    Normalize extracted text:
    - Replace non-breaking spaces and other unicode spaces with regular space
    - Collapse multiple spaces into one
    - Collapse more than 2 consecutive newlines into 2
    - Strip leading/trailing whitespace
    """
    # Replace unicode whitespace variants with normal space
    text = re.sub(r"[^\S\n]", " ", text)

    # Remove null bytes and other control characters except newlines
    text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", text)

    # Collapse multiple spaces into one
    text = re.sub(r" {2,}", " ", text)

    # Collapse more than 2 newlines into 2
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()
