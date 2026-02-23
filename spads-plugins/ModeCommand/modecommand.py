import perl
import re

spads = perl.ModeCommand

pluginVersion = '0.1'
requiredSpadsVersion = '0.12.29'

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

    if len(params) < 1:
        spads.invalidSyntax(user, 'mode')
        return 0

    mode_key = params[0]
    kv_params = params[1:]

    settings = []
    for param in kv_params:
        m = re.match(r'^([^=]+)=(.*)$', param)
        if not m:
            spads.answer('Invalid parameter format "%s" (expected key=value)' % param)
            return 0
        settings.append((m.group(1).lower(), m.group(2)))

    if checkOnly:
        return 1

    change_descs = []
    for (key, val) in settings:
        spads.updateSetting('bSet', key, val)
        change_descs.append('%s=%s' % (key, val))

    changes_str = ', '.join(change_descs)
    spads.sayBattleAndGame('Mode "%s" applied by %s (%s)' % (mode_key, user, changes_str))
    if source == 'pv':
        spads.answer('Mode "%s" applied (%s)' % (mode_key, changes_str))

    return 1
