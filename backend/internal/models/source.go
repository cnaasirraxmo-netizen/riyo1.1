package models

// Source represents a direct video stream URL and its metadata.
type Source struct {
	URL      string `json:"url"`
	Quality  string `json:"quality"`
	Provider string `json:"provider"`
	Type     string `json:"type"` // mp4 / m3u8 / mpd
}
