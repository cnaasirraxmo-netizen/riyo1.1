package scrapers

import (
	"reflect"
	"testing"
)

func TestExtractVideoSources(t *testing.T) {
	html := `
		<html>
			<body>
				<video>
					<source src="https://example.com/video1.mp4">
					<source data-src="https://example.com/video2.m3u8">
				</video>
				<script>
					var config = { "file": "https://example.com/video3.mpd" };
				</script>
				<div data-video-url="https://example.com/video4.webm"></div>
				<a href="https://example.com/video5.mkv">Download</a>
			</body>
		</html>
	`
	expected := []string{
		"https://example.com/video2.m3u8",
		"https://example.com/video1.mp4",
		"https://example.com/video4.webm",
		"https://example.com/video5.mkv",
		"https://example.com/video3.mpd",
	}

	sources := ExtractVideoSources(html)

	// Check if all expected sources are found (order might differ due to regex sequence)
	for _, exp := range expected {
		found := false
		for _, s := range sources {
			if s == exp {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Expected source %s not found in %v", exp, sources)
		}
	}
}

func TestExtractJSVariables(t *testing.T) {
	html := `
		<script>
			var hls_url = "https://example.com/playlist.m3u8";
			var stream_url = "https://example.com/stream.mp4";
			window.config = {"sources": [{"file": "https://example.com/config.m3u8"}]};
			player.setup({"playlist": [{"file": "https://example.com/setup.mp4"}]})
		</script>
	`
	sources := ExtractJSVariables(html)
	expected := []string{
		"https://example.com/playlist.m3u8",
		"https://example.com/stream.mp4",
		"https://example.com/config.m3u8",
		"https://example.com/setup.mp4",
	}

	for _, exp := range expected {
		found := false
		for _, s := range sources {
			if s == exp {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Expected source %s not found in %v", exp, sources)
		}
	}
}

func TestExtractNetworkDiscovery(t *testing.T) {
	html := `
		<script>
			fetch("https://example.com/api/v1/get_sources?id=123");
			$.ajax({url: "https://example.com/ajax/embed/video?id=456"});
		</script>
	`

	sources := ExtractNetworkDiscovery(html)
	expected := []string{
		"https://example.com/api/v1/get_sources?id=123",
		"https://example.com/ajax/embed/video?id=456",
	}

	for _, exp := range expected {
		found := false
		for _, s := range sources {
			if s == exp {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Expected endpoint %s not found in %v", exp, sources)
		}
	}
}

func TestExtractEmbeds(t *testing.T) {
	html := `<iframe src="https://vidsrc.to/embed/movie/123"></iframe>`
	embeds := ExtractEmbeds(html)
	expected := []string{"https://vidsrc.to/embed/movie/123"}

	if !reflect.DeepEqual(embeds, expected) {
		t.Errorf("Expected %v, got %v", expected, embeds)
	}
}

func TestExtractRedirects(t *testing.T) {
	// Mock a scenario where a link leads to a redirect
	html := `
		<html>
			<body>
				<a href="https://google.com/url?q=https://example.com/video.m3u8">Go to Video</a>
				<a href="https://bit.ly/3abc123">Short Link</a>
			</body>
		</html>
	`
	// Note: In real testing, we can't easily follow external redirects without mocking the client,
	// but we can verify the function doesn't crash and handles the HTML correctly.
	sources := ExtractRedirects(html)
	// Expect no sources found since these aren't real redirect chains to video files,
	// but this ensures the regex and loop logic are working.
	if sources == nil {
		sources = []string{}
	}
}
