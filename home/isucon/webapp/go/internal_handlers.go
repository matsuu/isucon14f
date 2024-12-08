package main

import (
	"database/sql"
	"errors"
	"net/http"
)

// このAPIをインスタンス内から一定間隔で叩かせることで、椅子とライドをマッチングさせる
func internalGetMatching(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	rides := []Ride{}
	if err := db.SelectContext(ctx, &rides, `SELECT * FROM rides WHERE chair_id IS NULL ORDER BY created_at`); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	for _, ride := range rides {
		matched := &Chair{}
		empty := false

		d := calculateDistance(ride.PickupLatitude, ride.PickupLongitude, ride.DestinationLatitude, ride.DestinationLongitude)
		var query string
		if d < 20 {
			query = "SELECT * FROM chairs WHERE is_active = TRUE ORDER BY ABS(? - last_latitude)+ABS(?-last_longitude), speed ASC LIMIT 1 OFFSET ?"
		} else {
			query = "SELECT * FROM chairs WHERE is_active = TRUE ORDER BY ABS(? - last_latitude)+ABS(?-last_longitude), speed DESC LIMIT 1 OFFSET ?"
		}

		for i := 0; i < 10; i++ {
			if err := db.GetContext(ctx, matched, query, ride.PickupLatitude, ride.PickupLongitude, i); err != nil {
				if errors.Is(err, sql.ErrNoRows) {
					w.WriteHeader(http.StatusNoContent)
					return
				}
				writeError(w, http.StatusInternalServerError, err)
			}

			if err := db.GetContext(ctx, &empty, "SELECT COUNT(*) = 0 FROM (SELECT COUNT(chair_sent_at) = 6 AS completed FROM ride_statuses WHERE ride_id IN (SELECT id FROM rides WHERE chair_id = ?) GROUP BY ride_id) is_completed WHERE completed = FALSE", matched.ID); err != nil {
				writeError(w, http.StatusInternalServerError, err)
				return
			}
			if empty {
				break
			}
		}
		if !empty {
			w.WriteHeader(http.StatusNoContent)
			continue
		}

		if _, err := db.ExecContext(ctx, "UPDATE rides SET chair_id = ? WHERE id = ?", matched.ID, ride.ID); err != nil {
			writeError(w, http.StatusInternalServerError, err)
			return
		}
	}

	w.WriteHeader(http.StatusNoContent)
}
