CREATE INDEX idx_lesson_progress_user_completed
ON lesson_progress (user_id, completed_at DESC);