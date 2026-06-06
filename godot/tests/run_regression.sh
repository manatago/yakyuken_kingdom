#!/usr/bin/env bash
# 回帰テスト一括ランナー
# tests/Run*.gd（過去に直したバグ1件ずつを守る単体スクリプト）を全部別プロセスで起動し、
# exit code を集計する。1本でも落ちたら全体を fail（exit 1）。
#
# 使い方:
#   bash godot/tests/run_regression.sh            # 全 Run*.gd
#   bash godot/tests/run_regression.sh Story      # 名前に "Story" を含むものだけ
#
# 各 Run*.gd は extends SceneTree で quit(0)=成功 / quit(1)=失敗 を返す前提。

set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_DIR="$ROOT/godot/tests"
FILTER="${1:-}"

if [ ! -x "$GODOT" ]; then
	echo "[REG] Godot が見つからない: $GODOT" >&2
	exit 2
fi

pass=0
fail=0
failed_list=()

# 安全網: 保存系テストは編集保存の対象ファイル（registry / 章ソース / バトル章）を書き換える。
# 各テストは自前で復元するが、登録漏れ・途中クラッシュで汚染が残ることがある（実際 registry と
# PrologueChapter で発生）。実行前にこれらを丸ごと退避し、終了時（失敗・中断含む）に必ず戻すことで、
# 「ランナーは走らせる前と同じ状態でツリーを残す」を保証する。退避は実行直前の状態（ユーザーの
# 未コミット編集を含む）なので、戻しても意図した編集は失われない。
SNAP_DIRS=(
	"godot/story/PortraitLayout.gd"
	"godot/story/chapters"
	"godot/battle/chapters"
	"godot/encounter"
)
SNAP_BAK="$(mktemp -d)"
for rel in "${SNAP_DIRS[@]}"; do
	src="$ROOT/$rel"
	if [ -e "$src" ]; then
		mkdir -p "$SNAP_BAK/$(dirname "$rel")"
		cp -R "$src" "$SNAP_BAK/$rel"
	fi
done
restore_snapshot() {
	for rel in "${SNAP_DIRS[@]}"; do
		if [ -e "$SNAP_BAK/$rel" ]; then
			rm -rf "$ROOT/$rel"
			cp -R "$SNAP_BAK/$rel" "$ROOT/$rel"
		fi
	done
	rm -rf "$SNAP_BAK"
}
trap restore_snapshot EXIT INT TERM

for f in "$TESTS_DIR"/Run*.gd; do
	name="$(basename "$f" .gd)"
	if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then
		continue
	fi
	# display必須テストの自動判定: root.push_input を使うものは実ディスプレイが要る
	# （headless では入力イベントが届かず、メニューが開かず偽失敗/ハングする）。
	# それらは --headless を付けずに実行する。
	headless="--headless"
	tag=""
	if grep -q 'push_input' "$f"; then
		headless=""
		tag=" (display)"
	fi
	printf '[REG] %-40s ... ' "$name$tag"
	# 失敗時のログを拾えるよう出力は変数に溜める
	out="$("$GODOT" --path "$ROOT/godot" $headless --script "res://tests/$name.gd" 2>&1)"
	code=$?
	if [ "$code" -eq 0 ]; then
		echo "PASS"
		pass=$((pass + 1))
	else
		echo "FAIL (exit=$code)"
		fail=$((fail + 1))
		failed_list+=("$name")
		# 失敗テストの FAIL 行だけ抜粋表示
		echo "$out" | grep -iE 'FAIL' | sed 's/^/[REG]     /'
	fi
done

echo "----------------------------------------"
echo "[REG] PASS=$pass  FAIL=$fail"
if [ "$fail" -gt 0 ]; then
	echo "[REG] 落ちたテスト:"
	for n in "${failed_list[@]}"; do
		echo "[REG]   - $n"
	done
	exit 1
fi
echo "[REG] 全て通過 ✅"
exit 0
