import yaml
import json
import urllib.request
import argparse
import shutil
import base64
import hashlib
import subprocess
import os.path 

def get_release_assets(repo, tag):
    with urllib.request.urlopen(f"https://api.github.com/repos/{repo}/releases/tags/{tag}") as f:
        release = json.load(f)
        assets = dict()
        for asset in release['assets']:
            assets[asset['name']] = asset
        return assets

def get_file_sha512(path):
    h = hashlib.sha512()
    with open(path, 'rb') as f:
        while (data := f.read(54*1024)):
            h.update(data)
    return base64.standard_b64encode(h.digest()).decode('utf-8')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('version', help='Tag of launcher release, e.g. v1.1832.0')
    parser.add_argument('--repo', default='beyond-all-reason/BYAR-Chobby', help='Github repo name')
    parser.add_argument('--signtool', help='Path to signtool binary', required=True)
    parser.add_argument('--cert_subject', help='/n argument to signtool', default='Open Source Developer')
    args = parser.parse_args()

    print("Fetching release assets")
    assets = get_release_assets(args.repo, args.version)
    
    print("Fetching latest.yml")
    with urllib.request.urlopen(assets['latest.yml']['browser_download_url']) as f:
        latest = yaml.safe_load(f)
        # I'm not sure how stable this format is
        assert latest.keys() == {'version', 'files', 'path', 'sha512', 'releaseDate'}
        assert len(latest['files']) == 1
        assert latest['files'][0].keys() == {'url', 'sha512', 'size'}

    print("Fetching installer")
    installer = latest['path']
    with open(installer, 'wb') as out:
        with urllib.request.urlopen(assets[installer]['browser_download_url']) as f:
            shutil.copyfileobj(f, out)

    assert get_file_sha512(installer) == latest['sha512']

    subprocess.run([args.signtool, 'sign', '/n', args.cert_subject, '/t',
                    'http://time.certum.pl/', '/fd', 'sha256', '/v', installer], check=True)

    signed_sha512 = get_file_sha512(installer)

    new_latest = {
        'version': latest['version'],
        'files': [{
            'url': installer,
            'sha512': signed_sha512,
            'size': os.path.getsize(installer)
        }],
        'path': installer,
        'sha512': signed_sha512,
        'releaseDate': latest['releaseDate']
    }
    with open('latest.yml', 'w') as f:
        yaml.dump(new_latest, f, default_flow_style=False, sort_keys=False)

if __name__ == '__main__':
    main()
