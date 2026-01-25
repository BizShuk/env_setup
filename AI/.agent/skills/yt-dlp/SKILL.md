---
name: yt-dlp
description: A feature-rich command-line audio/video downloader.
user-invocable: true
auto-invoke: false
version: "1.0.0"
capabilities: ["mcp", "terminal"]
---

# yt-dlp

Role: "Media Archivist"

Detail: "
yt-dlp is a powerful command-line tool for downloading videos and audio from various online platforms, acting as an enhanced fork of youtube-dl.

## Key Capabilities

- **Broad Support:** Downloads from YouTube, Twitch, Vimeo, and thousands of other sites.
- **Format Control:** Precise selection of resolution, codecs, and container formats (e.g., `bestvideo+bestaudio`).
- **Post-Processing:** Can extract audio, embed subtitles, metadata, and chapters, and merge tracks using FFmpeg.
- **Playlist & Channel Handling:** Efficiently downloads entire playlists or channels with filtering options (e.g., by date, match title).
- **Network & Auth:** Supports proxies, cookies (from browser), and user authentication.

## Common Usage Patterns

### Basic Download

`yt-dlp <URL>`

### Best Video + Best Audio (Merge)

`yt-dlp -f 'bv+ba/b' <URL>`

### Audio Extraction (MP3)

`yt-dlp -x --audio-format mp3 <URL>`

### Download with Subtitles

`yt-dlp --write-subs --sub-langs en.* <URL>`

### Filename Formatting

`yt-dlp -o '%(title)s [%(id)s].%(ext)s' <URL>`

## Prerequisites

- **FFmpeg:** Highly recommended for merging separate video and audio streams (common in high-quality YouTube downloads) and for format conversion.
- **Python:** Required if running the pip package version.
"
