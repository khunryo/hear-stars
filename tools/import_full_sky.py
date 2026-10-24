"""Reproducible Yale BSC5 + d3-celestial line conversion, no runtime network.

--fetch pins public upstream commits and caches gzip snapshots and notices.
Normal invocation rebuilds using only those checked-in snapshots.
"""
import argparse
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
from datetime import datetime, timezone
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'tools/sky-sources'
OUTPUT = ROOT / 'Sources/HearStarsCore/Resources'


def unit(point):
    ra, dec = map(math.radians, point)
    return math.cos(dec) * math.cos(ra), math.cos(dec) * math.sin(ra), math.sin(dec)


def coordinate(row):
    try:
        hours, minutes, seconds = (float(row[k]) for k in ('RAh', 'RAm', 'RAs'))
        degrees, arcminutes, arcseconds = (float(row[k]) for k in ('DEd', 'DEm', 'DEs'))
        if not (0 <= hours < 24 and 0 <= minutes < 60 and 0 <= seconds < 60
                and 0 <= degrees <= 90 and 0 <= arcminutes < 60 and 0 <= arcseconds < 60
                and row['DE-'] in ('+', '-')):
            return None
        ra = 15 * (hours + minutes / 60 + seconds / 3600)
        dec = (degrees + arcminutes / 60 + arcseconds / 3600) * (-1 if row['DE-'] == '-' else 1)
        return (ra, dec) if abs(dec) <= 90 else None
    except (KeyError, TypeError, ValueError):
        return None


def nearest_star(point, stars, max_degrees=0.02):
    direction = unit(point)
    best = None
    best_dot = math.cos(math.radians(max_degrees))
    for star in stars:
        vector = star.get('_unit') or unit((star['ra'], star['dec']))
        dot = sum(a * b for a, b in zip(direction, vector))
        if dot > best_dot:
            best, best_dot = star['id'], dot
    return best


def merge_constellation_id(value):
    return 'ser' if value.lower() in ('ser1', 'ser2', 'ser') else value.lower()


def fetch_sources():
    def read(url):
        with urlopen(Request(url, headers={'User-Agent': 'HearStars-catalog-import'}), timeout=60) as response:
            return response.read()
    SOURCES.mkdir(parents=True, exist_ok=True)
    manifest = {'retrieved': datetime.now(timezone.utc).isoformat(), 'files': {}}
    specs = {
        'brettonw/YaleBrightStarCatalog': ['bsc5-orig.json', 'LICENSE', 'README.md'],
        'ofrohn/d3-celestial': ['data/constellations.lines.json', 'data/constellations.json', 'LICENSE', 'readme.md'],
    }
    for repo, files in specs.items():
        commit = json.loads(read(f'https://api.github.com/repos/{repo}/commits/master'))['sha']
        for name in files:
            url = f'https://raw.githubusercontent.com/{repo}/{commit}/{name}'
            data = read(url)
            filename = repo.split('/')[1] + '-' + name.replace('/', '-') + '.gz'
            (SOURCES / filename).write_bytes(gzip.compress(data, mtime=0))
            manifest['files'][filename] = {'url': url, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
    (SOURCES / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')


def snapshot(filename):
    manifest = json.loads((SOURCES / 'manifest.json').read_text(encoding='utf-8'))
    data = gzip.decompress((SOURCES / filename).read_bytes())
    assert hashlib.sha256(data).hexdigest() == manifest['files'][filename]['sha256'], filename
    return data


def build():
    rows = json.loads(snapshot('YaleBrightStarCatalog-bsc5-orig.json.gz'))
    stars = []
    for row in rows:
        position = coordinate(row)
        if position is None or 'Vmag' not in row:
            continue
        magnitude = float(row['Vmag'])
        if not math.isfinite(magnitude):
            continue
        stars.append({'id': 'hr' + row['HR'], 'ra': round(position[0], 8), 'dec': round(position[1], 8),
                      'mag': magnitude, 'designation': row.get('Name', '').strip() or 'HR ' + row['HR'],
                      '_unit': unit(position)})
    # Preserve every previously shipped identity and its more precise astrometry.
    original = (ROOT / 'Sources/HearStarsCore/StarCatalog.swift').read_text(encoding='utf-8')
    small = (ROOT / 'Sources/HearStarsCore/LegacySkyCatalog.swift').read_text(encoding='utf-8') if (ROOT / 'Sources/HearStarsCore/LegacySkyCatalog.swift').exists() else (ROOT / 'Sources/HearStarsCore/SkyCatalog.swift').read_text(encoding='utf-8')
    originals = [(m[0], float(m[1].replace('_', '')), float(m[2].replace('_', '')))
                 for m in re.findall(r'id: "([^"]+)".*?rightAscensionDegrees: ([\d_.-]+), declinationDegrees: ([\d_.-]+)', original, re.S)]
    originals += [(m[0], float(m[1]), float(m[2])) for m in re.findall(r'star\("([^"]+)", "[^"]+", ([\d.-]+), ([\d.-]+),', small)]
    assert len(originals) == 31
    aliases = {}
    for identity, ra, dec in originals:
        match = nearest_star((ra, dec), stars, max_degrees=0.03)
        assert match is not None and match not in aliases, ('Original identity match', identity, match)
        aliases[match] = identity
    figures = json.loads(snapshot('d3-celestial-data-constellations.lines.json.gz'))['features']
    names = {merge_constellation_id(f['id']): f['properties'] for f in
             json.loads(snapshot('d3-celestial-data-constellations.json.gz'))['features']}
    groups = {}
    endpoints = set()
    matches = {}
    unmatched = []
    for figure in figures:
        group_id = merge_constellation_id(figure['id'])
        group = groups.setdefault(group_id, {'id': group_id, 'nameJA': names[group_id]['ja'],
                                             'nameEN': names[group_id]['name'], 'links': []})
        if group_id == 'ser':
            group['nameJA'], group['nameEN'] = 'へび座', 'Serpens'
        for line in figure['geometry']['coordinates']:
            ids = []
            for coordinate_pair in line:
                key = tuple(coordinate_pair)
                if key not in matches:
                    matches[key] = nearest_star(key, stars, max_degrees=0.03)
                match = matches[key]
                if match is None:
                    unmatched.append((group_id, key))
                else:
                    endpoints.add(match)
                    ids.append(aliases.get(match, match))
            if len(ids) == len(line):
                group['links'].extend([[a, b] for a, b in zip(ids, ids[1:]) if a != b])
    assert not unmatched, f'Unmatched constellation endpoints: {unmatched[:12]} ({len(unmatched)} total)'
    assert len(groups) == 88
    keep = []
    for star in stars:
        old_id = star['id']
        if star['mag'] > 6.5 and old_id not in endpoints and old_id not in aliases:
            continue
        keep.append({k: (aliases.get(old_id, old_id) if k == 'id' else v) for k, v in star.items() if not k.startswith('_')})
    for group in groups.values():
        group['links'] = [list(pair) for pair in dict.fromkeys(tuple(sorted(pair)) for pair in group['links'])]
        group['starIDs'] = sorted({s for pair in group['links'] for s in pair})
    OUTPUT.mkdir(parents=True, exist_ok=True)
    payload = {'schema': 1, 'stars': keep, 'constellations': sorted(groups.values(), key=lambda g: g['id'])}
    (OUTPUT / 'full-sky.json').write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    notice = ('Yale Bright Star Catalogue, Hoffleit & Warren (1991), original J2000 fields.\n'
              'JSON export by Bretton Wade, reduced/converted for Hear the Stars.\n'
              'Constellation line topology and names adapted from d3-celestial by Olaf Frohn,\n'
              'based on IAU constellation charts with author modifications and translated names.\n'
              'Coordinates in this derived file come from Yale, not the Hipparcos star catalog.\n'
              'Original31 identities retain their existing IAU/Wikidata data and notices.\n'
              'New star proper motion is approximated as zero. Lines are guides, not IAU boundaries.\n\n')
    notice += snapshot('YaleBrightStarCatalog-LICENSE.gz').decode() + '\n\n' + snapshot('d3-celestial-LICENSE.gz').decode()
    notice += '\n\nIAU public materials: https://iauarchive.eso.org/copyright/ (CC BY 4.0).\nNot endorsed by IAU.\n'
    (OUTPUT / 'SkyDataNotices.txt').write_text(notice, encoding='utf-8')
    print(f'{len(keep)} stars; {len(groups)} constellations; {sum(len(g["links"]) for g in groups.values())} edges; '
          f'{len(aliases)} retained identities; no unmatched endpoints')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--fetch', action='store_true')
    args = parser.parse_args()
    if args.fetch:
        fetch_sources()
    build()
