#!/usr/bin/env python3
"""Generate placeholder Sprites/ and Music/ so a code-only clone can boot headlessly.

Both directories are gitignored on purpose (see README): the art is large and the
music is third-party. That makes a fresh clone unbootable, so nothing past
"does every script compile" can be verified. These stubs are structurally valid
files of the right type at the right paths -- enough for Godot's importers to
succeed and for every scene to build. They are not the real assets and are never
committed.
"""
import os, re, struct, zlib, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# --- PNG ------------------------------------------------------------------
def png(w, h):
    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)   # 8-bit RGBA
    # Opaque magenta, so anything that does render is obviously a placeholder.
    row = b"\x00" + b"\xff\x00\xff\xff" * w
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(row * h)) + chunk(b"IEND", b""))

# --- JPEG (baseline, 8x8, grey) ------------------------------------------
def jpeg():
    std_dqt = bytes([16] * 64)
    # Annex K luminance Huffman tables.
    dc_bits = bytes([0,1,5,1,1,1,1,1,1,0,0,0,0,0,0,0])
    dc_vals = bytes(range(12))
    ac_bits = bytes([0,2,1,3,3,2,4,3,5,5,4,4,0,0,1,0x7d])
    ac_vals = bytes([
        0x01,0x02,0x03,0x00,0x04,0x11,0x05,0x12,0x21,0x31,0x41,0x06,0x13,0x51,0x61,
        0x07,0x22,0x71,0x14,0x32,0x81,0x91,0xa1,0x08,0x23,0x42,0xb1,0xc1,0x15,0x52,
        0xd1,0xf0,0x24,0x33,0x62,0x72,0x82,0x09,0x0a,0x16,0x17,0x18,0x19,0x1a,0x25,
        0x26,0x27,0x28,0x29,0x2a,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x43,0x44,0x45,
        0x46,0x47,0x48,0x49,0x4a,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x63,0x64,
        0x65,0x66,0x67,0x68,0x69,0x6a,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x83,
        0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,
        0x9a,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xb2,0xb3,0xb4,0xb5,0xb6,
        0xb7,0xb8,0xb9,0xba,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xd2,0xd3,
        0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,0xe1,0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,
        0xe9,0xea,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa])
    def seg(marker, payload):
        return bytes([0xff, marker]) + struct.pack(">H", len(payload) + 2) + payload
    out = b"\xff\xd8"
    out += seg(0xe0, b"JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
    out += seg(0xdb, b"\x00" + std_dqt)
    out += seg(0xc0, struct.pack(">BHHB", 8, 8, 8, 1) + bytes([1, 0x11, 0]))
    out += seg(0xc4, b"\x00" + dc_bits + dc_vals)
    out += seg(0xc4, b"\x10" + ac_bits + ac_vals)
    out += seg(0xda, bytes([1, 1, 0x00, 0, 63, 0]))
    # One MCU: DC category 0 (code "00"), then EOB (code "1010"), padded with 1s.
    out += bytes([0b00101011 | 0b00000111])
    out += b"\xff\xd9"
    return out

# --- WAV (16-bit PCM silence) --------------------------------------------
def wav(seconds=0.25, rate=22050):
    n = int(rate * seconds)
    data = b"\x00\x00" * n
    return (b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt "
            + struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16)
            + b"data" + struct.pack("<I", len(data)) + data)

# --- MP3 (MPEG-1 Layer III, silent frames) -------------------------------
def mp3(frames=40):
    # 0xFFFB: MPEG-1, Layer III, no CRC. 0x90: 128kbps, 44.1kHz, no padding.
    # 0x00: stereo, no emphasis. A 128k/44.1k frame is 417 bytes and the
    # decoder is happy to read zeroed main_data as silence.
    header = b"\xff\xfb\x90\x00"
    return (header + b"\x00" * (417 - len(header))) * frames

# --- OGG Vorbis ----------------------------------------------------------
def ogg_page(serial, seq, granule, flags, payload):
    segs = []
    remaining = len(payload)
    while remaining >= 255:
        segs.append(255); remaining -= 255
    segs.append(remaining)
    head = (b"OggS" + bytes([0]) + bytes([flags])
            + struct.pack("<q", granule) + struct.pack("<I", serial)
            + struct.pack("<I", seq) + struct.pack("<I", 0)
            + bytes([len(segs)]) + bytes(segs))
    crc = ogg_crc(head + payload)
    return head[:22] + struct.pack("<I", crc) + head[26:] + payload

_OGG_TABLE = []
def ogg_crc(data):
    if not _OGG_TABLE:
        for i in range(256):
            r = i << 24
            for _ in range(8):
                r = ((r << 1) ^ 0x04c11db7) & 0xffffffff if r & 0x80000000 else (r << 1) & 0xffffffff
            _OGG_TABLE.append(r)
    crc = 0
    for b in data:
        crc = ((crc << 8) & 0xffffffff) ^ _OGG_TABLE[((crc >> 24) & 0xff) ^ b]
    return crc

def ogg():
    serial = 0x5350414d
    ident = (b"\x01vorbis" + struct.pack("<I", 0) + bytes([1])
             + struct.pack("<I", 44100) + struct.pack("<iii", 0, 128000, 0)
             + bytes([0xb8]) + bytes([1]))
    comment = (b"\x03vorbis" + struct.pack("<I", 6) + b"hollow"
               + struct.pack("<I", 0) + bytes([1]))
    # A real setup header needs valid codebooks; an empty-ish one is enough for
    # the importer to accept the stream as Vorbis.
    setup = b"\x05vorbis" + b"\x00" * 32
    pages = ogg_page(serial, 0, 0, 0x02, ident)
    pages += ogg_page(serial, 1, 0, 0x00, comment + setup)
    pages += ogg_page(serial, 2, 1024, 0x04, b"\x00" * 16)
    return pages

MAKERS = {
    ".png": lambda p: png(1024, 1024),
    ".jpg": lambda p: jpeg(),
    ".wav": lambda p: wav(),
    ".mp3": lambda p: mp3(),
    ".ogg": lambda p: ogg(),
}

def main():
    refs = set()
    # Paths in these scenes contain spaces, parentheses and brackets, so this
    # takes everything up to the closing quote rather than a character class.
    pat = re.compile(rb'res://([^"\n]*?\.(?:png|jpg|mp3|wav|ogg))["\n]')
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".godot", ".git", "addons")]
        for fn in filenames:
            if not fn.endswith((".tscn", ".tres")):
                continue
            with open(os.path.join(dirpath, fn), "rb") as fh:
                refs.update(m.decode() for m in pat.findall(fh.read()))

    made = 0
    for rel in sorted(refs):
        path = os.path.join(ROOT, rel)
        if os.path.exists(path):
            continue
        ext = os.path.splitext(rel)[1].lower()
        maker = MAKERS.get(ext)
        if maker is None:
            print("no maker for", rel); continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(maker(rel))
        made += 1
    print("created %d placeholder assets" % made)

if __name__ == "__main__":
    main()
