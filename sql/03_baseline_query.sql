EXPLAIN ANALYZE
SELECT lesson_id, completed_at IS NOT NULL
FROM lesson_progress 
WHERE user_id = 142
ORDER BY completed_at DESC