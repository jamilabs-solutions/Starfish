#!/bin/bash

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Create empty dir for big file searches
empty_root="$TMPDIR/empty"
mkdir -p "$empty_root"

# Case 1: disk free 50 GB (OK), RAM 4GB avail of 8GB, swap 8GB all free
state_dir_1="$TMPDIR/state1"
mkdir -p "$state_dir_1"
df_file_1="$TMPDIR/df1"
meminfo_1="$TMPDIR/meminfo1"
echo "100000000000 50000000000" > "$df_file_1"
cat > "$meminfo_1" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_1" JL_GUARD_MEMINFO="$meminfo_1" \
  JL_GUARD_STATE_DIR="$state_dir_1" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD OK$"; then
  echo "case 1 ok"
else
  echo "FAIL case 1: $(echo "$result" | head -1)"
  exit 1
fi

# Case 2: disk free 9 GB (WARN)
state_dir_2="$TMPDIR/state2"
mkdir -p "$state_dir_2"
df_file_2="$TMPDIR/df2"
meminfo_2="$TMPDIR/meminfo2"
echo "100000000000 9000000000" > "$df_file_2"
cat > "$meminfo_2" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_2" JL_GUARD_MEMINFO="$meminfo_2" \
  JL_GUARD_STATE_DIR="$state_dir_2" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD WARN$" && \
   echo "$result" | grep -q "91% used"; then
  echo "case 2 ok"
else
  echo "FAIL case 2: $(echo "$result" | head -2)"
  exit 1
fi

# Case 3: disk free 4 GB (CRIT)
state_dir_3="$TMPDIR/state3"
mkdir -p "$state_dir_3"
df_file_3="$TMPDIR/df3"
meminfo_3="$TMPDIR/meminfo3"
echo "100000000000 4000000000" > "$df_file_3"
cat > "$meminfo_3" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_3" JL_GUARD_MEMINFO="$meminfo_3" \
  JL_GUARD_STATE_DIR="$state_dir_3" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD CRIT$"; then
  echo "case 3 ok"
else
  echo "FAIL case 3: $(echo "$result" | head -1)"
  exit 1
fi

# Case 4: RAM available 0.8 GB (WARN)
state_dir_4="$TMPDIR/state4"
mkdir -p "$state_dir_4"
df_file_4="$TMPDIR/df4"
meminfo_4="$TMPDIR/meminfo4"
echo "100000000000 50000000000" > "$df_file_4"
cat > "$meminfo_4" << EOF
MemTotal:        7812500 kB
MemAvailable:    838860 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_4" JL_GUARD_MEMINFO="$meminfo_4" \
  JL_GUARD_STATE_DIR="$state_dir_4" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD WARN$"; then
  echo "case 4 ok"
else
  echo "FAIL case 4: $(echo "$result" | head -1)"
  exit 1
fi

# Case 5: RAM available 0.3 GB (CRIT)
state_dir_5="$TMPDIR/state5"
mkdir -p "$state_dir_5"
df_file_5="$TMPDIR/df5"
meminfo_5="$TMPDIR/meminfo5"
echo "100000000000 50000000000" > "$df_file_5"
cat > "$meminfo_5" << EOF
MemTotal:        7812500 kB
MemAvailable:    314572 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_5" JL_GUARD_MEMINFO="$meminfo_5" \
  JL_GUARD_STATE_DIR="$state_dir_5" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD CRIT$"; then
  echo "case 5 ok"
else
  echo "FAIL case 5: $(echo "$result" | head -1)"
  exit 1
fi

# Case 6: swap used 6 GB of 8 (WARN)
state_dir_6="$TMPDIR/state6"
mkdir -p "$state_dir_6"
df_file_6="$TMPDIR/df6"
meminfo_6="$TMPDIR/meminfo6"
echo "100000000000 50000000000" > "$df_file_6"
cat > "$meminfo_6" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        1953125 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_6" JL_GUARD_MEMINFO="$meminfo_6" \
  JL_GUARD_STATE_DIR="$state_dir_6" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD WARN$" && \
   echo "$result" | grep -q "swap 6.0 of 8.0 GB used"; then
  echo "case 6 ok"
else
  echo "FAIL case 6: $(echo "$result" | head -3)"
  exit 1
fi

# Case 7: drop 10 GB in 60 min (CRIT)
state_dir_7="$TMPDIR/state7"
mkdir -p "$state_dir_7"
df_file_7="$TMPDIR/df7"
meminfo_7="$TMPDIR/meminfo7"
echo "100000000000 50000000000" > "$df_file_7"
cat > "$meminfo_7" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
now=$(($(date +%s)))
old_epoch=$((now - 3600))
state_json_7="$state_dir_7/state.json"
echo "{\"free\": [[$old_epoch, 60000000000]], \"last\": {\"level\": \"OK\", \"epoch\": 0}}" > "$state_json_7"
result=$(JL_GUARD_DF_FILE="$df_file_7" JL_GUARD_MEMINFO="$meminfo_7" \
  JL_GUARD_STATE_DIR="$state_dir_7" JL_GUARD_NO_TOP=1 JL_GUARD_NOW="$now" JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD CRIT$" && \
   echo "$result" | grep -q "drop: 10.0 GB"; then
  echo "case 7 ok"
else
  echo "FAIL case 7: $(echo "$result" | head -3)"
  exit 1
fi

# Case 8: drop 4 GB in 60 min (WARN)
state_dir_8="$TMPDIR/state8"
mkdir -p "$state_dir_8"
df_file_8="$TMPDIR/df8"
meminfo_8="$TMPDIR/meminfo8"
echo "100000000000 50000000000" > "$df_file_8"
cat > "$meminfo_8" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
now=$(($(date +%s)))
old_epoch=$((now - 3600))
state_json_8="$state_dir_8/state.json"
echo "{\"free\": [[$old_epoch, 54000000000]], \"last\": {\"level\": \"OK\", \"epoch\": 0}}" > "$state_json_8"
result=$(JL_GUARD_DF_FILE="$df_file_8" JL_GUARD_MEMINFO="$meminfo_8" \
  JL_GUARD_STATE_DIR="$state_dir_8" JL_GUARD_NO_TOP=1 JL_GUARD_NOW="$now" JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD WARN$" && \
   echo "$result" | grep -q "drop:"; then
  echo "case 8 ok"
else
  echo "FAIL case 8: $(echo "$result" | head -3)"
  exit 1
fi

# Case 9: 3 GB big file (WARN)
state_dir_9="$TMPDIR/state9"
mkdir -p "$state_dir_9"
big_root_9="$TMPDIR/big_root_9"
mkdir -p "$big_root_9"
big_file_9="$big_root_9/largefile"
truncate -s 3G "$big_file_9"
df_file_9="$TMPDIR/df9"
meminfo_9="$TMPDIR/meminfo9"
echo "100000000000 50000000000" > "$df_file_9"
cat > "$meminfo_9" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
result=$(JL_GUARD_DF_FILE="$df_file_9" JL_GUARD_MEMINFO="$meminfo_9" \
  JL_GUARD_STATE_DIR="$state_dir_9" JL_GUARD_NO_TOP=1 \
  JL_GUARD_BIG_ROOTS="$big_root_9" \
  python3 -I tools/jl_guard.py 2>&1)
if echo "$result" | head -1 | grep -q "^GUARD WARN$" && \
   echo "$result" | grep -q "big file:"; then
  echo "case 9 ok"
else
  echo "FAIL case 9: $(echo "$result" | head -4)"
  exit 1
fi

# Case 10: notify WARN, 10 min later still 1 line, 61 min later 2 lines
state_dir_10="$TMPDIR/state10"
mkdir -p "$state_dir_10"
df_file_10="$TMPDIR/df10"
meminfo_10="$TMPDIR/meminfo10"
notify_log_10="$TMPDIR/notify10.log"
touch "$notify_log_10"
notify_script_10="$TMPDIR/notify10.sh"
{
  echo "#!/bin/bash"
  echo "echo \"called\" >> '$notify_log_10'"
} > "$notify_script_10"
chmod +x "$notify_script_10"
echo "100000000000 9000000000" > "$df_file_10"
cat > "$meminfo_10" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
now=$(($(date +%s)))
JL_GUARD_DF_FILE="$df_file_10" JL_GUARD_MEMINFO="$meminfo_10" \
  JL_GUARD_STATE_DIR="$state_dir_10" JL_GUARD_NOW="$now" \
  JL_GUARD_NOTIFY_CMD="$notify_script_10" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py --notify > /dev/null 2>&1 || true
lines_1=$(wc -l < "$notify_log_10" 2>/dev/null || echo 0)
now=$((now + 600))
JL_GUARD_DF_FILE="$df_file_10" JL_GUARD_MEMINFO="$meminfo_10" \
  JL_GUARD_STATE_DIR="$state_dir_10" JL_GUARD_NOW="$now" \
  JL_GUARD_NOTIFY_CMD="$notify_script_10" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py --notify > /dev/null 2>&1 || true
lines_2=$(wc -l < "$notify_log_10" 2>/dev/null || echo 0)
now=$((now + 3600))
JL_GUARD_DF_FILE="$df_file_10" JL_GUARD_MEMINFO="$meminfo_10" \
  JL_GUARD_STATE_DIR="$state_dir_10" JL_GUARD_NOW="$now" \
  JL_GUARD_NOTIFY_CMD="$notify_script_10" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py --notify > /dev/null 2>&1 || true
lines_3=$(wc -l < "$notify_log_10" 2>/dev/null || echo 0)
if [ "$lines_1" -eq 1 ] && [ "$lines_2" -eq 1 ] && [ "$lines_3" -eq 2 ]; then
  echo "case 10 ok"
else
  echo "FAIL case 10: got $lines_1, $lines_2, $lines_3 (expected 1, 1, 2)"
  exit 1
fi

# Case 11: WARN then CRIT 5 min later
state_dir_11="$TMPDIR/state11"
mkdir -p "$state_dir_11"
df_file_11="$TMPDIR/df11"
meminfo_11="$TMPDIR/meminfo11"
notify_log_11="$TMPDIR/notify11.log"
touch "$notify_log_11"
notify_script_11="$TMPDIR/notify11.sh"
{
  echo "#!/bin/bash"
  echo "echo \"\$1\" >> '$notify_log_11'"
} > "$notify_script_11"
chmod +x "$notify_script_11"
echo "100000000000 9000000000" > "$df_file_11"
cat > "$meminfo_11" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
now=$(($(date +%s)))
JL_GUARD_DF_FILE="$df_file_11" JL_GUARD_MEMINFO="$meminfo_11" \
  JL_GUARD_STATE_DIR="$state_dir_11" JL_GUARD_NOW="$now" \
  JL_GUARD_NOTIFY_CMD="$notify_script_11" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py --notify > /dev/null 2>&1 || true
echo "100000000000 4000000000" > "$df_file_11"
now=$((now + 300))
JL_GUARD_DF_FILE="$df_file_11" JL_GUARD_MEMINFO="$meminfo_11" \
  JL_GUARD_STATE_DIR="$state_dir_11" JL_GUARD_NOW="$now" \
  JL_GUARD_NOTIFY_CMD="$notify_script_11" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  python3 -I tools/jl_guard.py --notify > /dev/null 2>&1 || true
if grep -q "\-u critical" "$notify_log_11" 2>/dev/null; then
  echo "case 11 ok"
else
  echo "FAIL case 11: missing -u critical in notify log"
  cat "$notify_log_11" 2>/dev/null || echo "(no log)"
  exit 1
fi

# Case 12: OK with --notify, no notify call, last.txt exists
state_dir_12="$TMPDIR/state12"
mkdir -p "$state_dir_12"
df_file_12="$TMPDIR/df12"
meminfo_12="$TMPDIR/meminfo12"
notify_log_12="$TMPDIR/notify12.log"
touch "$notify_log_12"
notify_script_12="$TMPDIR/notify12.sh"
{
  echo "#!/bin/bash"
  echo "echo \"called\" >> '$notify_log_12'"
} > "$notify_script_12"
chmod +x "$notify_script_12"
echo "100000000000 50000000000" > "$df_file_12"
cat > "$meminfo_12" << EOF
MemTotal:        7812500 kB
MemAvailable:    3906250 kB
SwapTotal:       7812500 kB
SwapFree:        6835938 kB
EOF
JL_GUARD_DF_FILE="$df_file_12" JL_GUARD_MEMINFO="$meminfo_12" \
  JL_GUARD_STATE_DIR="$state_dir_12" JL_GUARD_NO_TOP=1 JL_GUARD_BIG_ROOTS="$empty_root" \
  JL_GUARD_NOTIFY_CMD="$notify_script_12" \
  python3 -I tools/jl_guard.py --notify > /dev/null 2>&1 || true
if [ -f "$state_dir_12/last.txt" ] && [ ! -s "$notify_log_12" ]; then
  echo "case 12 ok"
else
  echo "FAIL case 12: last.txt exists=$([ -f "$state_dir_12/last.txt" ] && echo yes || echo no), notify_log empty=$([ ! -s "$notify_log_12" ] && echo yes || echo no)"
  exit 1
fi

echo "ALL 12 CASES PASSED"
