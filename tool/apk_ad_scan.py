#!/usr/bin/env python3
"""Scan an Android APK for advertising SDK signatures.

Usage:
    python3 tool/apk_ad_scan.py build/app/outputs/flutter-apk/app-beta-release.apk

Exit codes:
    0  no high-confidence advertising SDK found
    1  high-confidence advertising SDK detected (build should fail)
    2  scan could not be performed (e.g. file missing)

Design notes
------------
Only *high-confidence* markers fail the build.  Broad substrings such as the
word "pangle" can legitimately appear in Dart source comments that survive
into compiled assets, so they are reported but do not fail the run.  A marker
only fails when it is a vendor-specific class path, API class, native library
name, or plugin module marker.
"""
import os
import re
import sys
import zipfile

# --- markers that fail the build -------------------------------------------
# (pattern, label, zones)   zones: "dex" | "so" | "meta" | "assets"
HARD_MARKERS = [
    (b"com/bytedance", "ByteDance SDK namespace (Pangle/TikTok ads)", ("dex", "so")),
    (b"com/bytedance/sdk", "ByteDance SDK namespace", ("dex", "so")),
    (b"PangleAd", "PangleAd API class", ("dex",)),
    (b"PangleNativeAd", "PangleNativeAd API class", ("dex",)),
    (b"PangleBannerAd", "PangleBannerAd API class", ("dex",)),
    (b"PangleSplashAd", "PangleSplashAd API class", ("dex",)),
    (b"TTAdSdk", "TTAdSdk (ByteDance ads)", ("dex", "so")),
    (b"com/qq/e/ads", "GDT 优量汇 (Tencent ads)", ("dex",)),
    (b"com/kwad/sdk", "Kwai 快手联盟 ads", ("dex",)),
    (b"com/baidu/mobads", "Baidu ads", ("dex",)),
    (b"com/google/android/gms/ads", "Google AdMob / Ads", ("dex",)),
    (b"com/applovin", "AppLovin ads", ("dex", "so")),
    (b"com/unity3d/ads", "Unity Ads", ("dex", "so")),
    (b"com/inmobi", "InMobi ads", ("dex", "so")),
    (b"com/mopub", "MoPub ads", ("dex",)),
    (b"com/sigmob", "Sigmob ads", ("dex", "so")),
    (b"com/tradplus", "TradPlus ads", ("dex", "so")),
    (b"com/anythink", "AnyThink / TopOn ads", ("dex", "so")),
]

# --- markers reported but not fatal -----------------------------------------
SOFT_MARKERS = [
    (b"pangle", "literal 'pangle' (may be a Dart source comment)"),
    (b"admob", "literal 'admob'"),
]

# --- native library / file-name markers ------------------------------------
HARD_NAMES = re.compile(
    r"(?i)(libpangle|pangolin|ttadsdk|libkwad|unityads|libapplovin|"
    r"mediationsdk|libtopon|libgdt)"
)
HARD_META = re.compile(r"(?i)(pangle|admob|gdt|kwad|tradplus|anythink|mopub|inmobi)")
HARD_ASSETS = re.compile(r"(?i)(pangle|banner[_-]?ad|ad[_-]?banner|ad[_-]?slot|advert)")


def collect(zf, names):
    blob = bytearray()
    for n in names:
        try:
            blob += zf.read(n)
        except Exception:
            pass
    return bytes(blob)


def main(path):
    if not os.path.isfile(path):
        print(f"::error::APK not found: {path}")
        return 2

    zf = zipfile.ZipFile(path)
    names = zf.namelist()

    dex_names = [n for n in names if n.endswith(".dex")]
    so_names = [n for n in names if n.startswith("lib/") and n.endswith(".so")]
    meta_names = [n for n in names if n.startswith("META-INF/")]
    asset_names = [n for n in names if n.startswith("assets/")]

    zones = {
        "dex": collect(zf, dex_names),
        "so": collect(zf, so_names),
        "meta": collect(zf, meta_names),
        "assets": collect(zf, asset_names),
    }

    print(f"APK              : {path}")
    print(f"size             : {os.path.getsize(path) / 1048576:.2f} MB")
    print(f"entries          : {len(names)}")
    print(f"dex files        : {len(dex_names)} -> {', '.join(dex_names) or '-'}")
    print(f"native libraries : {len(so_names)}")
    for n in so_names:
        print(f"    {n}")
    print()

    failures = []

    print("=== Hard markers (fail the build) ===")
    any_hard = False
    for pattern, label, zs in HARD_MARKERS:
        for z in zs:
            cnt = zones[z].count(pattern)
            if cnt:
                any_hard = True
                failures.append(f"{label} [{z}] x{cnt}")
                print(f"  HIT  {cnt:>6}  {label}  (zone: {z}, pattern: {pattern.decode()})")
    if not any_hard:
        print("  none")

    print("\n=== Hard markers in file names ===")
    sus_so = sorted({n for n in so_names if HARD_NAMES.search(n)})
    sus_meta = sorted({n for n in meta_names if HARD_META.search(n)})
    sus_asset = sorted({n for n in asset_names if HARD_ASSETS.search(n)})
    for n in sus_so:
        failures.append(f"native library {n}")
        print(f"  HIT          native library: {n}")
    for n in sus_meta:
        failures.append(f"META-INF {n}")
        print(f"  HIT          META-INF: {n}")
    for n in sus_asset:
        failures.append(f"asset {n}")
        print(f"  HIT          asset: {n}")
    if not (sus_so or sus_meta or sus_asset):
        print("  none")

    print("\n=== Soft markers (reported only) ===")
    found_soft = False
    for pattern, label in SOFT_MARKERS:
        for z in ("dex", "so", "assets"):
            cnt = zones[z].count(pattern)
            if cnt:
                found_soft = True
                print(f"  note {cnt:>6}  {label}  (zone: {z})")
    if not found_soft:
        print("  none")

    print()
    if failures:
        print("::error::Advertising SDK detected in APK:")
        for f in failures:
            print(f"::error::  - {f}")
        zf.close()
        return 1

    print("::notice::No advertising SDK signature detected in APK.")
    zf.close()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ""))
