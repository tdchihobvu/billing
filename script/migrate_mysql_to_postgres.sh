#!/usr/bin/env bash
#
# Migrate a MySQL dump (phpMyAdmin .sql, or a .zip holding one) into a NEW
# PostgreSQL database, then prove every row arrived unchanged.
#
#   PGPASSWORD=... script/migrate_mysql_to_postgres.sh <dump.zip|dump.sql> <new_database>
#
# Run from the Rails root, in Git Bash, with the project's Ruby and Node on PATH.
# Optional settings: PGHOST (localhost), PGPORT (5434), PGUSER (postgres),
#                    MYSQL_BIN (WAMP MySQL 8.0.31), TEMP_MYSQL_PORT (3307).
#
# Safety:
#   - Refuses to touch a database that already exists.
#   - Loads everything in one transaction, so a failure leaves nothing behind.
#   - Reads the dump through a temporary, localhost-only MySQL server.
#   - Deletes its working files on exit, because they contain customer data.
#
# Exits 0 only if every row in every table matches.

set -euo pipefail

DUMP="${1:?usage: $0 <dump.zip|dump.sql> <new_database>}"
TARGET="${2:?usage: $0 <dump.zip|dump.sql> <new_database>}"
: "${PGPASSWORD:?set PGPASSWORD}"
export PGPASSWORD PGCLIENTENCODING=UTF8

PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5434}"
PGUSER="${PGUSER:-postgres}"
MYSQL_BIN="${MYSQL_BIN:-/c/wamp64/bin/mysql/mysql8.0.31/bin}"
TEMP_MYSQL_PORT="${TEMP_MYSQL_PORT:-3307}"
SKIP_TABLES='^(schema_migrations|ar_internal_metadata)$'

WORK="$(mktemp -d "${TMPDIR:-/tmp}/mysql_to_pg.XXXXXX")"
WORK_WIN="$(cygpath -m "$WORK")"
MYSQL_STARTED=""

mysql_cmd() { "$MYSQL_BIN/mysql.exe" --no-defaults -h127.0.0.1 -P"$TEMP_MYSQL_PORT" -uroot "$@"; }
psql_target() { psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -w -d "$TARGET" "$@"; }
psql_admin() { psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -w -d postgres -At "$@"; }
step() { printf '\n== %s\n' "$*"; }

cleanup() {
  if [ -n "$MYSQL_STARTED" ]; then
    "$MYSQL_BIN/mysqladmin.exe" --no-defaults -h127.0.0.1 -P"$TEMP_MYSQL_PORT" -uroot shutdown 2>/dev/null || true
  fi
  for _ in $(seq 1 30); do
    rm -rf "$WORK" 2>/dev/null || true
    [ -e "$WORK" ] || return 0
    sleep 1
  done
  echo "WARNING: could not delete $WORK. It contains customer data." >&2
}
trap cleanup EXIT

step "1/8 Pre-flight checks"
[ -f "$DUMP" ] || { echo "Dump not found: $DUMP" >&2; exit 1; }
[ -f config/application.rb ] || { echo "Run this from the Rails root." >&2; exit 1; }
if [ -n "$(psql_admin -c "select 1 from pg_database where datname='$TARGET'" | tr -d '\r')" ]; then
  echo "Database $TARGET already exists. Refusing to overwrite it." >&2
  exit 1
fi
echo "Target: $TARGET on $PGHOST:$PGPORT"

step "2/8 Extract dump and start temporary MySQL"
case "$DUMP" in
  *.zip) unzip -q -o "$DUMP" -d "$WORK/extract"; SQL="$(ls "$WORK"/extract/*.sql | head -1)" ;;
  *)     SQL="$DUMP" ;;
esac
"$MYSQL_BIN/mysqld.exe" --no-defaults --initialize-insecure --datadir="$WORK_WIN/mydata" 2>/dev/null
powershell.exe -NoProfile -Command "Start-Process -FilePath '$(cygpath -w "$MYSQL_BIN/mysqld.exe")' -ArgumentList '--no-defaults','--datadir=$WORK_WIN/mydata','--port=$TEMP_MYSQL_PORT','--bind-address=127.0.0.1','--mysqlx=OFF','--secure-file-priv=','--sql-mode=','--character-set-server=utf8mb4' -WindowStyle Hidden"
MYSQL_STARTED=1
for _ in $(seq 1 60); do mysql_cmd -e "select 1" >/dev/null 2>&1 && break; sleep 1; done
mysql_cmd -e "create database src character set utf8mb4"
mysql_cmd --default-character-set=utf8mb4 --init-command="SET sql_mode=''" src < "$SQL"
echo "Dump loaded."

step "3/8 Create target from db/schema.rb"
DATABASE_URL="postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$TARGET" bundle exec rails db:create db:schema:load 2>&1 | grep -v DEPRECATION | tail -1

step "4/8 Compare schemas"
mysql_cmd -N src -e "select table_name,column_name,data_type from information_schema.columns where table_schema='src' order by table_name,ordinal_position" | tr -d '\r' > "$WORK/my_cols.tsv"
psql_target -At -F $'\t' -c "select table_name,column_name from information_schema.columns where table_schema='public' order by 1,ordinal_position" | tr -d '\r' > "$WORK/pg_cols.tsv"
MISSING="$(awk -F'\t' 'NR==FNR{p[$1 FS $2]=1;next} !(($1 FS $2) in p){print $1"."$2}' "$WORK/pg_cols.tsv" "$WORK/my_cols.tsv")"
if [ -n "$MISSING" ]; then echo "Columns missing from PostgreSQL:" >&2; echo "$MISSING" >&2; exit 1; fi
cut -f1 "$WORK/my_cols.tsv" | uniq | grep -vE "$SKIP_TABLES" > "$WORK/tables.txt"
echo "$(wc -l < "$WORK/tables.txt") tables, $(wc -l < "$WORK/my_cols.tsv") columns: every MySQL column exists in PostgreSQL."

step "5/8 Build export, load and fingerprint SQL"
# MySQL's OUTFILE format maps to COPY text format: \N for NULL, backslash escapes.
# Hex literals avoid the mysql client misreading backslashes.
mkdir -p "$WORK/out"
{
  echo "SET session_replication_role = replica;"   # FK checks off for load order only
} > "$WORK/load.sql"
: > "$WORK/export.sql"; : > "$WORK/fp_mysql.sql"; : > "$WORK/fp_pg.sql"
while read -r t; do
  cols=""; my_fp=""; pg_fp=""
  while IFS=$'\t' read -r tb c ty; do
    [ "$tb" = "$t" ] || continue
    cols="$cols${cols:+,}\`$c\`"
    case "$ty" in
      datetime|timestamp) a="date_format(\`$c\`,'%Y-%m-%d %H:%i:%s.%f')"; b="to_char(\"$c\",'YYYY-MM-DD HH24:MI:SS.US')" ;;
      date)               a="date_format(\`$c\`,'%Y-%m-%d')";             b="to_char(\"$c\",'YYYY-MM-DD')" ;;
      tinyint)            a="cast(\`$c\` as char)";                       b="(\"$c\"::int)::text" ;;
      *)                  a="convert(\`$c\` using utf8mb4)";              b="\"$c\"::text" ;;
    esac
    my_fp="$my_fp${my_fp:+,}ifnull($a,'~NULL~')"
    pg_fp="$pg_fp${pg_fp:+,}coalesce($b,'~NULL~')"
  done < "$WORK/my_cols.tsv"
  echo "SELECT $cols INTO OUTFILE '$WORK_WIN/out/$t.tsv' CHARACTER SET utf8mb4 FIELDS TERMINATED BY X'09' ESCAPED BY X'5C' LINES TERMINATED BY X'0A' FROM \`$t\`;" >> "$WORK/export.sql"
  echo "\\copy \"$t\" ($(echo "$cols" | tr '`' '"')) from '$WORK_WIN/out/$t.tsv'" >> "$WORK/load.sql"
  echo "select '$t', md5(concat_ws(char(31),$my_fp)) from \`$t\`;" >> "$WORK/fp_mysql.sql"
  echo "select '$t', md5(concat_ws(chr(31),$pg_fp)) from \"$t\";" >> "$WORK/fp_pg.sql"
done < "$WORK/tables.txt"
cat >> "$WORK/load.sql" <<'SQL'
SET session_replication_role = DEFAULT;
DO $$ DECLARE r record; m bigint; BEGIN
  FOR r IN SELECT table_name, pg_get_serial_sequence(quote_ident(table_name),'id') s
           FROM information_schema.columns
           WHERE table_schema='public' AND column_name='id' AND column_default LIKE 'nextval%' LOOP
    EXECUTE format('SELECT max(id) FROM %I', r.table_name) INTO m;
    IF m IS NOT NULL THEN PERFORM setval(r.s, m); END IF;
  END LOOP; END $$;
SQL

step "6/8 Export from MySQL and load into PostgreSQL (one transaction)"
mysql_cmd src < "$WORK/export.sql"
sed -i 's/\r/\\r/g' "$WORK"/out/*.tsv          # COPY rejects a bare carriage return
psql_target -q -1 -v ON_ERROR_STOP=1 -f "$WORK_WIN/load.sql"
echo "Loaded."

step "7/8 Verify every row"
mysql_cmd -N --default-character-set=utf8mb4 src < "$WORK/fp_mysql.sql" | tr -d '\r' | sed -E 's/\t/ /' | LC_ALL=C sort > "$WORK/fp_mysql.txt"
psql_target -At -F ' ' -f "$WORK_WIN/fp_pg.sql" | tr -d '\r' | LC_ALL=C sort > "$WORK/fp_pg.txt"
ROWS_MY="$(wc -l < "$WORK/fp_mysql.txt")"; ROWS_PG="$(wc -l < "$WORK/fp_pg.txt")"
DIFFS="$(diff "$WORK/fp_mysql.txt" "$WORK/fp_pg.txt" | grep -cE '^[<>]' || true)"
echo "Rows: MySQL=$ROWS_MY PostgreSQL=$ROWS_PG. Differing fingerprints: $DIFFS"

BEHIND=0
while read -r t s; do
  [ -n "$s" ] || continue
  read -r seq_value max_id <<< "$(psql_target -At -F ' ' -c "select (select last_value from $s), coalesce((select max(id) from \"$t\"),0)" | tr -d '\r')"
  [ "$seq_value" -ge "$max_id" ] || { echo "ID counter behind: $t" >&2; BEHIND=$((BEHIND+1)); }
done < <(psql_target -At -F ' ' -c "select table_name, pg_get_serial_sequence(quote_ident(table_name),'id') from information_schema.columns where table_schema='public' and column_name='id' and column_default like 'nextval%'" | tr -d '\r')
echo "ID counters behind: $BEHIND"

step "8/8 Report orphaned rows"
psql_target -At -F '|' -c "select conrelid::regclass, a.attname, confrelid::regclass, fa.attname from pg_constraint c join pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1] join pg_attribute fa on fa.attrelid=c.confrelid and fa.attnum=c.confkey[1] where contype='f'" | tr -d '\r' > "$WORK/fks.txt"
ORPHANS=0
while IFS='|' read -r t c ft fc; do
  n="$(psql_target -At -c "select count(*) from $t x where x.$c is not null and not exists (select 1 from $ft y where y.$fc=x.$c)" | tr -d '\r')"
  if [ "$n" != "0" ]; then echo "  $t.$c -> $ft: $n"; ORPHANS=$((ORPHANS+n)); fi
done < "$WORK/fks.txt"
echo "Orphaned rows (already in the source, reported only): $ORPHANS"

if [ "$DIFFS" = "0" ] && [ "$ROWS_MY" = "$ROWS_PG" ] && [ "$BEHIND" = "0" ]; then
  printf '\nPASS: %s rows migrated to %s and verified.\n' "$ROWS_PG" "$TARGET"
else
  printf '\nFAIL: verification did not pass. Do not use %s.\n' "$TARGET" >&2
  exit 1
fi
