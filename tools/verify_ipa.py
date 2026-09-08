"""Inspect the packaged IPA without changing or signing it."""

import hashlib
import plistlib
import sys
import zipfile
from pathlib import Path


def main():
    path = Path(sys.argv[1])
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, "Corrupt IPA archive"
        prefix = "Payload/HearStars.app/"
        info = plistlib.loads(archive.read(prefix + "Info.plist"))
        assert info["CFBundleIdentifier"] == "com.example.HearStars"
        assert info["CFBundleShortVersionString"] == "0.1.0"
        assert info["CFBundleVersion"] == "3"
        for language in ("ja", "en"):
            strings = plistlib.loads(archive.read(prefix + language + ".lproj/Localizable.strings"))
            assert strings["readiness.calibrating.title"] == (
                "方角の調整が必要です" if language == "ja" else "Direction needs adjusting"
            )
            print(f"{language}: {len(strings)} bundled translations verified")
    print(f"IPA: {info['CFBundleShortVersionString']} ({info['CFBundleVersion']})")
    print(f"Size: {path.stat().st_size:,} bytes")
    print(f"SHA-256: {hashlib.sha256(path.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
