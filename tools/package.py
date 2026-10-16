"""Build a self-contained installable folder inside a ZIP; no third-party packages."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parent.parent
addon = root / "HerbValue"
toc = addon / "HerbValue.toc"
for line in toc.read_text().splitlines():
    line = line.strip()
    if line and not line.startswith("#"):
        if not (addon / line).is_file():
            raise SystemExit(f"Missing TOC source: {line}")

output = root / "dist" / "HerbValue-1.0.0.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for path in sorted(addon.iterdir()):
        if path.is_file():
            archive.write(path, "HerbValue/" + path.name)
    archive.write(root / "README.md", "HerbValue/README.md")
    for path in sorted((root / "docs").glob("*.md")):
        archive.write(path, "HerbValue/docs/" + path.name)
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert "HerbValue/HerbValue.toc" in archive.namelist()
    assert all(name.startswith("HerbValue/") for name in archive.namelist())
print(output)
