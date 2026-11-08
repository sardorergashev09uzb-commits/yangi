#!/usr/bin/env bash
set -e

GODOT_BIN="${GODOT_BIN:-$HOME/godot/Godot_v4.3-stable_linux.x86_64}"

if [ ! -f "$GODOT_BIN" ]; then
    echo "Godot binary topilmadi: $GODOT_BIN"
    exit 1
fi

echo "=== ALPOMISH O'YININI EKSPORT QILISH VA YIG'ISH ==="
mkdir -p builds/linux builds/windows

echo "1. Resurslar paketi (PCK) yig'ilmoqda..."
"$GODOT_BIN" --headless --path . --export-pack "Linux/X11" builds/linux/alpomish.pck

echo "2. Windows paketi..."
cp builds/linux/alpomish.pck builds/windows/alpomish.pck

echo "3. Binar fayllar tayyorlanmoqda..."
cp "$GODOT_BIN" builds/linux/alpomish.x86_64
chmod +x builds/linux/alpomish.x86_64

echo "=== MUVAFFAQIYATLI YIG'ILDI! ==="
ls -lh builds/linux/ builds/windows/
