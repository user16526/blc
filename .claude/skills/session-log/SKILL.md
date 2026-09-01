---
name: session-log
description: Записати результат завершеної робочої задачі в телеметрію Context Guard. Використовуй, коли задача завершена (успішно чи ні), коли handoff переводиться в DONE, або коли користувач викликає /session-log чи просить "залогуй сесію/результат".
---

# /session-log — outcome-запис телеметрії

1. Постав користувачу рівно два коротких питання (якщо відповіді не очевидні
   з розмови): (а) «Чи довелося переробляти щось, що вже було зроблено до
   компакції?» (б) «Чи помітили ви втрату контексту або дрейф якості?»
2. Визнач сам: outcome = success | partial | fail.
   verifier: якщо існує `_reports/runs/latest.json` для ЦІЄЇ задачі — візьми з
   нього (verdict GREEN або gate PASS → pass; RED/BLOCKED → fail), НЕ питай;
   інакше — за результатом тестів/verifier-перевірки, якщо була; інакше none.
3. Прочитай авто-поля поточної сесії, якщо файл існує:
   `cat "${TMPDIR:-/tmp}/claude-context-guard/telemetry-<session_id>.json"`
   (session_id є у state-файлах statusline у тій самій директорії; якщо
   недоступний — пропусти, аналізатор підтягне сесійний запис за полем session).
4. Допиши ОДИН рядок JSON у `.claude/handoffs/telemetry.jsonl`:
   {"type":"outcome","ts":"<ISO>","task":"<коротка назва>","session":"<session_id або null>",
    "outcome":"...","verifier":"...","rework_after_compact":true|false,
    "human_noticed_drift":true|false,
    "peak_used":<з авто-полів або null>,"compacts":<або null>}
5. Підтверди одним рядком, що запис зроблено. Нічого більше не змінюй.
