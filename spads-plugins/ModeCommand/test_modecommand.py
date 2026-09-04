"""Unit tests for the parts of the ModeCommand plugin that do not need SPADS.

Run from this directory: python3 -m unittest test_modecommand
"""
import json
import os
import sys
import tempfile
import threading
import time
import types
import unittest

# The plugin imports SPADS's perl bridge at module scope; stand one in.
_calls = {'slog': [], 'answer': [], 'bSet': [], 'say': []}


class _FakeSpads:
    def getSpadsConf(self):
        return {'modName': 'Beyond All Reason test-24450-abc1234'}

    def slog(self, message, level):
        _calls['slog'].append((message, level))

    def addSpadsCommandHandler(self, handlers):
        pass

    def removeSpadsCommandHandler(self, names):
        pass

    def fix_string(self, *args):
        return args if len(args) > 1 else args[0]

    def invalidSyntax(self, user, command):
        _calls['answer'].append('invalid syntax')

    def answer(self, message):
        _calls['answer'].append(message)

    def updateSetting(self, kind, key, value):
        _calls['bSet'].append((key, value))

    def sayBattleAndGame(self, message):
        _calls['say'].append(message)


fake_perl = types.ModuleType('perl')
fake_perl.ModeCommand = _FakeSpads()
sys.modules['perl'] = fake_perl
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import modecommand  # noqa: E402


def _reset(data, pending=None):
    modecommand._state.update({'modName': 'Beyond All Reason test-24450-abc1234', 'data': data, 'pending': pending})
    for v in _calls.values():
        v.clear()


MODES = {
    'schemaVersion': 1,
    'categories': {
        'transfer': {
            'selector': 'transfer_mode',
            'presets': {
                'enabled': {
                    'modOptions': {
                        'ResourceMult': {'value': '1', 'locked': True},
                        'tax_rate': {'value': '0.1', 'locked': False},
                    }
                }
            },
        }
    },
}


class ModesShape(unittest.TestCase):
    def test_a_list_at_the_top_level_reads_as_no_modes(self):
        modecommand._state.update({'modName': None, 'data': {}, 'pending': None})
        modecommand._load_local = lambda: ['not', 'an', 'object']
        modecommand._start_fetch = lambda mod_name: None
        self.assertEqual({}, modecommand._modes())
        self.assertEqual({}, modecommand._as_dict(modecommand._modes().get('categories')))


class LockedKeys(unittest.TestCase):
    def test_a_lock_holds_whatever_the_casing(self):
        _reset(MODES)
        modecommand.hSpadsMode('pv', 'alice', ['transfer', 'enabled', 'resourcemult=9'], False)
        self.assertIn(('resourcemult', '1'), _calls['bSet'])
        self.assertNotIn(('resourcemult', '9'), _calls['bSet'])

    def test_an_unlocked_option_takes_the_override(self):
        _reset(MODES)
        modecommand.hSpadsMode('pv', 'alice', ['transfer', 'enabled', 'tax_rate=0.5'], False)
        self.assertIn(('tax_rate', '0.5'), _calls['bSet'])


class BackgroundFetch(unittest.TestCase):
    def test_the_first_lookup_never_waits_on_the_network(self):
        modecommand._state.update({'modName': None, 'data': {}, 'pending': None})
        gate = threading.Event()

        def slow_fetch(mod_name):
            gate.wait(5)
            return MODES, [('fetched', 3)]

        modecommand._fetch = slow_fetch
        modecommand._load_local = lambda: {'schemaVersion': 1, 'categories': {}}
        started = time.time()
        first = modecommand._modes()
        self.assertLess(time.time() - started, 1.0)
        self.assertEqual({}, first['categories'])
        gate.set()
        deadline = time.time() + 5
        while modecommand._state['pending'] and time.time() < deadline:
            time.sleep(0.01)
            modecommand._modes()
        self.assertEqual(MODES['categories'], modecommand._modes()['categories'])


if __name__ == '__main__':
    unittest.main()
