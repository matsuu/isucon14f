SET CHARACTER_SET_CLIENT = utf8mb4;
SET CHARACTER_SET_CONNECTION = utf8mb4;

USE isuride;

ALTER TABLE chairs ADD COLUMN total_distance INTEGER NOT NULL DEFAULT 0 INVISIBLE;
ALTER TABLE chairs ADD COLUMN total_distance_updated_at DATETIME(6) INVISIBLE;
UPDATE chairs, (SELECT chair_id, SUM(IFNULL(distance, 0)) AS total_distance, MAX(created_at) AS total_distance_updated_at FROM (SELECT chair_id, created_at, ABS(latitude - LAG(latitude) OVER (PARTITION BY chair_id ORDER BY created_at)) + ABS(longitude - LAG(longitude) OVER (PARTITION BY chair_id ORDER BY created_at)) AS distance FROM chair_locations) tmp GROUP BY chair_id) AS d SET chairs.total_distance = d.total_distance, chairs.total_distance_updated_at = d.total_distance_updated_at WHERE chairs.id = d.chair_id;
