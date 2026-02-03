from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import yt_dlp
import os
import uuid
import asyncio
from typing import Dict

app = FastAPI(title="YT Downloader Pro API")

# CORS - permite accesul din Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Stocare status-uri descărcări
download_status: Dict[str, dict] = {}

# Folder descărcări
DOWNLOAD_FOLDER = "downloads"
os.makedirs(DOWNLOAD_FOLDER, exist_ok=True)


@app.get("/")
async def health_check():
    return {"status": "running", "api": "YT Downloader Pro v1.0"}


@app.post("/api/download")
async def start_download(url: str, format_type: str = "audio"):
    """Inițiază descărcare"""
    task_id = str(uuid.uuid4())[:8]
    
    download_status[task_id] = {
        "status": "pending",
        "progress": 0,
        "file_path": None,
        "error": None,
        "filename": None
    }
    
    asyncio.create_task(process_download(task_id, url, format_type))
    return {"task_id": task_id}


async def process_download(task_id: str, url: str, format_type: str):
    """Procesează descărcarea"""
    
    def progress_hook(d):
        if d['status'] == 'downloading':
            total = d.get('total_bytes') or d.get('total_bytes_estimate')
            downloaded = d.get('downloaded_bytes', 0)
            if total:
                percent = int((downloaded / total) * 100)
                download_status[task_id]["progress"] = percent
                download_status[task_id]["status"] = "downloading"
        elif d['status'] == 'finished':
            download_status[task_id]["status"] = "processing"
    
    try:
        base_opts = {
            'outtmpl': f'{DOWNLOAD_FOLDER}/{task_id}.%(ext)s',
            'progress_hooks': [progress_hook],
            'noplaylist': True,
            'socket_timeout': 120,
            'quiet': False,
            'no_warnings': False,
            'skip_unavailable_fragments': True,
            'fragment_retries': 30,
            'extractor_args': {
                'youtube': {
                    'player_client': ['web'],
                }
            },
            'http_headers': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            },
        }
        
        if format_type == "audio":
            # AUDIO: Doar sunet - m4a format
            ydl_opts = base_opts.copy()
            ydl_opts['format'] = 'bestaudio[ext=m4a]/bestaudio/best'
            
            print(f"[{task_id}] Downloading AUDIO...")
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=True)
                filename = ydl.prepare_filename(info)
                
                print(f"[{task_id}] ✓ Audio downloaded: {filename}")
                
                download_status[task_id]["status"] = "completed"
                download_status[task_id]["progress"] = 100
                download_status[task_id]["file_path"] = filename
                download_status[task_id]["filename"] = os.path.basename(filename)
        
        else:
            # VIDEO: Video + Audio combinate
            # Opțiuni format în ordine de preferință
            video_formats = [
                'bestvideo[height<=720]+bestaudio/best',      # 720p video + audio
                'bestvideo[height<=1080]+bestaudio/best',     # 1080p video + audio
                'bestvideo+bestaudio/best',                   # Best video + audio
                'best[vcodec!="none"][acodec!="none"]/best',  # Best cu video și audio
                'best',                                        # Fallback: best available
            ]
            
            success = False
            for format_str in video_formats:
                try:
                    ydl_opts = base_opts.copy()
                    ydl_opts['format'] = format_str
                    
                    print(f"[{task_id}] Downloading VIDEO - format: {format_str}")
                    
                    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                        info = ydl.extract_info(url, download=True)
                        filename = ydl.prepare_filename(info)
                        
                        print(f"[{task_id}] ✓ Video downloaded: {filename}")
                        
                        download_status[task_id]["status"] = "completed"
                        download_status[task_id]["progress"] = 100
                        download_status[task_id]["file_path"] = filename
                        download_status[task_id]["filename"] = os.path.basename(filename)
                        
                        success = True
                        break
                
                except Exception as e:
                    print(f"[{task_id}] Format '{format_str}' failed: {type(e).__name__}")
                    continue
            
            if not success:
                raise Exception("All video formats failed")
    
    except Exception as e:
        error_msg = str(e)
        print(f"[{task_id}] ✗ ERROR: {error_msg}")
        download_status[task_id]["status"] = "error"
        download_status[task_id]["error"] = error_msg


@app.get("/api/progress/{task_id}")
async def get_progress(task_id: str):
    """Verifică progres"""
    if task_id not in download_status:
        raise HTTPException(status_code=404, detail="Task not found")
    return download_status[task_id]


@app.get("/api/download/{task_id}")
async def download_file(task_id: str):
    """Descarcă fișierul"""
    if task_id not in download_status:
        raise HTTPException(status_code=404, detail="Not found")
    
    status = download_status[task_id]
    if status["status"] != "completed":
        raise HTTPException(status_code=400, detail="Not ready")
    
    file_path = status["file_path"]
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File missing")
    
    return FileResponse(file_path, filename=status["filename"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
