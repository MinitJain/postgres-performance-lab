INSERT INTO lesson_progress (user_id, lesson_id, completed_at)
SELECT
    100 + (g % 100),
    1000 + g,
    NOW() - (g * INTERVAL '1 minute')
FROM generate_series(1, 100000) AS g;