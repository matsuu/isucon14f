SET CHARACTER_SET_CLIENT = utf8mb4;
SET CHARACTER_SET_CONNECTION = utf8mb4;

USE isuride;

-- ALTER TABLE chairs ADD COLUMN total_distance INTEGER NOT NULL DEFAULT 0 INVISIBLE;
-- ALTER TABLE chairs ADD COLUMN total_distance_updated_at DATETIME(6) INVISIBLE;
-- ALTER TABLE chairs ADD COLUMN last_latitude INTEGER INVISIBLE;
-- ALTER TABLE chairs ADD COLUMN last_longitude INTEGER INVISIBLE;
-- ALTER TABLE chairs ADD COLUMN last_status ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NULL COMMENT '状態' INVISIBLE;

UPDATE chairs, (SELECT chair_id, SUM(IFNULL(distance, 0)) AS total_distance, MAX(created_at) AS total_distance_updated_at FROM (SELECT chair_id, created_at, ABS(latitude - LAG(latitude) OVER (PARTITION BY chair_id ORDER BY created_at)) + ABS(longitude - LAG(longitude) OVER (PARTITION BY chair_id ORDER BY created_at)) AS distance FROM chair_locations) tmp GROUP BY chair_id) AS d SET chairs.total_distance = d.total_distance, chairs.total_distance_updated_at = d.total_distance_updated_at WHERE chairs.id = d.chair_id;

UPDATE chairs AS c
JOIN (
    SELECT cl1.chair_id, cl1.latitude, cl1.longitude
    FROM chair_locations AS cl1
    INNER JOIN (
        SELECT chair_id, MAX(created_at) AS max_created_at
        FROM chair_locations
        GROUP BY chair_id
    ) AS cl2 ON cl1.chair_id = cl2.chair_id AND cl1.created_at = cl2.max_created_at
) AS latest_cl ON c.id = latest_cl.chair_id
SET c.last_latitude = latest_cl.latitude,
    c.last_longitude = latest_cl.longitude;

