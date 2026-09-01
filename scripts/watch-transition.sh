#!/usr/bin/env bash
# Transition Watcher (Hermi Watcher) — заміна "/loop 5m перевір ..." нулем LLM-токенів.
# Принцип: детермінована shell-перевірка класифікує стан у RUNNING | SUCCESS |
# FAILED | ATTENTION | UNKNOWN. Claude будиться ТІЛЬКИ на ПЕРЕХОДІ у термінальний
# стан (SUCCESS/FAILED/ATTENTION) — прогрес (лог росте, RUNNING триває) не будить.
# Кожен wake — свіжа обмежена headless-сесія (~кілька k токенів), НЕ поточна розмова.
#
# НАЛАШТУЙ classify_state() і PROMPT під свою задачу. Правило безпеки: без
# --permission-mode acceptEdits у безлюдному режимі (RISK MATRIX); watcher
# аналізує і пише звіт — зміни коду йдуть через звичайну сесію.
set -u

INTERVAL=300                        # секунд між перевірками (перевірка = 0 LLM токенів)
COOLDOWN=900                        # мін. секунд між wake-ами
DAILY_WAKE_BUDGET=12                # макс. wake-ів на добу
MAX_QUIET_HOURS=6                   # RUNNING без переходу довше -> один ATTENTION-wake
MAX_TURNS=8

NAME="${1:-default}"                # кілька watcher-ів -> різні імена
D="${TMPDIR:-/tmp}/watch-transition-$NAME"
mkdir -p "$D"
LOG="$D/watch.log"

# ── КЛАСИФІКАТОР: надрукуй рівно одне слово: RUNNING|SUCCESS|FAILED|ATTENTION|UNKNOWN ──
classify_state() {
  # ПРИКЛАД systemd:
  #   case "$(systemctl is-active my-job.service 2>/dev/null)" in
  #     active|activating) echo RUNNING ;;
  #     inactive)          echo SUCCESS ;;      # якщо inactive = штатне завершення
  #     failed)            echo FAILED  ;;
  #     *)                 echo UNKNOWN ;;
  #   esac
  # ПРИКЛАД файл-маркер:
  #   [ -f /path/RESULT.ok ]   && { echo SUCCESS; return; }
  #   [ -f /path/RESULT.fail ] && { echo FAILED;  return; }
  #   pgrep -f my_corpus_job >/dev/null && { echo RUNNING; return; }
  #   echo ATTENTION   # процесу нема і результату нема — щось не так
  echo UNKNOWN
}

PROMPT='Watcher зафіксував перехід стану задачі. Нижче: попередній стан, новий стан, назва watcher-а. Проаналізуй, що сталося. Напиши короткий звіт у _reports/watcher/<YYYY-MM-DD-HHMM>.md (створи теку за потреби; якщо _reports немає — у temp/): вердикт, докази (команди перевірки живого стану), рекомендована наступна дія. КОД НЕ ЗМІНЮЙ — лише аналіз і звіт. Якщо це штатний успіх — один рядок підсумку.'

wake_claude() {
  local prev="$1" cur="$2" now today count last_wake
  now=$(date +%s); today=$(date +%F)
  last_wake=$(cat "$D/last_wake_ts" 2>/dev/null || echo 0)
  [ $((now - last_wake)) -lt "$COOLDOWN" ] && { echo "[$(date '+%F %T')] cooldown, skip wake ($prev->$cur)" >> "$LOG"; return; }
  [ "$(cat "$D/budget_date" 2>/dev/null)" = "$today" ] || { echo "$today" > "$D/budget_date"; echo 0 > "$D/budget_count"; }
  count=$(cat "$D/budget_count" 2>/dev/null || echo 0)
  [ "$count" -ge "$DAILY_WAKE_BUDGET" ] && { echo "[$(date '+%F %T')] daily budget exhausted, skip ($prev->$cur)" >> "$LOG"; return; }
  echo $((count + 1)) > "$D/budget_count"; echo "$now" > "$D/last_wake_ts"
  echo "[$(date '+%F %T')] TRANSITION $prev -> $cur — waking Claude (fresh session)" | tee -a "$LOG"
  printf '%s\n\nWatcher: %s\n--- PREV ---\n%s\n--- CUR ---\n%s\n' "$PROMPT" "$NAME" "$prev" "$cur" \
    | claude -p --max-turns "$MAX_TURNS" >> "$LOG" 2>&1
}

prev=$(cat "$D/state" 2>/dev/null || echo "")
last_transition=$(cat "$D/last_transition_ts" 2>/dev/null || echo "$(date +%s)")
quiet_waked=$(cat "$D/quiet_waked" 2>/dev/null || echo 0)

echo "[$(date '+%F %T')] watcher '$NAME' started (interval ${INTERVAL}s)" >> "$LOG"
while true; do
  cur=$(classify_state 2>&1 | tail -1)
  if [ "$cur" != "$prev" ]; then
    now=$(date +%s); echo "$now" > "$D/last_transition_ts"; last_transition=$now
    echo 0 > "$D/quiet_waked"; quiet_waked=0
    # Ідемпотентність: перехід обробляємо один раз, навіть після рестарту watcher-а
    if [ "$(cat "$D/last_handled" 2>/dev/null)" != "$prev->$cur" ]; then
      case "$cur" in
        SUCCESS|FAILED|ATTENTION) wake_claude "$prev" "$cur"; echo "$prev->$cur" > "$D/last_handled" ;;
        *) echo "[$(date '+%F %T')] transition $prev -> $cur (no wake)" >> "$LOG" ;;
      esac
    fi
    prev="$cur"; printf '%s' "$cur" > "$D/state"
  elif [ "$cur" = "RUNNING" ] && [ "$quiet_waked" -eq 0 ] \
       && [ $(( $(date +%s) - last_transition )) -ge $((MAX_QUIET_HOURS * 3600)) ]; then
    echo 1 > "$D/quiet_waked"; quiet_waked=1     # завислий RUNNING — один сигнал
    wake_claude "RUNNING(>${MAX_QUIET_HOURS}h)" "ATTENTION-QUIET"
  fi
  sleep "$INTERVAL"
done
# Запуск: nohup ./scripts/watch-transition.sh myjob >/dev/null 2>&1 &   Лог: $TMPDIR/watch-transition-myjob/watch.log
