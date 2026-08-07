import perl
import re
import os
import json
import urllib.request

spads = perl.ModeCommand

pluginVersion = '0.2'
requiredSpadsVersion = '0.12.29'


# modes.json describes every mode preset's full effective modoption set for a
# given game version. It is generated headless in BAR CI from the game's
# modules/*/modes/*.lua (modules/modes/widgets/export_modes.lua) and published per
# channel as a GitHub Release asset. This plugin self-fetches the asset for the
# version it is currently hosting, caches it locally, and falls back to a local
# file, so `!mode <category> <key>` can apply a mode's full option set.
# Schema: { schemaVersion, categories: { <cat>: { selector, presets: {
#   <mode>: { name, desc, allowRanked, modOptions: { <opt>: {value, locked} } } } } } }

_PLUGIN_DIR = os.path.dirname(os.path.abspath(__file__))

# Default publish location: the rolling `modes` prerelease in the BAR repo.
# We prefer a COMMIT-PINNED asset (modes-<shortsha>.json, published by BAR CI's
# export_modes.yml on manual dispatch for the exact commit) so the plugin never
# serves mode data that disagrees with the game it is hosting — the client/skirmish
# reads the matching modes/*.lua straight from that archive via VFS, and the hosted
# version string ends in that same git short SHA (e.g. "...test-24450-6c81e38" ->
# 6c81e38), so the SHA is what keeps the two in sync. We fall back to the rolling
# per-channel asset (modes-<channel>.json) when no pinned asset exists for the
# commit (the normal case for production hosts), which preserves the previous behaviour.
# Override the base for local testing with MODECOMMAND_RELEASE_BASE; pin to an explicit
# asset key with MODECOMMAND_MODES_VERSION (any <key> -> modes-<key>.json, handy
# for hosting an off-master build), or force the channel with
# MODECOMMAND_MODES_CHANNEL=test|stable, in the SPADS service Environment=.
_DEFAULT_RELEASE_BASE = 'https://github.com/beyond-all-reason/Beyond-All-Reason/releases/download/modes'
_CACHE_PATH = os.path.join(_PLUGIN_DIR, 'modes.cache.json')
_LOCAL_PATHS = [
    os.path.join(_PLUGIN_DIR, 'modes.json'),
    '/opt/spads/var/plugins/modes.json',
]
_FETCH_TIMEOUT = 5

# Loaded data, keyed by the version (modName) it was fetched for. _UNSET forces the
# first lookup to fetch; a `!rehost` to a different version refetches.
_UNSET = object()
_state = {'modName': _UNSET, 'data': {}}


def _conf():
    try:
        return spads.getSpadsConf()
    except Exception:
        return {}


def _current_mod_name():
    # The human-readable hosted game name, e.g. "Beyond All Reason test-24450-...".
    try:
        return _conf().get('modName')
    except Exception:
        return None


def _release_base():
    return (os.environ.get('MODECOMMAND_RELEASE_BASE') or _DEFAULT_RELEASE_BASE).rstrip('/')


def _channel(mod_name):
    # `auto` (default) infers the channel from the hosted version string: test
    # builds carry a "test" marker, everything else is treated as stable.
    override = (os.environ.get('MODECOMMAND_MODES_CHANNEL') or 'auto').lower()
    if override in ('test', 'stable'):
        return override
    return 'test' if (mod_name and 'test' in mod_name.lower()) else 'stable'


def _commit_sha(mod_name):
    # The asset key for a commit-pinned fetch. Prefer an explicit ops override (any
    # asset key -> modes-<key>.json); otherwise extract the trailing git short
    # SHA from the hosted version string (e.g. "Beyond All Reason test-24450-6c81e38"
    # -> "6c81e38"). Returns None when no SHA token is present (e.g. a clean stable
    # version), in which case _fetch falls back to the per-channel asset.
    override = os.environ.get('MODECOMMAND_MODES_VERSION')
    if override:
        return override.strip() or None
    if not mod_name:
        return None
    m = re.search(r'-([0-9a-f]{7,40})\s*$', mod_name)
    return m.group(1) if m else None


def _fetch(mod_name):
    # Parsed JSON for the hosted version, or None if it could not be fetched (caller
    # falls back). Tries the commit-pinned asset first, then the rolling per-channel
    # asset. On success the raw body is cached to disk.
    base = _release_base()
    urls = []
    sha = _commit_sha(mod_name)
    if sha:
        urls.append('%s/modes-%s.json' % (base, sha))
    urls.append('%s/modes-%s.json' % (base, _channel(mod_name)))

    for url in urls:
        try:
            with urllib.request.urlopen(url, timeout=_FETCH_TIMEOUT) as resp:
                body = resp.read()
            data = json.loads(body)
            try:
                with open(_CACHE_PATH, 'wb') as f:
                    f.write(body)
            except OSError:
                pass
            return data
        except Exception as e:
            spads.slog('mode: could not fetch %s: %s' % (url, e), 2)
    return None


def _load_local():
    # Last good fetch first, then any host-dropped file.
    for path in [_CACHE_PATH] + _LOCAL_PATHS:
        try:
            with open(path) as f:
                return json.load(f)
        except Exception:
            continue
    return None


def _modes():
    # Fetch once per hosted version (modName); a `!rehost` to a different version
    # refetches. On failure, serve the last cached copy, then any host-dropped file,
    # then {} — and still mark the version attempted so `!mode` never blocks on a
    # repeated network call. Reload the plugin to force a refresh.
    mod_name = _current_mod_name()
    if mod_name != _state['modName']:
        data = _fetch(mod_name)
        if data is None:
            data = _load_local()
        _state['data'] = data if data is not None else {}
        _state['modName'] = mod_name
    return _state['data']


def _as_dict(v):
    # The export's engine-side Json.encode emits an empty Lua table as `[]`, not
    # `{}` (e.g. a game with no mode categories). Coerce so lookups never hit a list.
    return v if isinstance(v, dict) else {}

globalPluginParams = {
    'commandsFile': ['notNull'],
    'helpFile': ['notNull'],
}
presetPluginParams = None


def getVersion(pluginObject):
    return pluginVersion

def getRequiredSpadsVersion(pluginName):
    return requiredSpadsVersion

def getParams(pluginName):
    return [globalPluginParams, presetPluginParams]


class ModeCommand:

    def __init__(self, context):
        spads.addSpadsCommandHandler({'mode': hSpadsMode})
        spads.slog("Plugin loaded (version %s)" % pluginVersion, 3)

    def onUnload(self, reason):
        spads.removeSpadsCommandHandler(['mode'])
        spads.slog("Plugin unloaded", 3)


def hSpadsMode(source, user, params, checkOnly):
    (source, user) = spads.fix_string(source, user)
    for i in range(len(params)):
        params[i] = spads.fix_string(params[i])

    if len(params) < 2:
        spads.invalidSyntax(user, 'mode')
        return 0

    category = params[0]
    mode_key = params[1]
    kv_params = params[2:]

    category_data = _as_dict(_modes().get('categories')).get(category)
    if not category_data:
        spads.answer('Unknown mode category "%s"' % category)
        return 0
    presets = _as_dict(category_data.get('presets'))
    preset = presets.get(mode_key)
    if not preset:
        valid = ', '.join(sorted(presets)) or '(none)'
        spads.answer('Unknown mode "%s" for category "%s" (valid: %s)' % (mode_key, category, valid))
        return 0

    mod_options = _as_dict(preset.get('modOptions'))

    settings = []
    for param in kv_params:
        m = re.match(r'^([^=]+)=(.*)$', param)
        if not m:
            spads.answer('Invalid parameter format "%s" (expected key=value)' % param)
            return 0
        settings.append((m.group(1).lower(), m.group(2)))

    locked_keys = set(
        key for key, spec in mod_options.items()
        if isinstance(spec, dict) and spec.get('locked')
    )

    # Reject unknown option keys outright rather than silently bSet-ing a typo
    # (e.g. "resource_sharing_tax" for "tax_resource_sharing_amount"), which would
    # drop the intended change and apply a bogus setting. Rejecting in the checkOnly
    # phase means the vote is never called for a malformed command.
    valid_keys = set(k.lower() for k in mod_options)
    for (key, _val) in settings:
        if key not in valid_keys:
            spads.answer('Unknown option "%s" for mode "%s %s" (valid: %s)'
                         % (key, category, mode_key, ', '.join(sorted(valid_keys)) or '(none)'))
            return 0

    if checkOnly:
        return 1

    # Record the chosen mode in the category's selector so clients reflect it.
    selector_key = category_data.get('selector') or ('%s_mode' % category)
    spads.updateSetting('bSet', selector_key, mode_key)

    # Expand the mode preset (full effective option set) so a bare
    # `!mode <category> <key>` fully applies it -- the Chobby client sends only the
    # user's deviations from the preset and relies on this expansion for the rest.
    # Explicit params override the preset, EXCEPT locked options: those are clamped
    # to the preset value, so a non-conforming client cannot change a locked option
    # even by naming it.
    effective = {}
    for (key, spec) in mod_options.items():
        if isinstance(spec, dict) and 'value' in spec:
            effective[key] = spec['value']
    for (key, val) in settings:
        if key not in locked_keys:
            effective[key] = val

    change_descs = ['%s=%s' % (selector_key, mode_key)]
    for key in sorted(effective):
        spads.updateSetting('bSet', str(key), str(effective[key]))
        change_descs.append('%s=%s' % (key, effective[key]))

    changes_str = ', '.join(change_descs)
    mode_label = '%s %s' % (category, mode_key)
    if changes_str:
        spads.sayBattleAndGame('Mode "%s" applied by %s (%s)' % (mode_label, user, changes_str))
    else:
        spads.sayBattleAndGame('Mode "%s" applied by %s' % (mode_label, user))
    if source == 'pv':
        if changes_str:
            spads.answer('Mode "%s" applied (%s)' % (mode_label, changes_str))
        else:
            spads.answer('Mode "%s" applied' % mode_label)

    return 1
