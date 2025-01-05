package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"

	"github.com/oklog/ulid/v2"
)

var erroredUpstream = errors.New("errored upstream")

type paymentGatewayPostPaymentRequest struct {
	Amount int `json:"amount"`
}

type paymentGatewayGetPaymentsResponseOne struct {
	Amount int    `json:"amount"`
	Status string `json:"status"`
}

func init() {
	tr := http.DefaultTransport.(*http.Transport).Clone()
	tr.MaxIdleConnsPerHost = 10
	http.DefaultClient.Transport = tr
}

func requestPaymentGatewayPostPayment(ctx context.Context, paymentGatewayURL string, token string, param *paymentGatewayPostPaymentRequest, retrieveRidesOrderByCreatedAtAsc func() ([]Ride, error)) error {
	b, err := json.Marshal(param)
	if err != nil {
		return err
	}

	key := ulid.Make().String()

	// 失敗したらとりあえずリトライ
	retry := 0
	for {
		err := func() error {
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, paymentGatewayURL+"/payments", bytes.NewBuffer(b))
			if err != nil {
				return err
			}
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+token)
			req.Header.Set("Idempotency-Key", key)

			res, err := http.DefaultClient.Do(req)
			if err != nil {
				return err
			}
			io.Copy(io.Discard, res.Body)
			res.Body.Close()

			if res.StatusCode != http.StatusNoContent {
				return fmt.Errorf("statuscode: %d", res.StatusCode)
			}
			return nil
		}()
		if err != nil {
			if retry < 10 {
				retry++
				continue
			} else {
				return err
			}
		}
		break
	}

	return nil
}
