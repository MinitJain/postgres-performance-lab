# PostgreSQL Performance Lab

A hands-on experiment exploring how PostgreSQL indexes affect query execution plans and performance.

## Objective

Measure the execution time of a query before and after adding a composite index, then inspect how PostgreSQL's query planner changes its execution strategy.

## Environment

- PostgreSQL 17
- Docker
- SQL and `EXPLAIN ANALYZE`
- Synthetic dataset of approximately 100,000 rows

## Experiment

The benchmark query filters lesson progress by `user_id`, excludes incomplete lessons, and orders results by `completed_at` in descending order.

The index tested is:

```sql
CREATE INDEX idx_lesson_progress_user_completed
ON lesson_progress (user_id, completed_at DESC);
```

## Preliminary Results

| Measurement        |           Before index |                          After index |
| ------------------ | ---------------------: | -----------------------------------: |
| Execution time     |               8.791 ms |                             1.828 ms |
| Execution strategy | Sequential scan + sort | Bitmap index scan + heap scan + sort |

The initial measurements showed approximately **4.81× speedup**, or a **79.2% reduction** in execution time.

These are preliminary single-run measurements, not a statistically rigorous benchmark. Results can vary with caching, hardware, and database conditions.

## Repository Structure

- `compose.yaml`: Local PostgreSQL environment
- `sql/01_schema.sql`: Table definition
- `sql/02_seed_data.sql`: Synthetic test data
- `sql/03_baseline_query.sql`: Baseline query
- `sql/04_create_index.sql`: Index creation
- `sql/05_analyze_query.sql`: Query after indexing
- `results/`: Benchmark outputs

## Key Learning

An index can reduce the amount of data PostgreSQL needs to scan, but it does not guarantee that every sort will disappear. The query planner chooses an execution strategy based on estimated costs and available statistics.
