# 🎬 Media

Resize, convert, and inspect media without a GUI.

## Scripts

| Script | What it does | Usage | Added |
|---|---|---|---|
| [video-thumbnail.sh](video-thumbnail.sh) | Grab one frame from a video as a JPEG image. | `video-thumbnail [-t TIME] [-w WIDTH] [-o FILE] [--force] VIDEO` | 2016-03 |
| [video-trim.sh](video-trim.sh) | Trim a video, copying the streams when the format allows. | `video-trim [-s START] [-d DURATION] [-o FILE] [--force] [--replace] VIDEO` | 2016-11 |
| [pdf-merge.sh](pdf-merge.sh) | Merge PDF files into one document, in the order given. | `pdf-merge [-o OUTPUT.pdf] [--force] PDF...` | 2017-05 |
| [gif-from-video.sh](gif-from-video.sh) | Turn a video clip into a smooth GIF with a generated colour palette. | `gif-from-video [-s WIDTH] [-f FPS] [-t START] [-d DURATION] [-o FILE] [--force] VIDEO` | 2017-09 |
| [subtitle-shift.sh](subtitle-shift.sh) | Shift every timestamp in a SubRip (SRT) subtitle file. | `subtitle-shift [-s SECONDS] [-o FILE] [--force] [--replace] SRT` | 2017-10 |
| [image-to-pdf.sh](image-to-pdf.sh) | Combine images into one PDF, in the order given. | `image-to-pdf [-o FILE] [--force] IMAGE...` | 2017-12 |
| [media-info.sh](media-info.sh) | Show a quick summary of media files: format, duration, size and streams. | `media-info FILE...` | 2018-06 |
| [pdf-split.sh](pdf-split.sh) | Extract a page range from a PDF, or split it into single pages. | `pdf-split [-p RANGE] [--each] [-o DIR] [--force] PDF` | 2018-08 |
| [image-resize.sh](image-resize.sh) | Resize images to fit inside a box, keeping each aspect ratio. | `image-resize [-w WIDTH] [-H HEIGHT] [-o DIR] [--force] [--replace] IMAGE...` | 2018-09 |
| [video-compress.sh](video-compress.sh) | Compress a video to an H.264/AAC MP4 file. | `video-compress [-q CRF] [-H HEIGHT] [-p PRESET] [-a KBPS] [-o DIR] [--force] [--replace] VIDEO...` | 2019-07 |

## Requirements

- FFmpeg
- FFprobe (ships with FFmpeg)
- Ghostscript; pdfseparate (poppler-utils) for --each
- ImageMagick (magick
- or Ghostscript
- or convert on older systems)
- pdfunite (poppler-utils)

Shell scripts with options support `--help`.
