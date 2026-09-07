"""Cross-platform structural checks that do not require Xcode or Swift."""

from __future__ import annotations

import json
import plistlib
import re
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "HearStarsApp/Resources/Assets.xcassets"
LOCALIZATION_PATTERN = re.compile(r'^\s*"([^"]+)"\s*=\s*"', re.MULTILINE)
KEY_PREFIXES = (
    "app.", "common.", "mode.", "practice.", "location.", "picker.",
    "safety.", "calibration.", "accuracy.", "finder.", "direction.",
    "discovery.", "compass.", "star.", "readiness.", "constellation.",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def localization_key_list(path: Path) -> list[str]:
    return LOCALIZATION_PATTERN.findall(path.read_text(encoding="utf-8"))


def localization_keys(path: Path) -> set[str]:
    keys = localization_key_list(path)
    require(len(keys) == len(set(keys)), f"Duplicate localization keys: {path}")
    return set(keys)


def png_metadata(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()[:33]
    require(data[:8] == b"\x89PNG\r\n\x1a\n", f"Not a PNG: {path}")
    require(data[12:16] == b"IHDR", f"Missing PNG IHDR: {path}")
    width, height, _depth, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, color_type


def check_assets() -> None:
    root_manifest = json.loads((ASSETS / "Contents.json").read_text(encoding="utf-8"))
    require(root_manifest["info"]["version"] == 1, "Invalid asset root manifest")

    icon_set = ASSETS / "AppIcon.appiconset"
    icon_manifest = json.loads((icon_set / "Contents.json").read_text(encoding="utf-8"))
    images = icon_manifest["images"]
    require(len(images) == 1, "Phase 1 expects one universal App Icon entry")
    icon = icon_set / images[0]["filename"]
    width, height, color_type = png_metadata(icon)
    require((width, height) == (1024, 1024), "App Icon must be exactly 1024×1024")
    require(color_type in (0, 2), "App Icon must not contain an alpha channel")

    json.loads((ASSETS / "AccentColor.colorset/Contents.json").read_text(encoding="utf-8"))


def check_localizations() -> None:
    ja_path = ROOT / "HearStarsApp/Resources/ja.lproj/Localizable.strings"
    en_path = ROOT / "HearStarsApp/Resources/en.lproj/Localizable.strings"
    ja = localization_keys(ja_path)
    en = localization_keys(en_path)
    require(ja == en, f"JA/EN localization keys differ: JA-only={ja-en}, EN-only={en-ja}")

    info_ja = localization_keys(ROOT / "HearStarsApp/Resources/ja.lproj/InfoPlist.strings")
    info_en = localization_keys(ROOT / "HearStarsApp/Resources/en.lproj/InfoPlist.strings")
    expected_info = {
        "CFBundleDisplayName",
        "NSLocationWhenInUseUsageDescription",
        "NSMotionUsageDescription",
    }
    require(info_ja == info_en == expected_info, "JA/EN InfoPlist keys are incomplete or differ")

    swift_lines = [
        line
        for path in (ROOT / "HearStarsApp").rglob("*.swift")
        for line in path.read_text(encoding="utf-8").splitlines()
        if "systemName:" not in line
    ]
    literals = set(
        re.findall(r'"([A-Za-z][A-Za-z0-9_.]+)"', "\n".join(swift_lines))
    )
    referenced = {key for key in literals if key.startswith(KEY_PREFIXES)}
    missing = referenced - ja
    require(not missing, f"Missing localized strings: {sorted(missing)}")


def check_privacy_and_scope() -> None:
    manifest = ROOT / "HearStarsApp/Resources/PrivacyInfo.xcprivacy"
    with manifest.open("rb") as handle:
        privacy = plistlib.load(handle)
    require(privacy.get("NSPrivacyTracking") is False, "Tracking must remain disabled")
    require(not privacy.get("NSPrivacyCollectedDataTypes"), "No collected data is expected")
    accessed = privacy.get("NSPrivacyAccessedAPITypes", [])
    require(
        {
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategorySystemBootTime",
            "NSPrivacyAccessedAPITypeReasons": ["35F9.1"],
        } in accessed,
        "systemUptime timer use must declare the 35F9.1 required reason",
    )

    project_text = "\n".join(
        path.read_text(encoding="utf-8", errors="replace")
        for path in [*(ROOT / "HearStarsApp").rglob("*.swift"), ROOT / "project.yml"]
    )
    for forbidden in (
        "URLSession", "import Network", "Firebase", "Analytics", "AdMob",
        "import ARKit", "AVCaptureSession", "NSCameraUsageDescription",
    ):
        require(forbidden not in project_text, f"Unexpected Phase 1 capability: {forbidden}")


def check_readme_links() -> None:
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    for relative in re.findall(r"\]\(([^)]+)\)", readme):
        if "://" not in relative and not relative.startswith("#"):
            require((ROOT / relative).exists(), f"Broken README link: {relative}")


def main() -> None:
    check_assets()
    check_localizations()
    check_privacy_and_scope()
    check_readme_links()
    print("Project structure: OK")


if __name__ == "__main__":
    main()
