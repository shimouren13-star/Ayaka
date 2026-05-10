#!/usr/bin/env python3
"""
OCR script — reads text from images using Tesseract.
Usage: python ocr.py <image_path>
       python ocr.py              (uses latest screenshot)
       python ocr.py --watch      (watch for new screenshots)
"""
import sys
import os
from pathlib import Path

# Fix Windows console encoding for Chinese output
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# Configure Tesseract paths
TESSERACT_EXE = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
TESSDATA_DIR = os.path.expandvars(r"%USERPROFILE%\tesseract\tessdata")

os.environ["TESSDATA_PREFIX"] = TESSDATA_DIR

import pytesseract
pytesseract.pytesseract.tesseract_cmd = TESSERACT_EXE

from PIL import Image


def ocr_image(image_path: str, lang: str = "chi_sim+eng") -> str:
    """Extract text from an image using Tesseract OCR."""
    img = Image.open(image_path)
    text = pytesseract.image_to_string(img, lang=lang)
    return text.strip()


def get_latest_screenshot() -> str | None:
    """Return path to the most recent screenshot."""
    screenshots_dir = os.path.expandvars(r"%USERPROFILE%\Pictures\Screenshots")
    if not os.path.isdir(screenshots_dir):
        return None
    pngs = sorted(
        [f for f in os.listdir(screenshots_dir) if f.startswith("screenshot_") and f.endswith(".png")],
        key=lambda f: os.path.getmtime(os.path.join(screenshots_dir, f)),
        reverse=True,
    )
    if pngs:
        return os.path.join(screenshots_dir, pngs[0])
    return None


def watch_screenshots(lang: str = "chi_sim+eng"):
    """Watch the screenshots folder for new images and OCR them."""
    screenshots_dir = os.path.expandvars(r"%USERPROFILE%\Pictures\Screenshots")
    print(f" Watching for new screenshots in: {screenshots_dir}")
    print(f"   Language: {lang}")
    seen = set(os.listdir(screenshots_dir))

    while True:
        try:
            current = set(os.listdir(screenshots_dir))
            new_files = current - seen

            for filename in sorted(new_files):
                if filename.startswith("screenshot_") and filename.endswith(".png"):
                    filepath = os.path.join(screenshots_dir, filename)
                    print(f"\n{'='*50}")
                    print(f" New screenshot: {filename}")
                    print(f"{'='*50}")
                    text = ocr_image(filepath, lang=lang)
                    if text:
                        print(text)
                    else:
                        print(" (no text detected)")

                    # Save OCR result
                    txt_path = filepath.replace(".png", ".txt")
                    with open(txt_path, "w", encoding="utf-8") as f:
                        f.write(text or "[No text detected]")
                    print(f" Saved: {txt_path}")
                    print(f"{'='*50}")

            seen = current
            import time
            time.sleep(1)
        except KeyboardInterrupt:
            print("\n Stopped.")
            break
        except Exception as e:
            print(f" Error: {e}")
            import time
            time.sleep(2)


if __name__ == "__main__":
    lang = os.environ.get("OCR_LANG", "chi_sim+eng")

    if len(sys.argv) > 1:
        if sys.argv[1] == "--watch":
            watch_screenshots(lang=lang)
        elif sys.argv[1] == "--lang":
            lang = sys.argv[2] if len(sys.argv) > 2 else "eng"
            path = sys.argv[3] if len(sys.argv) > 3 else get_latest_screenshot()
            if path:
                text = ocr_image(path, lang=lang)
                print(text or "(no text detected)")
        else:
            path = sys.argv[1]
            if os.path.isfile(path):
                text = ocr_image(path, lang=lang)
                print(text or "(no text detected)")
                # Save result alongside image
                txt_path = os.path.splitext(path)[0] + ".txt"
                with open(txt_path, "w", encoding="utf-8") as f:
                    f.write(text or "[No text detected]")
                print(f"\n Saved: {txt_path}")
            else:
                print(f"File not found: {path}")
                sys.exit(1)
    else:
        # Default: OCR the latest screenshot
        path = get_latest_screenshot()
        if path:
            print(f" Latest screenshot: {os.path.basename(path)}")
            text = ocr_image(path, lang=lang)
            if text:
                print(f"\n{text}")
            else:
                print(" (no text detected)")
            txt_path = os.path.splitext(path)[0] + ".txt"
            with open(txt_path, "w", encoding="utf-8") as f:
                f.write(text or "[No text detected]")
            print(f"\n Saved: {txt_path}")
        else:
            print("No screenshots found. Usage: python ocr.py <image_path>")
            sys.exit(1)
