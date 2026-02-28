package ffmpeg

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type Transcoder struct{}

func NewTranscoder() *Transcoder {
	return &Transcoder{}
}

func (t *Transcoder) GenerateHLS(inputPath string, outputPath string, resolution string) error {
	resMap := map[string]string{
		"1080p": "1920x1080 -b:v 5000k",
		"720p":  "1280x720 -b:v 2500k",
		"480p":  "854x480 -b:v 1200k",
		"360p":  "640x360 -b:v 800k",
	}

	params, ok := resMap[resolution]
	if !ok {
		return fmt.Errorf("unsupported resolution: %s", resolution)
	}

	parts := strings.Split(params, " ")
	size := parts[0]
	bitrate := parts[2]

	// Ensure output directory exists
	if err := os.MkdirAll(outputPath, 0755); err != nil {
		return fmt.Errorf("failed to create output dir: %v", err)
	}

	args := []string{
		"-i", inputPath,
		"-s", size,
		"-b:v", bitrate,
		"-c:v", "libx264",
		"-preset", "fast",
		"-crf", "23",
		"-g", "48",
		"-keyint_min", "48",
		"-sc_threshold", "0",
		"-c:a", "aac",
		"-b:a", "128k",
		"-ac", "2",
		"-f", "hls",
		"-hls_time", "6",
		"-hls_playlist_type", "vod",
		"-hls_segment_filename", filepath.Join(outputPath, "seg_%03d.ts"),
		filepath.Join(outputPath, "index.m3u8"),
	}

	cmd := exec.Command("ffmpeg", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpeg error: %v, output: %s", err, string(output))
	}

	return nil
}

func (t *Transcoder) GenerateMasterPlaylist(outputDir string, resolutions []string) error {
	var content strings.Builder
	content.WriteString("#EXTM3U\n")
	content.WriteString("#EXT-X-VERSION:3\n")

	resToBandwidth := map[string]string{
		"1080p": "5000000",
		"720p":  "2500000",
		"480p":  "1200000",
		"360p":  "800000",
	}

	for _, res := range resolutions {
		bandwidth := resToBandwidth[res]
		content.WriteString(fmt.Sprintf("#EXT-X-STREAM-INF:BANDWIDTH=%s,RESOLUTION=%s\n", bandwidth, res))
		content.WriteString(fmt.Sprintf("%s/index.m3u8\n", res))
	}

	masterPath := filepath.Join(outputDir, "master.m3u8")
	return os.WriteFile(masterPath, []byte(content.String()), 0644)
}
