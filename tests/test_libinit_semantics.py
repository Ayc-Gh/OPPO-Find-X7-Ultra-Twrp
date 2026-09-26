#!/usr/bin/env python3
from pathlib import Path
import re
src = (Path(__file__).parents[1] / 'libinit/libinit_phy110.cpp').read_text()
assert 'kPhy110Project = 22111' in src
assert 'std::stoi' not in src
assert 'ParseInt(' in src
assert src.count('"ro.product.odm.model"') == 1
assert '"OP565FL1"' in src and '"PHY110"' in src
guard = re.search(r'if \(project != 0 && project != kPhy110Project\).*?return;', src, re.S)
assert guard, 'missing unsupported-device guard'
print('PASS: libinit semantic regression')
