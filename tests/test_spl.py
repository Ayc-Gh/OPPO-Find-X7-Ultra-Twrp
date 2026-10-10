#!/usr/bin/env python3
"""Host-only failure tests. Never execute recovery scripts against a phone."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'recovery/root/vendor/bin/override-spl.sh'

MOCKS = r'''
function [ {
    if [[ "$1" == "!" && "$2" == "-b" ]]; then
        [[ "$CASE" == missing_block ]]
        return
    fi
    builtin [ "$@"
}
getprop() {
    case "$1" in
        ro.twrp.fastbootd) [[ "$CASE" == fastbootd ]] && echo 1 || echo 0 ;;
        ro.recovery.phy110.supported) [[ "$CASE" == wrong_device ]] && echo 0 || echo 1 ;;
        ro.boot.slot_suffix) [[ "$CASE" == invalid_slot ]] && echo _c || echo "$SLOT" ;;
    esac
}
setprop() { printf 'setprop %s %s\n' "$1" "$2" >> "$TRACE"; }
resetprop() {
    printf 'resetprop %s %s\n' "$1" "$2" >> "$TRACE"
    [[ "$CASE" != reset_fail ]]
}
mount() {
    printf 'mount %s\n' "$*" >> "$TRACE"
    local dest="${@: -1}" dev="${@: -2:1}"
    [[ "$CASE" == mount_fail ]] && return 1
    [[ "$CASE" == system_mount_fail && "$dev" == *system* ]] && return 1
    [[ "$CASE" == ext4 && "$*" == *'-t erofs'* ]] && return 1
    if [[ "$dev" == *vendor* ]]; then
        printf 'ro.vendor.build.security_patch=2026-08-01\n' > "$dest/build.prop"
    elif [[ "$CASE" == missing_spl ]]; then
        printf 'unrelated=value\n' > "$dest/build.prop"
    elif [[ "$CASE" == malformed_spl ]]; then
        printf 'ro.build.version.security_patch=2099-99-99\n' > "$dest/build.prop"
    else
        mkdir -p "$dest/system"
        printf 'ro.build.version.security_patch=2026-08-01\n' > "$dest/system/build.prop"
    fi
}
umount() {
    printf 'umount %s\n' "$1" >> "$TRACE"
    [[ "$CASE" == unmount_fail ]] && return 1
    # Remove fixture files as a simulated unmount; no real mount is used.
    rm -f "$1/build.prop" "$1/system/build.prop"
    rmdir "$1/system" 2>/dev/null || true
}
'''


class SplTests(unittest.TestCase):
    def run_case(self, case, slot='_b'):
        with tempfile.TemporaryDirectory(prefix='phy110-test-') as directory:
            base = Path(directory)
            trace = base / 'trace'
            trace.touch()
            body = SCRIPT.read_text().replace(
                'TEMP_ROOT="/tmp/phy110-spl.$$"', f'TEMP_ROOT="{base}/mounts"'
            ).replace('/tmp/recovery.log', str(base / 'recovery.log'))
            test = base / 'scenario.sh'
            test.write_text(MOCKS + '\n' + body)
            env = dict(os.environ, CASE=case, SLOT=slot, TRACE=str(trace))
            result = subprocess.run(['bash', str(test)], env=env,
                                    capture_output=True, text=True, timeout=10)
            return result.returncode, trace.read_text(), (base / 'mounts').exists()

    def test_both_slots_and_filesystem_fallback(self):
        for case in ('success', 'ext4'):
            for slot in ('_a', '_b'):
                with self.subTest(case=case, slot=slot):
                    code, trace, remains = self.run_case(case, slot)
                    self.assertEqual(code, 0, trace)
                    self.assertIn('setprop crypto.ready 1', trace)
                    self.assertIn('vendor' + slot, trace)
                    self.assertIn('system' + slot, trace)
                    self.assertFalse(remains)
                    lines = trace.splitlines()
                    last_unmount = max(i for i, line in enumerate(lines) if line.startswith('umount '))
                    first_reset = min(i for i, line in enumerate(lines) if line.startswith('resetprop '))
                    self.assertLess(last_unmount, first_reset)
                    for line in lines:
                        if line.startswith('mount '):
                            self.assertIn('ro,nodev,nosuid,noexec', line.replace('ro,noload', 'ro'))
                            if '-t ext4' in line:
                                self.assertIn('ro,noload', line)

    def test_errors_never_publish_readiness(self):
        for case in ('wrong_device', 'invalid_slot', 'missing_block', 'mount_fail',
                     'system_mount_fail', 'missing_spl', 'malformed_spl',
                     'unmount_fail', 'reset_fail'):
            with self.subTest(case=case):
                code, trace, remains = self.run_case(case)
                self.assertNotEqual(code, 0, trace)
                self.assertNotIn('setprop crypto.ready 1', trace)
                if case != 'reset_fail':
                    self.assertNotIn('resetprop ', trace)
                if case == 'unmount_fail':
                    self.assertTrue(remains, 'Mounted contents must never be recursively removed')
                else:
                    self.assertFalse(remains)

    def test_fastbootd_skips_everything(self):
        code, trace, remains = self.run_case('fastbootd')
        self.assertEqual(code, 0)
        self.assertEqual(trace, '')
        self.assertFalse(remains)


if __name__ == '__main__':
    unittest.main(verbosity=2)
