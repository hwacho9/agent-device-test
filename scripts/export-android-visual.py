#!/usr/bin/env python3
from pathlib import Path
import shutil
root=Path(__file__).resolve().parents[1]
out=root/'artifacts/android/visual'
for dest,source in [('reference','androidApp/src/screenshotTestDebug/reference'),('actual','androidApp/build/outputs/screenshotTest-results/preview/debug/rendered'),('report','androidApp/build/reports/screenshotTest/preview/debug')]:
 p=root/source
 if p.exists(): shutil.copytree(p,out/dest,dirs_exist_ok=True)
(out/'diff').mkdir(parents=True,exist_ok=True)
# The plugin emits differences only when comparison fails; never fabricate a diff.
for p in (root/'androidApp/build/outputs/screenshotTest-results/preview/debug').rglob('*.png'):
 if 'diff' in str(p.relative_to(root/'androidApp/build/outputs/screenshotTest-results/preview/debug')).lower():
  target=out/'diff'/p.name;shutil.copy2(p,target)
