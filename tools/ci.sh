#!/usr/bin/env bash
#
# Headless verification for hellorogue on Linux. The Bash counterpart to
# tools/smoke.ps1, and what .github/workflows/ci.yml runs on every push.
#
#   tools/ci.sh                # everything
#   GODOT=/path/to/godot tools/ci.sh
#
# Sprites/ and Music/ are untracked (see README), so a clone cannot load the
# level scenes at all. This stubs them first -- without that, five scenes fail
# to build and every integration test reports pending, which would make a green
# run mean almost nothing.
#
# Godot's exit codes are not usable here: it returns non-zero for harmless
# resource leaks at shutdown. Pass and fail are decided by scanning output, the
# same way smoke.ps1 does on Windows.

set -uo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.2.2-stable}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${GODOT_CACHE:-$PROJECT_DIR/.godot-bin}"

failures=0

# Output that is an artifact of running headless with placeholder assets, not a
# problem with the game.
NOISE='Mouse is not supported|ObjectDB instances leaked|Resources still in use'
NOISE="$NOISE"'|RID allocations of type|leaked at exit|at: (mouse_set_mode|cleanup|clear) '
NOISE="$NOISE"'|invalid UID:|resource_format_text|at: load \(scene/resources'
NOISE="$NOISE"'|Error parsing header packet|audio_stream_ogg_vorbis|libpulse|ALSA lib'
NOISE="$NOISE"'|Failed loading resource: res://(Sprites|Music)'

# Anything here means the stage failed, whatever Godot's exit code said.
FAIL='SCRIPT ERROR|Compile Error|Parse Error|SMOKE FAILURE|SMOKE TEST FAILED'
FAIL="$FAIL"'|Failed to load script|Nothing was run|Could not find script'
FAIL="$FAIL"'|Failing +[1-9]|[0-9]+ failing tests|Invalid call|nonexistent function'
FAIL="$FAIL"'|null instance|Invalid get index|Invalid set index'

godot_bin() {
	if [ -n "${GODOT:-}" ] && [ -x "${GODOT}" ]; then
		echo "$GODOT"; return
	fi
	local exe="$CACHE_DIR/Godot_v${GODOT_VERSION}_linux.x86_64"
	if [ ! -x "$exe" ]; then
		mkdir -p "$CACHE_DIR"
		local url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
		echo "  fetching Godot ${GODOT_VERSION}" >&2
		curl -sSL -o "$CACHE_DIR/godot.zip" "$url" || return 1
		unzip -o -q "$CACHE_DIR/godot.zip" -d "$CACHE_DIR" || return 1
		chmod +x "$exe"
	fi
	echo "$exe"
}

# stage <name> <required success marker> <command...>
#
# A stage passes only when it produced the marker it is supposed to produce.
# Checking for the absence of error text is not enough on its own: a stage that
# died before printing anything, or a binary that could not be executed, emits no
# error pattern either and would sail through as a pass. That is the failure mode
# that makes CI worth less than nothing, so every stage has to say the words.
stage() {
	local name="$1"
	local expect="$2"
	shift 2
	echo ""
	echo "== $name =="

	local raw
	raw="$(mktemp)"
	"$@" >"$raw" 2>&1
	local code=$?

	local out
	out="$(grep -Ev "$NOISE" "$raw" | grep -v '^[[:space:]]*$')"
	rm -f "$raw"
	echo "$out"

	local bad=0
	# 126/127 are "found but not executable" and "not found".
	if [ "$code" -ge 126 ]; then
		echo "   !! could not execute (exit $code)"
		bad=1
	fi
	if [ -z "$out" ]; then
		echo "   !! produced no output at all"
		bad=1
	fi
	if echo "$out" | grep -Eq "$FAIL"; then
		bad=1
	fi
	if [ -n "$expect" ] && ! echo "$out" | grep -Eq "$expect"; then
		echo "   !! missing expected result: $expect"
		bad=1
	fi

	if [ "$bad" -ne 0 ]; then
		echo "-> $name FAILED"
		failures=$((failures + 1))
	else
		echo "-> $name ok"
	fi
}

GODOT_EXE="$(godot_bin)" || { echo "could not obtain Godot"; exit 2; }
echo "godot:   $GODOT_EXE"
echo "project: $PROJECT_DIR"

echo ""
echo "== placeholder assets =="
python3 "$PROJECT_DIR/tools/stub_assets.py" || exit 2
# Two passes: the first writes the .import files, the second resolves the
# resources that reference them.
"$GODOT_EXE" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1
"$GODOT_EXE" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1
echo "-> imported"

stage "smoke test" "SMOKE TEST PASSED" \
	"$GODOT_EXE" --headless --path "$PROJECT_DIR" res://tools/smoke_test.tscn

stage "smoke test (deep)" "SMOKE TEST PASSED" \
	"$GODOT_EXE" --headless --path "$PROJECT_DIR" res://tools/smoke_test.tscn -- --deep

stage "unit + integration tests" "All tests passed" \
	"$GODOT_EXE" --headless --path "$PROJECT_DIR" \
		-s res://addons/gut/gut_cmdln.gd \
		-gdir=res://test -ginclude_subdirs -gexit -glog=1

# A level boot prints nothing of its own when it goes well, so the engine banner
# is the marker: it proves the binary ran rather than the stage being skipped.
for scene in main_level intermission_level intermission_level_2 intermission_level_1 final_level; do
	stage "boot $scene" "Godot Engine v" \
		"$GODOT_EXE" --headless --path "$PROJECT_DIR" "res://Levels/$scene.tscn" --quit-after 240
done

echo ""
if [ "$failures" -gt 0 ]; then
	echo "FAILED - $failures stage(s) had problems."
	exit 1
fi
echo "PASSED"
