#!/usr/bin/env python3
"""Run a reviewed .ad, then assert the full snapshot. Never heals scripts or records baselines."""
import argparse, hashlib, json, os, shlex, shutil, signal, subprocess, sys, time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('platform',choices=['android','ios']);p.add_argument('--record',action='store_true');args=p.parse_args()
root=Path(__file__).resolve().parents[1];os.chdir(root)
platform=args.platform;session='demo-'+platform
run_id=time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())+'-'+str(os.getpid())
out=root/'artifacts'/platform/'runtime';run_dir=out/'runs'/run_id;run_dir.mkdir(parents=True)
script=root/'e2e'/platform/'login-profile-save.ad';before=hashlib.sha256(script.read_bytes()).hexdigest()
replay_script=script
if args.record:
    # Presentation pacing only. Every original action/assertion and metadata line is preserved.
    paced=[]
    for line in script.read_text().splitlines():
        paced.append(line)
        if not line or line.startswith('#'):continue
        fields=shlex.split(line)
        if fields[0]=='fill' or (fields[0]=='wait' and len(fields)>1 and any(tag in fields[1] for tag in ['login.email','home.title','profile.title','profile.saved'])) or (fields[0]=='is' and 'profile.reminder' in line and ('On' in line or 'value=' in line)):
            paced.extend(['# 1.75s presentation pause; readiness is asserted separately.', 'wait 1750'])
    replay_script=run_dir/'video-scenario.ad'
    replay_script.write_text('\n'.join(paced)+'\n')
ad=['agent-device'];serial=os.environ.get('DEMO_ANDROID_SERIAL','emulator-5580');udid=os.environ['DEMO_IOS_UDID']
binding=['--platform',platform,'--serial',serial] if platform=='android' else ['--platform',platform,'--udid',udid]
log_file=(run_dir/'replay.log').open('w');processes=[];recorder=None;record_file=run_dir/(platform+'-clean-e2e.mp4');remote_video='/sdcard/agent-device-demo-'+run_id+'.mp4';step='reset';success=False

def run(command,timeout=180,capture=False):
    log_file.write('$ '+' '.join(map(str,command))+'\n');log_file.flush()
    result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,timeout=timeout)
    log_file.write(result.stdout+result.stderr);log_file.flush()
    if result.returncode: raise RuntimeError(f'Exit {result.returncode}: {result.stderr[-1500:] or result.stdout[-1500:]}')
    return result.stdout

def cli(*items,capture=False): return run(ad+list(items)+['--session',session],capture=capture)

def stop_recording():
    global recorder
    if recorder is None:return
    if platform=='android':
        # Only this command's owned screenrecord process uses this unique output path.
        listing=run(['adb','-s',serial,'shell','ps','-A','-o','PID,ARGS'])
        for line in listing.splitlines():
            if remote_video in line and 'screenrecord' in line:
                run(['adb','-s',serial,'shell','kill','-2',line.split()[0]])
    else: recorder.send_signal(signal.SIGINT)
    try:recorder.wait(timeout=30)
    except subprocess.TimeoutExpired: recorder.kill();raise RuntimeError('Recording did not finalize')
    recorder=None
    if platform=='android':
        run(['adb','-s',serial,'pull',remote_video,str(record_file)])
        run(['adb','-s',serial,'shell','rm',remote_video])
    if not record_file.exists() or record_file.stat().st_size==0:raise RuntimeError('Missing video')
    run(['ffmpeg','-v','error','-i',str(record_file),'-f','null','-'],timeout=120)
    info=run(['ffprobe','-v','error','-show_format','-show_streams','-of','json',str(record_file)])
    (run_dir/'video-info.json').write_text(info)

try:
    print(f'[REPLAY] {platform}: reset and install',flush=True)
    run(['bash',str(root/'scripts'/('install-'+platform+'.sh'))],timeout=240)
    if platform=='ios':run(['bash','scripts/prepare-ios-agent-device.sh'])
    app_log=(run_dir/'app.log').open('w')
    log_cmd=['adb','-s',serial,'logcat','-v','threadtime'] if platform=='android' else ['xcrun','simctl','spawn',udid,'log','stream','--style','compact','--predicate','process == "AgentDeviceE2EDemo"']
    processes.append(subprocess.Popen(log_cmd,stdout=app_log,stderr=subprocess.STDOUT))
    if args.record:
        step='start recording';rec_log=(run_dir/'recording.log').open('w')
        cmd=['adb','-s',serial,'shell','screenrecord','--size','720x1280','--bit-rate','4000000','--time-limit','120',remote_video] if platform=='android' else ['xcrun','simctl','io',udid,'recordVideo','--codec=h264',str(record_file)]
        recorder=subprocess.Popen(cmd,stdout=rec_log,stderr=subprocess.STDOUT)
        deadline=time.monotonic()+15
        while time.monotonic()<deadline:
            if recorder.poll() is not None:raise RuntimeError('Recorder exited before replay')
            ready=('Recording started' in (run_dir/'recording.log').read_text()) if platform=='ios' else subprocess.run(['adb','-s',serial,'shell','ls',remote_video],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=5).returncode == 0
            if ready:break
            time.sleep(.2)
        else:raise RuntimeError('Recorder readiness timed out')
    step='deterministic replay';print(f'[REPLAY] {platform}: {script.relative_to(root)}',flush=True)
    run(ad+['replay',str(replay_script),'--keep-session','--timeout','120000',*binding,'--session',session],timeout=150)
    step='final snapshot assertion';data=json.loads(cli('snapshot','--json'));(run_dir/'final.json').write_text(json.dumps(data,indent=2))
    nodes=data['data']['nodes']
    for identifier in ['profile.title','profile.name','profile.reminder','profile.saved']:
        assert any(n.get('identifier')==identifier for n in nodes),f'Missing {identifier}'
    assert not any(n.get('identifier')=='login.error' for n in nodes),'Unexpected login.error'
    if platform=='ios':assert any(n.get('identifier')=='profile.reminder' and n.get('value')=='1' for n in nodes),'Reminder is not on'
    else:assert any(n.get('identifier')=='profile.reminder.state' and n.get('value')=='On' for n in nodes),'Reminder is not on'
    assert hashlib.sha256(script.read_bytes()).hexdigest()==before,'Replay mutated the scenario'
    if args.record:
        step='finalize and decode video';stop_recording()
    # agent-device screenshot can normalize display/status-bar presentation.
    # Capture it only after the native video is finalized to keep the video clean.
    step='final screenshot';cli('screenshot',str(run_dir/(platform+'-final.png')))
    step='close';cli('close');success=True
except Exception as error:
    log_file.write('\nFAIL '+repr(error)+'\n');log_file.flush()
    try:cli('screenshot',str(run_dir/(platform+'-failure.png')))
    except Exception:
        try:
            target=run_dir/(platform+'-failure.png')
            if platform=='ios':run(['xcrun','simctl','io',udid,'screenshot',str(target)],timeout=20)
            else:
                with target.open('wb') as f:subprocess.run(['adb','-s',serial,'exec-out','screencap','-p'],stdout=f,timeout=20,check=True)
        except Exception:pass
    print(f'[DEMO RESULT] FAIL\n[FAILED STEP] {step}\n[EXPECTED] reviewed replay, reminder on, Saved, no error\n[ACTUAL] {error}\n[EVIDENCE] {run_dir}',flush=True)
finally:
    if recorder:
        try:stop_recording()
        except Exception as e:log_file.write('Recording cleanup: '+str(e)+'\n')
    for process in processes:
        process.terminate()
        try:process.wait(timeout=5)
        except subprocess.TimeoutExpired:process.kill()
    if not success:
        try:cli('close')
        except Exception:pass
    runner_log=Path(os.environ['AGENT_DEVICE_STATE_DIR'])/'sessions'/session/'runner.log'
    if runner_log.exists():shutil.copy2(runner_log,run_dir/'runner.log')
    (run_dir/'result.txt').write_text(('PASS' if success else 'FAIL')+'\nScenario SHA256: '+before+'\n')
    for file in run_dir.iterdir():
        if (success or file.name != platform+'-clean-e2e.mp4') and file.is_file() and file.name in ['app.log','runner.log','result.txt',platform+'-final.png',platform+'-failure.png',platform+'-clean-e2e.mp4']:
            shutil.copy2(file,out/file.name)
    log_file.close()
if success:print(f'[DEMO RESULT] PASS\n[EVIDENCE] {run_dir}',flush=True)
sys.exit(0 if success else 1)
