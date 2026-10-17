.PHONY: db

db:
	docker compose exec postgres psql -U learner -d engineering_lab