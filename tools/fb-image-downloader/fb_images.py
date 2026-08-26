#!/usr/bin/env python3
"""Download every image from Facebook posts onto your computer.

ดึงรูปจากโพสต์ Facebook ลงเครื่องคอมพิวเตอร์

Three ways to use it — see README.md for the step-by-step Thai version.

  1. From a Facebook URL (needs your login cookies):
       python3 fb_images.py "https://www.facebook.com/share/XXXX/" --browser chrome

  2. From pages you saved in the browser (Ctrl+S / Cmd+S, no login needed):
       python3 fb_images.py --from-html "saved page.html"

  3. From a plain text file of image URLs, one per line:
       python3 fb_images.py --from-list urls.txt

Only the standard library is required for modes 2 and 3. Mode 1 works best
with gallery-dl installed (`pip install gallery-dl`), which knows how to walk
a whole profile/page and paginate through every post; without it this script
falls back to scraping whatever the single page returns.
"""

from __future__ import annotations

import argparse
import html
import http.cookiejar
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
)

# Any fbcdn/scontent asset. Matched against raw HTML *and* the escaped JSON
# blobs Facebook embeds in <script> tags, so backslashes are tolerated here
# and unescaped afterwards.
IMAGE_URL_RE = re.compile(
    r"https?:\\?/\\?/[\w.-]*fbcdn\.net\\?/[^\s\"'<>\\]*"
    r"(?:\\.|[^\s\"'<>\\])*",
    re.IGNORECASE,
)

IMAGE_EXT_RE = re.compile(r"\.(jpe?g|png|webp|gif)$", re.IGNORECASE)

# Static site chrome, emoji sprites and UI icons — never post content.
JUNK_MARKERS = ("rsrc.php", "/emoji/", "safe_image.php", "/images/emoji")

# Facebook's own filename suffix, best quality first.
QUALITY_SUFFIX_RANK = {"o": 3, "n": 2, "b": 1}


def log(msg: str) -> None:
    print(msg, flush=True)


# --------------------------------------------------------------------------
# URL handling
# --------------------------------------------------------------------------


def unescape_url(raw: str) -> str:
    """Turn an embedded/escaped URL back into a real one."""
    url = raw.replace("\\/", "/").replace("\\u0025", "%").replace("\\", "")
    url = html.unescape(url)
    return url.rstrip(").,;'\"")


def strip_size_params(url: str) -> str:
    """Drop the query params that force Facebook to serve a downscaled copy.

    `stp` is the resize/crop instruction (e.g. `stp=dst-jpg_s600x600`).
    Removing it usually yields the full-size original from the same CDN path.
    """
    parts = urllib.parse.urlsplit(url)
    if not parts.query:
        return url
    kept = [
        (k, v)
        for k, v in urllib.parse.parse_qsl(parts.query, keep_blank_values=True)
        if k != "stp"
    ]
    return urllib.parse.urlunsplit(parts._replace(query=urllib.parse.urlencode(kept)))


def _basename(url: str) -> str:
    return urllib.parse.urlsplit(url).path.rsplit("/", 1)[-1]


def image_key(url: str) -> str:
    """Identity of the *photo*, independent of which size variant this URL is.

    Facebook names files `<setid>_<photoid>_<variantid>_n.jpg`, so the numeric
    run is stable across every rendition of the same picture.
    """
    name = _basename(url)
    ids = re.findall(r"\d{6,}", name)
    return "_".join(ids) if ids else name


def quality_score(url: str) -> tuple[int, int, int]:
    """Rank two URLs pointing at the same photo. Higher is better."""
    name = _basename(url)
    suffix = re.search(r"_([a-z])\.(?:jpe?g|png|webp|gif)$", name, re.IGNORECASE)
    rank = QUALITY_SUFFIX_RANK.get(suffix.group(1).lower(), 0) if suffix else 0

    # Explicit pixel hints, in the path (`/p720x720/`) or the stp param.
    pixels = 0
    for w, h in re.findall(r"[psc](\d{2,5})x(\d{2,5})", url):
        pixels = max(pixels, int(w) * int(h))

    unresized = 0 if "stp=" in url else 1
    return (unresized, pixels, rank)


def looks_like_photo(url: str) -> bool:
    lowered = url.lower()
    if any(marker in lowered for marker in JUNK_MARKERS):
        return False
    return bool(IMAGE_EXT_RE.search(urllib.parse.urlsplit(url).path))


def extract_image_urls(text: str) -> list[str]:
    """Pull every distinct post image out of a page's HTML/JSON."""
    best: dict[str, str] = {}
    for raw in IMAGE_URL_RE.findall(text):
        url = unescape_url(raw)
        if not looks_like_photo(url):
            continue
        key = image_key(url)
        current = best.get(key)
        if current is None or quality_score(url) > quality_score(current):
            best[key] = url
    return [strip_size_params(u) for u in best.values()]


# --------------------------------------------------------------------------
# Network
# --------------------------------------------------------------------------


def build_opener(cookies_file: str | None) -> urllib.request.OpenerDirector:
    handlers: list[urllib.request.BaseHandler] = []
    if cookies_file:
        jar = http.cookiejar.MozillaCookieJar()
        jar.load(cookies_file, ignore_discard=True, ignore_expires=True)
        handlers.append(urllib.request.HTTPCookieProcessor(jar))
    opener = urllib.request.build_opener(*handlers)
    opener.addheaders = [
        ("User-Agent", USER_AGENT),
        ("Accept-Language", "th-TH,th;q=0.9,en;q=0.8"),
        ("Referer", "https://www.facebook.com/"),
    ]
    return opener


def resolve_share_url(url: str, opener: urllib.request.OpenerDirector) -> str:
    """Expand a /share/XXXX/ short link into the real post URL."""
    if "/share/" not in url:
        return url
    try:
        with opener.open(url, timeout=30) as resp:
            final = resp.geturl()
    except (urllib.error.URLError, OSError) as exc:
        log(f"  ! could not expand the share link ({exc}); using it as-is")
        return url
    if final != url:
        log(f"  share link points to: {final}")
    return final


def fetch_text(url: str, opener: urllib.request.OpenerDirector) -> str:
    with opener.open(url, timeout=60) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset, errors="replace")


def download_one(
    url: str,
    dest: str,
    opener: urllib.request.OpenerDirector,
    min_size: int,
    retries: int = 3,
) -> tuple[bool, str]:
    """Fetch one image. Returns (saved, reason)."""
    for attempt in range(1, retries + 1):
        try:
            with opener.open(url, timeout=90) as resp:
                ctype = resp.headers.get("Content-Type", "")
                if "image" not in ctype:
                    return False, f"not an image ({ctype or 'unknown type'})"
                data = resp.read()
            break
        except (urllib.error.URLError, OSError) as exc:
            if attempt == retries:
                return False, f"download failed: {exc}"
            time.sleep(2 * attempt)
    else:  # pragma: no cover - loop always breaks or returns
        return False, "download failed"

    if len(data) < min_size:
        return False, f"too small ({len(data)} bytes) — looks like an icon"

    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    with open(dest, "wb") as fh:
        fh.write(data)
    return True, f"{len(data) // 1024} KB"


def download_all(
    urls: list[str],
    out_dir: str,
    opener: urllib.request.OpenerDirector,
    min_size: int,
    limit: int | None,
    dry_run: bool,
) -> int:
    if limit:
        urls = urls[:limit]

    saved = 0
    for index, url in enumerate(urls, start=1):
        name = _basename(url) or f"image_{index}.jpg"
        if not IMAGE_EXT_RE.search(name):
            name += ".jpg"
        dest = os.path.join(out_dir, f"{index:03d}_{name}")

        if dry_run:
            log(f"[{index}/{len(urls)}] would save {dest}")
            saved += 1
            continue

        if os.path.exists(dest):
            log(f"[{index}/{len(urls)}] already have {os.path.basename(dest)}")
            saved += 1
            continue

        ok, reason = download_one(url, dest, opener, min_size)
        status = "saved" if ok else "skipped"
        log(f"[{index}/{len(urls)}] {status} {os.path.basename(dest)} — {reason}")
        if ok:
            saved += 1
        time.sleep(0.4)  # be gentle with the CDN

    return saved


# --------------------------------------------------------------------------
# gallery-dl integration
# --------------------------------------------------------------------------


def run_gallery_dl(
    url: str, out_dir: str, browser: str | None, cookies: str | None, limit: int | None
) -> bool:
    """Hand the URL to gallery-dl, which paginates whole profiles properly."""
    exe = shutil.which("gallery-dl")
    if not exe:
        return False

    cmd = [exe, "--dest", out_dir, "--write-metadata"]
    if browser:
        cmd += ["--cookies-from-browser", browser]
    elif cookies:
        cmd += ["--cookies", cookies]
    if limit:
        cmd += ["--range", f"1-{limit}"]
    cmd.append(url)

    log(f"  running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        log(f"  ! gallery-dl exited with code {result.returncode}")
        return False
    return True


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download all images from Facebook posts.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("url", nargs="?", help="Facebook post, photo or page URL")
    parser.add_argument(
        "--from-html",
        action="append",
        default=[],
        metavar="FILE",
        help="a page you saved from the browser; repeatable",
    )
    parser.add_argument(
        "--from-list", metavar="FILE", help="text file of image URLs, one per line"
    )
    parser.add_argument(
        "-o", "--out", default="fb-images", help="output folder (default: fb-images)"
    )
    parser.add_argument(
        "--browser",
        help="take login cookies from this browser: chrome, firefox, edge, safari, brave",
    )
    parser.add_argument("--cookies", metavar="FILE", help="cookies.txt (Netscape format)")
    parser.add_argument("--limit", type=int, help="stop after this many images")
    parser.add_argument(
        "--min-size",
        type=int,
        default=15000,
        help="skip files smaller than this many bytes (default: 15000)",
    )
    parser.add_argument(
        "--no-gallery-dl",
        action="store_true",
        help="always scrape directly instead of using gallery-dl",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="list what would be downloaded"
    )

    args = parser.parse_args(argv)
    if not args.url and not args.from_html and not args.from_list:
        parser.error("give a Facebook URL, --from-html, or --from-list")
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    os.makedirs(args.out, exist_ok=True)
    opener = build_opener(args.cookies)

    urls: list[str] = []

    if args.from_list:
        with open(args.from_list, encoding="utf-8") as fh:
            urls += [line.strip() for line in fh if line.strip() and not line.startswith("#")]
        log(f"read {len(urls)} URLs from {args.from_list}")

    for path in args.from_html:
        with open(path, encoding="utf-8", errors="replace") as fh:
            found = extract_image_urls(fh.read())
        log(f"found {len(found)} images in {path}")
        urls += found

    if args.url:
        if not args.no_gallery_dl and run_gallery_dl(
            args.url, args.out, args.browser, args.cookies, args.limit
        ):
            log(f"\nDone — gallery-dl saved everything into {os.path.abspath(args.out)}")
            return 0

        if not shutil.which("gallery-dl") and not args.no_gallery_dl:
            log("  gallery-dl is not installed — falling back to a direct scrape.")
            log("  For whole profiles/pages install it: pip install gallery-dl\n")

        target = resolve_share_url(args.url, opener)
        try:
            page = fetch_text(target, opener)
        except (urllib.error.URLError, OSError) as exc:
            log(f"! could not open {target}: {exc}")
            log("  Facebook usually needs your login — pass --cookies cookies.txt,")
            log("  or save the page in your browser and use --from-html instead.")
            return 1

        found = extract_image_urls(page)
        log(f"found {len(found)} images on the page")
        if not found and "login" in page[:4000].lower():
            log("  the page returned a login wall; export your cookies and retry")
        urls += found

    # Same photo can arrive from several sources — keep the best copy of each.
    deduped: dict[str, str] = {}
    for url in urls:
        key = image_key(url)
        if key not in deduped or quality_score(url) > quality_score(deduped[key]):
            deduped[key] = url
    final = list(deduped.values())

    if not final:
        log("\nNo images found.")
        return 1

    log(f"\nDownloading {len(final)} images into {os.path.abspath(args.out)}\n")
    saved = download_all(final, args.out, opener, args.min_size, args.limit, args.dry_run)
    log(f"\nDone — {saved}/{len(final)} images in {os.path.abspath(args.out)}")
    return 0 if saved else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
