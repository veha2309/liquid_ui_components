"""Publish the already-pushed v0.3.0 tag using Git Credential Manager.

GitHub release tooling is unavailable in the connected GitHub API. Credentials
are kept in memory and never written to output or files. Requires Python only.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
REPO = 'veha2309/liquid_ui_components'
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN')
if not token:
    result = subprocess.run(['git', 'credential', 'fill'],
        input='protocol=https\nhost=github.com\n\n', text=True,
        capture_output=True, check=True, cwd=ROOT)
    fields = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
    token = fields.get('password')
if not token:
    raise SystemExit('No GitHub publishing credential is configured.')

def request(url, payload=None, method=None, content_type='application/json', allow_missing=False):
    data = payload if isinstance(payload, bytes) else json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method,
        headers={'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.github+json',
                 'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': content_type,
                 'User-Agent': 'liquid-ui-components-release'})
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        if error.code == 404 and allow_missing:
            return None
        # Never print request objects or headers containing credentials.
        raise SystemExit(f'GitHub API failed: HTTP {error.code} for {urllib.parse.urlparse(url).path}') from None

repo = request(f'https://api.github.com/repos/{REPO}')
if args.check:
    print(json.dumps({'repository': repo['full_name'], 'can_push': repo.get('permissions', {}).get('push', False)}))
    raise SystemExit(0)

tag = request(f'https://api.github.com/repos/{REPO}/git/ref/tags/v0.3.0')
if not tag.get('object', {}).get('sha'):
    raise SystemExit('Release tag was not found; push and verify it first.')
release = request(f'https://api.github.com/repos/{REPO}/releases/tags/v0.3.0', allow_missing=True)
if release is None:
    release = request(f'https://api.github.com/repos/{REPO}/releases', {
    'tag_name': 'v0.3.0', 'name': 'v0.3.0 — Glass panels, fluid motion and measured Android performance',
    'body': (ROOT / 'doc/RELEASE_v0.3.0.md').read_text(encoding='utf-8'),
    'draft': False, 'prerelease': False, 'make_latest': 'true',
    }, method='POST')
print(f"Published GitHub release: {release['html_url']}")
upload_url = release['upload_url'].split('{')[0]
assets = [
    ROOT / 'screenshots/v0.3.0/morph-styles.gif',
    ROOT / 'screenshots/v0.3.0/modal-transitions.gif',
    ROOT / 'screenshots/v0.3.0/frame-times.png',
    ROOT / 'doc/performance/v0.3.0/2026-11-04-sm-s721b-frosted.json',
    ROOT / 'doc/performance/v0.3.0/2026-11-04-sm-s721b-solid.json',
    ROOT / 'build/v0.3.0-android-screenshots.zip',
]
for asset in assets:
    if not asset.is_file():
        raise SystemExit(f'Missing release asset: {asset.name}')
    if any(item['name'] == asset.name for item in release.get('assets', [])):
        print(f'Already uploaded {asset.name}')
        continue
    request(f'{upload_url}?name={urllib.parse.quote(asset.name)}', asset.read_bytes(),
        method='POST', content_type='application/octet-stream')
    print(f'Uploaded {asset.name}')
