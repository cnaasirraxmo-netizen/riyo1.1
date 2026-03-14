package utils

import (
	"log"
	"net/http"
	"time"
)

type RequestManager struct {
	Client *http.Client
}

func NewRequestManager() *RequestManager {
	return &RequestManager{
		Client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (m *RequestManager) Get(url string) (*http.Response, error) {
	var resp *http.Response
	var err error

	for i := 0; i < 3; i++ {
		resp, err = m.Client.Get(url)
		if err == nil && resp.StatusCode == http.StatusOK {
			return resp, nil
		}

		if err == nil {
			resp.Body.Close()
		}

		log.Printf("Retry %d for %s", i+1, url)
		time.Sleep(time.Duration(i+1) * time.Second)
	}

	return resp, err
}
