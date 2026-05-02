# CV Optimizer - Backend Integration Setup

## Overview

The CV Optimizer screen now connects to the Flask-based resume analyzer backend to provide real AI-powered resume analysis.

## Architecture

```
Flutter App (cv_Optimizer.dart)
    ↓
ResumeAnalyzerService (HTTP client)
    ↓
Flask Backend (resume_analyzer/app.py)
    ↓
AI Models (scorer_model.pkl, feature extraction)
```

## Files Created/Modified

### New Files
- `lib/models/resume_analysis.dart` - Data models for API responses
- `lib/services/resume_analyzer_service.dart` - HTTP client service
- `lib/config/api_config.dart` - API configuration

### Modified Files
- `lib/screens/cv_Optimizer.dart` - Integrated real API calls
- `pubspec.yaml` - Added http_parser dependency

## Setup Instructions

### 1. Start the Flask Backend

```bash
cd D:\SAMS\4th Year\SkillSync\skillsync2\resume_analyzer

# Install Python dependencies (first time only)
pip install flask python-dotenv pymupdf python-docx scikit-learn pandas numpy

# Start the server
flask --app app run --port 5000 --no-reload
```

The server will start at `http://localhost:5000`

### 2. Configure API URL for Your Device

Edit `lib/config/api_config.dart` based on your setup:

| Platform | Base URL |
|----------|----------|
| Android Emulator | `http://10.0.2.2:5000` |
| iOS Simulator | `http://localhost:5000` |
| Physical Device | `http://YOUR_IP:5000` (e.g., `192.168.1.100:5000`) |

**Note:** For physical devices, ensure:
- Your computer and phone are on the same WiFi network
- Flask is running with `--host=0.0.0.0` to accept external connections

### 3. Run the Flutter App

```bash
cd D:\SAMS\4th Year\SkillSync\skillsync2\mobile

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### 4. Test the Integration

1. Open the CV Optimizer screen in the app
2. Upload a PDF or DOCX resume file
3. Click "Analyze CV"
4. Wait for the analysis (may take 2-5 seconds)
5. View the results:
   - Overall score (0-100)
   - Strengths
   - Quick wins
   - Formatting/ATS issues
   - Detailed improvement suggestions

## API Response Structure

The backend returns:

```json
{
  "score": 72,
  "grade": "Average",
  "word_count": 450,
  "detected_field": "tech",
  "summary": "This resume is functional but has room to improve...",
  "strong_points": ["Contact information is complete", ...],
  "quick_wins": ["Add your LinkedIn URL", ...],
  "missing_sections": ["Summary section"],
  "ats_issues": ["Email not found in top section"],
  "writing_issues": ["First-person pronouns detected"],
  "improvements": ["Add a Summary section...", ...]
}
```

## Troubleshooting

### "Cannot connect to server"
- Ensure Flask backend is running
- Check the API URL in `api_config.dart` matches your platform
- For Android emulator, use `10.0.2.2` not `localhost`

### "Request timed out"
- The analysis may take 2-5 seconds for large files
- Increase timeout in `api_config.dart` if needed

### "File not found"
- Ensure the file path is accessible
- On Android, FilePicker provides a valid path

### "Analysis failed: Could not read file"
- The file may be corrupted or password-protected
- Try a different PDF/DOCX file

## Features

### What the AI Analyzes

1. **Contact Information** - Email, phone, LinkedIn, GitHub
2. **Section Structure** - Experience, Education, Skills sections
3. **Writing Quality** - Action verbs, filler phrases, first-person usage
4. **Quantification** - Numbers, percentages, metrics
5. **ATS Compatibility** - Formatting issues that confuse parsers
6. **Field Detection** - Tech, Marketing, Creative, Business, Other
7. **Keyword Analysis** - Missing keywords from job descriptions (optional)

### Score Calculation

- **0-39**: Needs Work (red)
- **40-69**: Average (orange)
- **70-100**: Strong (green)

## Next Steps

To enhance the integration:
1. Add job description matching (paste JD text for keyword analysis)
2. Implement export functionality for analysis results
3. Add history/saved analyses
4. Cache results to avoid re-analyzing the same file
