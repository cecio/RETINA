#!/usr/bin/env python3

import argparse
import subprocess
import sys
import re
import os
import requests
import struct
from pathlib import Path
import random

# Custom section
hvsc_download_url = "https://hvsc.brona.dk/HVSC/HVSC_82-all-of-them.rar"
capa_exe = "capa"
java_cmd = "java"
kickassembler_cmd = "/opt/KickAss/KickAss.jar"
retina_src = "src"

CLOCK_MAP = {
    0: "Unknown",
    1: "PAL",
    2: "NTSC",
    3: "PAL&NTSC",
}

def get_valid_sid():
    local_filename = hvsc_download_url.split('/')[-1]
    extract_path = local_filename.replace('.rar', '')
    download_and_uncompress(hvsc_download_url, local_filename, extract_path)
    valid_sid = []
    for sid_path in collect_sid_files(extract_path):
        info = read_sid_header(sid_path)
        if (info['init_address'] == 0x1000 and 
            info['play_address'] == 0x1003 and
            info['speed_mask'] == '$00000000' and
            info['clock'] == 'PAL' and
            info['file_size'] <= 0x1000):
                valid_sid.append(info)
    return valid_sid

def read_sid_header(path):

    file_size = path.stat().st_size

    with path.open("rb") as f:
        header = f.read(0x7C)              # grab enough to cover v4 fields
    if len(header) < 0x16:
        raise ValueError("File too small to be a valid SID")

    # Offsets are big-endian
    # ----- mandatory part -----
    magic      = header[0:4].decode("ascii", "replace")
    if magic not in ("PSID", "RSID"):
        raise ValueError(f"Bad magic: {magic!r}")

    version     = struct.unpack(">H", header[4:6])[0]
    load_addr   = struct.unpack(">H", header[8:10])[0]
    init_addr   = struct.unpack(">H", header[10:12])[0]
    play_addr   = struct.unpack(">H", header[12:14])[0]
    speed_mask  = struct.unpack(">I", header[0x12:0x16])[0]   # 0x12 == 18

    # ----- optional flags (v ≥ 2) -----
    if version >= 2 and len(header) >= 0x78:
        raw_flag   = struct.unpack(">H", header[0x76:0x78])[0]
        clock_bits = (raw_flag >> 2) & 0b11
        clock      = CLOCK_MAP.get(clock_bits, "Unknown")
    else:
        clock = "n/a (version 1 header)"

    return {
        "file_name"    : str(path),
        "file_size"    : file_size,
        "magic"        : magic,
        "version"      : version,
        "load_address" : load_addr,
        "init_address" : init_addr,
        "play_address" : play_addr,
        "speed_mask"   : f"$%08X" % speed_mask,
        "clock"        : clock,
    }

def collect_sid_files(root):
    root_path = Path(root) 
    if root_path.is_file():
        if root_path.suffix.lower() == ".sid":
            yield root_path
        return
    yield from root_path.rglob("*.sid")

def patch_sid_reference(
    asm_file,
    sid_filename,
    create_backup=True,
):
    IMPORT_RE = re.compile(
        r'(\.import\s+binary\s+")([^"]*)(",\s*\$7E)',  # 3 capture groups
        flags=re.IGNORECASE,
    )
    asm_path = Path(asm_file)
    text = asm_path.read_text(encoding="utf-8")

    # Build the replacement string on-the-fly: keep groups 1 & 3, swap group 2
    repl = r'\1' + sid_filename + r'\3'
    new_text, n_subs = IMPORT_RE.subn(repl, text, count=1)

    if n_subs == 0:
        return False  # no `.import binary` line with , $7E found

    if create_backup:
        asm_path.with_suffix(asm_path.suffix + ".bak").write_text(text, encoding="utf-8")

    asm_path.write_text(new_text, encoding="utf-8")
    return True

def download_and_uncompress(url, local_path, extract_to):
    # Check if file is already downloaded
    if not os.path.exists(local_path):
        print("Downloading...", local_path)
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(local_path, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)

    # Check if extraction is already done
    if not os.path.exists(extract_to):
        print("Extracting...", extract_to)
        os.makedirs(extract_to, exist_ok=True)
        subprocess.run(['unrar', 'x', '-y', local_path, extract_to], check=True)

# Function to parse capa output
def parse_capa_output(output):
    result = {}

    # Extract md5
    md5_match = re.search(r'md5\s+([a-fA-F0-9]{32})', output)
    result['md5'] = md5_match.group(1) if md5_match else None

    # Extract rules
    rules_pattern = re.compile(r'([^\n]+)\nnamespace\s+[^\n]+\nscope\s+([^\n]+)\nmatches\s+((?:0x[0-9A-Fa-f]+\s*)+)', re.MULTILINE)
    rules = []
    for match in rules_pattern.finditer(output):
        title = match.group(1).strip().lower()
        scope = match.group(2).strip().lower()
        matches = re.findall(r'0x[0-9A-Fa-f]+', match.group(3))
        matches = [ x.lower() for x in matches ]
        rules.append({
            'title': title[:35],
            'scope': scope,
            'matches': matches
        })

    result['rules'] = rules

    return result

def generate_asm(result):
    comment_separator = "//==============================================================================\n"
    
    # TODO: customize depending on malware
    mdBckgrndColor1 = "DARK_GRAY"
    mdBckgrndColor2 = "YELLOW"
    featuresNum = len(result['rules'])
    with open(retina_src + "/malwareData.asm", "w") as asm:
        asm.write(comment_separator)
        asm.write("//                              Malware Data File\n")
        asm.write(comment_separator)
        asm.write("\n#importonce\n")
        asm.write("\n// Includes\n//\n\n")
        asm.write(comment_separator)
        asm.write("// BackGround Colors, depending on Malware Type\n//\n\n")
        asm.write(f".const mdBckgrndColor1 = {mdBckgrndColor1}\n")
        asm.write(f".const mdBckgrndColor2 = {mdBckgrndColor2}\n\n")
        asm.write(comment_separator)
        asm.write("// File MD5\n//\n\n")
        asm.write(f"mdMD5:              .text \"{result['md5']}\"\n")
        asm.write("                    .byte 0\n\n")
        asm.write(comment_separator)
        asm.write("// Features\n//\n\n")
        asm.write(f".const mdFeatureNum = {featuresNum}\n\n")
        asm.write("mdCurrentFeature:  .byte 0\n\n// Pointers to Rules strings\n")
        # Rules
        asm.write("mdRulesPtrs:       .word ")
        for i in range(1, featuresNum + 1):
            asm.write(f"mdRule{i}")
            if i < featuresNum:
                asm.write(", ")
        asm.write("\n\n")
        for i in range(1, featuresNum + 1):
            asm.write(f"mdRule{i}:        .text \"{result['rules'][i-1]['title']}\"\n")
            asm.write(f"                .byte 0\n")
        # Scopes
        asm.write(f"\n// Pointers to Scopes\n")
        asm.write("mdScopePtrs:    .word ")
        for i in range(1, featuresNum + 1):
            asm.write(f"mdScope{i}")
            if i < featuresNum:
                asm.write(", ")
        asm.write("\n\n")
        for i in range(1, featuresNum + 1):
            asm.write(f"mdScope{i}:       .text \"{result['rules'][i-1]['scope']}\"\n")
            asm.write(f"                .byte 0\n")
        # Matches
        asm.write(f"\n// Pointers to Matches\n")
        asm.write("mdMatchesPtrs:  .word ")        
        for i in range(1, featuresNum + 1):
            asm.write(f"mdMatch{i}")
            if i < featuresNum:
                asm.write(", ")
        asm.write("\n\n")       
        for i in range(1, featuresNum + 1):
            m = result['rules'][i-1]
            asm.write(f"mdMatch{i}:       .text \"{', '.join(m['matches'][:3])}\"\n")
            asm.write(f"                .byte 0\n")    
    return

def main():
    parser = argparse.ArgumentParser(
        description="R.E.T.I.N.A. Builder"
    )
    parser.add_argument("filename", help="Malware file to be analyzed")
    parser.add_argument("--sid", help="SID file to use (default is random)")
    args = parser.parse_args()
    filename = args.filename

    print("[+] Executing file analysis, may take a while...")
    try:
        # Run capa
        result = subprocess.run(
            [capa_exe, "-v", filename ],
            capture_output=True,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        print("Error running capa:", e, file=sys.stderr)
        sys.exit(1)

    print("[+] Parsing result")
    result = parse_capa_output(result.stdout)

    print("[+] Generating ASM file")
    generate_asm(result)
    
    print("[+] Processing music")
    valid_sid = get_valid_sid()
    sid = random.choice(valid_sid)
    print(f"   Randomly choosing from {len(valid_sid)} SID files")
    print(f"   Using SID file {sid['file_name']}")
    patch_sid_reference(retina_src + "/gameData.asm", sid['file_name'])

    print("[+] Compiling R.E.T.I.N.A.")
    try:
        # Compile program 
        result = subprocess.run(
            [java_cmd, "-jar", kickassembler_cmd, retina_src + "/main.asm" ],
            capture_output=True,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        print("Error compiling:", e, file=sys.stderr)
        sys.exit(1)
        
    sys.exit(0)

if __name__ == "__main__":
    main()

