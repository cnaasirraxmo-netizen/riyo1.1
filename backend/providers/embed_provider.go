package providers

import (
	"fmt"
)

type EmbedProvider struct {
	Name string
	URLPattern string
}

func GetEmbedProviders() []EmbedProvider {
	return []EmbedProvider{
		{Name: "VidSrc", URLPattern: "https://vidsrc.to/embed/movie/%d"},
		{Name: "2Embed", URLPattern: "https://www.2embed.cc/embed/%d"},
		{Name: "SuperEmbed", URLPattern: "https://multiembed.mov/?video_id=%d&tmdb=1"},
	}
}

func GetTVEmbedProviders() []EmbedProvider {
	return []EmbedProvider{
		{Name: "VidSrc", URLPattern: "https://vidsrc.to/embed/tv/%d/%d/%d"},
		{Name: "2Embed", URLPattern: "https://www.2embed.cc/embedtv/%d&s=%d&e=%d"},
		{Name: "SuperEmbed", URLPattern: "https://multiembed.mov/?video_id=%d&tmdb=1&s=%d&e=%d"},
	}
}

func GenerateMovieURL(provider EmbedProvider, tmdbID int) string {
	return fmt.Sprintf(provider.URLPattern, tmdbID)
}

func GenerateTVURL(provider EmbedProvider, tmdbID, season, episode int) string {
	return fmt.Sprintf(provider.URLPattern, tmdbID, season, episode)
}
