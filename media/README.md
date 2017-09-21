# 🎬 Media

Resize, convert, and inspect media without a GUI.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [video-thumbnail.sh](video-thumbnail.sh) | Grab one frame from a video as a JPEG image. | `video-thumbnail [-t TIME] [-w WIDTH] [-o FILE] [--force] VIDEO` | 2016-03 |
| [video-trim.sh](video-trim.sh) | Trim a video, copying the streams when the format allows. | `video-trim [-s START] [-d DURATION] [-o FILE] [--force] [--replace] VIDEO` | 2016-11 |
| [pdf-merge.sh](pdf-merge.sh) | Merge PDF files into one document, in the order given. | `pdf-merge [-o OUTPUT.pdf] [--force] PDF...` | 2017-05 |
| [gif-from-video.sh](gif-from-video.sh) | Turn a video clip into a smooth GIF with a generated colour palette. | `gif-from-video [-s WIDTH] [-f FPS] [-t START] [-d DURATION] [-o FILE] [--force] VIDEO` | 2017-09 |

## Requirements

- FFmpeg
- or Ghostscript
- pdfunite (poppler-utils)

Shell scripts with options support `--help`.
