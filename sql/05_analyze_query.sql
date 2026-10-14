EXPLAIN ANALYZE
SELECT lesson_id, completed_at
FROM lesson_progress
WHERE user_id = 142
  AND completed_at IS NOT NULL
ORDER BY completed_at DESC;