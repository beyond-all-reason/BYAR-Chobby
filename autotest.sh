#!/bin/bash

FAILING=

fail() {
  echo "$@"
  FAILING="y"
}

while read f; do
  diff /dev/null "$f" | tail -1 | grep -q '^\\ No newline at end of file' > /dev/null && fail "Warning: $f: No trailing newline";
  if grep -q $'[^ \t][ \t]\+$' "$f"; then
    # Everybody hates trailing whitespace after content
    fail "Warning: $f: Trailing whitespace after content";
  else
    # Most hate full line trailing whitespace; separated out to be disabled if desired
    # grep -q $'[ \t]$' "$f" && fail "Warning: $f: Full line trailing whitespace";
    :;
  fi
  file -i "$f" | cut -f2 -d: | grep -q -e 'us-ascii' -e 'utf-8' || fail "Warning: $f: Unusual file encoding";
  grep -q $'\r' "$f" && fail "Warning: $f: Carriage return characters detected";
done < <(git ls-files '*.lua' '*.tdf' '*.h' '*.glsl' '*.fs' '*.json' '*.txt' '*.css') 1>&2
[ "x${FAILING}" == "x" ]
