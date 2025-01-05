package main

import (
	"database/sql"
	"errors"
	"fmt"
	"net/http"
)

var chairModels = map[string]int{
	"AeroSeat":        3,
	"Aurora Glow":     7,
	"BalancePro":      3,
	"ComfortBasic":    2,
	"EasySit":         2,
	"ErgoFlex":        3,
	"Infinity Seat":   5,
	"Legacy Chair":    7,
	"LiteLine":        2,
	"LuxeThrone":      5,
	"Phoenix Ultra":   7,
	"ShadowEdition":   7,
	"SitEase":         2,
	"StyleSit":        3,
	"Titanium Line":   5,
	"ZenComfort":      5,
	"アルティマシート X":      5,
	"インフィニティ GEAR V":  7,
	"インペリアルクラフト LUXE": 5,
	"ヴァーチェア SUPREME":  7,
	"エアシェル ライト":       2,
	"エアフロー EZ":        3,
	"エコシート リジェネレイト":   7,
	"エルゴクレスト II":      3,
	"オブシディアン PRIME":   7,
	"クエストチェア Lite":    3,
	"ゲーミングシート NEXUS":  3,
	"シェルシート ハイブリッド":   3,
	"シャドウバースト M":      5,
	"ステルスシート ROGUE":   5,
	"ストリームギア S1":      3,
	"スピンフレーム 01":      2,
	"スリムライン GX":       5,
	"ゼノバース ALPHA":     7,
	"ゼンバランス EX":       5,
	"タイタンフレーム ULTRA":  7,
	"チェアエース S":        2,
	"ナイトシート ブラックエディション": 7,
	"フォームライン RX":        3,
	"フューチャーステップ VISION": 7,
	"フューチャーチェア CORE":    5,
	"プレイスタイル Z":         3,
	"フレックスコンフォート PRO":   3,
	"プレミアムエアチェア ZETA":   5,
	"プロゲーマーエッジ X1":      5,
	"ベーシックスツール プラス":     2,
	"モーションチェア RISE":     5,
	"リカーブチェア スマート":      3,
	"リラックスシート NEO":      2,
	"リラックス座":            2,
	"ルミナスエアクラウン":        7,
	"匠座 PRO LIMITED":    7,
	"匠座（たくみざ）プレミアム":     7,
	"雅楽座":        5,
	"風雅（ふうが）チェア": 3,
}

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
	// if err := db.SelectContext(ctx, &chairs, "SELECT *, IFNULL(last_latitude,0) AS last_latitude, IFNULL(last_longitude,0) AS last_longitude FROM chairs WHERE is_active = TRUE AND id NOT IN (SELECT chair_id FROM rides WHERE chair_id IS NOT NULL AND id IN (SELECT ride_id FROM ride_statuses GROUP BY ride_id HAVING COUNT(chair_sent_at) < 6)) AND id NOT IN (SELECT chair_id FROM rides LEFT JOIN ride_statuses ON rides.id = ride_statuses.ride_id WHERE ride_statuses.ride_id IS null)"); err != nil {
	if err := db.SelectContext(ctx, &chairs, "SELECT *, IFNULL(last_latitude,0) AS last_latitude, IFNULL(last_longitude,0) AS last_longitude FROM chairs WHERE is_active = TRUE AND TRUE = (SELECT COUNT(*) = 0 FROM (SELECT COUNT(chair_sent_at) = 6 AS completed FROM ride_statuses WHERE ride_id IN (SELECT id FROM rides WHERE chair_id = chairs.id) GROUP BY ride_id) is_completed WHERE completed = FALSE)"); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	for _, ride := range rides {
		// chairの在庫がなければスキップ
		if len(chairs) == 0 {
			break
		}
		rideDeliver := calculateDistance(ride.PickupLatitude, ride.PickupLongitude, ride.DestinationLatitude, ride.DestinationLongitude)
		threthold := 9999999999
		target := -1
		for i, chair := range chairs {
			speed := 1
			if v, ok := chairModels[chair.Model]; ok {
				speed = v
			}
			pickupDeliver := calculateDistance(chair.LastLatitude, chair.LastLongitude, ride.PickupLatitude, ride.PickupLongitude)
			if pickupDeliver > 100 {
				continue
			}
			v := (pickupDeliver + rideDeliver) / speed
			if v < threthold {
				target = i
				threthold = v
			}
		}
		if target == -1 {
			writeError(w, http.StatusInternalServerError, fmt.Errorf("no chair found: ride_id:%v, threthold:%v", ride.ID, threthold))
			return
		}
		// 100を超える場合はスキップ
		if threthold > 100 {
			continue
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
