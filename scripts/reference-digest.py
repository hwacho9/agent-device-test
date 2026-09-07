#!/usr/bin/env python3
from pathlib import Path
import hashlib,sys
root=Path(sys.argv[1])
files=sorted(root.rglob('*.png'))
if len(files)!=11: raise SystemExit(f'Expected 11 references, got {len(files)}: {root}')
h=hashlib.sha256()
for p in files: h.update(str(p.relative_to(root)).encode());h.update(p.read_bytes())
print(h.hexdigest())
