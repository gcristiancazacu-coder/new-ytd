# YT Downloader Pro - Backend API

Backend FastAPI server pentru YT Downloader Pro application.

## Deployment on Railway

### Prerequisites
- Railway.app account (free)
- GitHub repository with backend code

### Steps to Deploy

1. **Push backend to GitHub**
   ```bash
   git push origin main
   ```

2. **Go to Railway.app**
   - Create new project
   - Connect GitHub repo
   - Select backend folder as source

3. **Set Environment Variables**
   - No special env vars needed currently

4. **Deploy**
   - Railway automatically detects Procfile
   - Builds and deploys automatically

5. **Get URL**
   - Railway gives you a public URL like: `https://ytdownloader-prod-abc123.railway.app`
   - Use this URL in Flutter app

## Local Development

```bash
pip install -r requirements.txt
python main.py
```

Server runs on `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`
