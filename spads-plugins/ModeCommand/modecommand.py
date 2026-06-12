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

    if len(params) < 2:
        spads.invalidSyntax(user, 'mode')
        return 0

    category = params[0]
    mode_key = params[1]
    kv_params = params[2:]

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
