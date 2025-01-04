package main

import (
	"database/sql"
	"errors"
	"fmt"
	"net/http"
)

// このAPIをインスタンス内から一定間隔で叩かせることで、椅子とライドをマッチングさせる
func internalGetMatching(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var rides []Ride
	if err := db.SelectContext(ctx, &rides, `SELECT * FROM rides WHERE chair_id IS NULL ORDER BY created_at`); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	var chairs []ChairWithLast
	if err := db.SelectContext(ctx, &chairs, "SELECT *, IFNULL(last_latitude,0) AS last_latitude, IFNULL(last_longitude,0) AS last_longitude FROM chairs WHERE is_active = TRUE AND id NOT IN (SELECT chair_id FROM rides WHERE chair_id IS NOT NULL AND id IN (SELECT ride_id FROM ride_statuses GROUP BY ride_id HAVING COUNT(chair_sent_at) < 6)) AND id NOT IN (SELECT chair_id FROM rides LEFT JOIN ride_statuses ON rides.id = ride_statuses.ride_id WHERE ride_statuses.ride_id IS null)"); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	for _, ride := range rides {
		threthold := 9999999999
		target := -1
		for i, chair := range chairs {
			deliver := calculateDistance(chair.LastLatitude, chair.LastLongitude, ride.PickupLatitude, ride.PickupLongitude)
			d := calculateDistance(ride.PickupLatitude, ride.PickupLongitude, ride.DestinationLatitude, ride.DestinationLongitude)
			if deliver+d < threthold {
				target = i
				threthold = deliver + d
			}
		}
		if target == -1 {
			writeError(w, http.StatusInternalServerError, fmt.Errorf("no chair found: ride_id:%v, threthold:%v", ride.ID, threthold))
			return
		}
		matched := chairs[target]
		chairs = append(chairs[:target], chairs[target+1:]...)

		if _, err := db.ExecContext(ctx, "UPDATE rides SET chair_id = ? WHERE id = ?", matched.ID, ride.ID); err != nil {
			writeError(w, http.StatusInternalServerError, err)
			return
		}
	}

	w.WriteHeader(http.StatusNoContent)
}
