package extraction

import (
	"strings"
	"github.com/riyobox/backend/internal/models"
)

// RemoveDuplicates filters out duplicate video URLs.
func RemoveDuplicates(sources []models.Source) []models.Source {
	keys := make(map[string]bool)
	var list []models.Source
	for _, entry := range sources {
		if _, value := keys[entry.URL]; !value && entry.URL != "" {
			keys[entry.URL] = true
			list = append(list, entry)
		}
	}
	return list
}

// DetectQuality attempts to find the video quality from the URL.
func DetectQuality(url string) string {
	lowerURL := strings.ToLower(url)
	if strings.Contains(lowerURL, "2160") || strings.Contains(lowerURL, "4k") || strings.Contains(lowerURL, "uhd") {
		return "4K"
	}
	if strings.Contains(lowerURL, "1080") || strings.Contains(lowerURL, "fhd") || strings.Contains(lowerURL, "fullhd") || strings.Contains(lowerURL, "1920x1080") {
		return "1080p"
	}
	if strings.Contains(lowerURL, "720") || strings.Contains(lowerURL, "hd") || strings.Contains(lowerURL, "1280x720") {
		return "720p"
	}
	if strings.Contains(lowerURL, "480") || strings.Contains(lowerURL, "sd") || strings.Contains(lowerURL, "854x480") {
		return "480p"
	}
	if strings.Contains(lowerURL, "360") || strings.Contains(lowerURL, "640x360") {
		return "360p"
	}
	return "720p" // Default to 720p if not detected
}

// IsVideoURL checks if a URL points to a common video file or manifest.
func IsVideoURL(url string) bool {
	lower := strings.ToLower(url)
	return strings.Contains(lower, ".m3u8") ||
		strings.Contains(lower, ".mp4") ||
		strings.Contains(lower, ".mpd") ||
		strings.Contains(lower, ".webm") ||
		strings.Contains(lower, ".mkv") ||
		strings.Contains(lower, "/playlist/") ||
		strings.Contains(lower, "/manifest/")
}
