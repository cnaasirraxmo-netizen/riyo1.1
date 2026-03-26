package scrapers

import (
	"net/http"
	"strings"
	"time"
)

var validationClient = &http.Client{
	Timeout: 10 * time.Second,
}

func ValidateURL(url string) (bool, string) {
	req, err := http.NewRequest("HEAD", url, nil)
	if err != nil {
		return false, ""
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

	resp, err := validationClient.Do(req)
	if err != nil {
		// Fallback to GET for some providers that don't support HEAD
		req.Method = "GET"
		req.Header.Set("Range", "bytes=0-0")
		resp, err = validationClient.Do(req)
		if err != nil {
			return false, ""
		}
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusPartialContent {
		ct := strings.ToLower(resp.Header.Get("Content-Type"))
		isValid := strings.Contains(ct, "video/") ||
			strings.Contains(ct, "mpegurl") ||
			strings.Contains(ct, "dash+xml") ||
			strings.Contains(ct, "application/octet-stream")
		return isValid, ct
	}

	return false, ""
}
