#!/usr/bin/env python3
"""Gate C command-based smoke check, not an agent-device Agent Pass."""
import os, re, subprocess, time, xml.etree.ElementTree as ET
from pathlib import Path
root=Path(__file__).resolve().parents[1]
serial=os.environ.get('DEMO_ANDROID_SERIAL','emulator-5580')
adb=str(Path(os.environ.get('ANDROID_HOME', str(Path.home()/'Library/Android/sdk')))/'platform-tools/adb')
out=root/'artifacts/android/runtime';out.mkdir(parents=True,exist_ok=True)
def run(*args): return subprocess.check_output([adb,'-s',serial,*args],stderr=subprocess.STDOUT)
def snapshot():
    run('shell','uiautomator','dump','/sdcard/agentdevice-window.xml')
    data=run('exec-out','cat','/sdcard/agentdevice-window.xml')
    (out/'gate-c-ui.xml').write_bytes(data)
    return ET.fromstring(data)
def find(tag):
    deadline=time.monotonic()+15
    while time.monotonic()<deadline:
        tree=snapshot()
        for e in tree.iter('node'):
            if e.get('resource-id')==tag: return e
        time.sleep(.3)
    raise AssertionError('Missing stable identifier: '+tag)
def tap(tag):
    e=find(tag); x1,y1,x2,y2=map(int,re.findall(r'\d+',e.attrib['bounds']))
    run('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
try:
    tap('login.email');run('shell','input','text','demo@example.com')
    tap('login.password');run('shell','input','text','demo1234')
    run('shell','input','keyevent','4')
    tap('login.submit');find('home.title')
    tap('home.profile');find('profile.title');find('profile.name')
    assert find('profile.reminder').get('checked')=='false'
    tap('profile.reminder');assert find('profile.reminder').get('checked')=='true'
    tap('profile.save');find('profile.saved')
    assert not any(e.get('resource-id')=='login.error' for e in snapshot().iter('node'))
    (out/'gate-c-saved.png').write_bytes(run('exec-out','screencap','-p'))
    (out/'gate-c-result.txt').write_text('PASS: command-based smoke, not Agent Pass\n')
    print('Gate C smoke PASS')
except Exception as error:
    (out/'gate-c-result.txt').write_text('FAIL: '+str(error)+'\n')
    (out/'gate-c-failure.png').write_bytes(run('exec-out','screencap','-p'))
    raise
