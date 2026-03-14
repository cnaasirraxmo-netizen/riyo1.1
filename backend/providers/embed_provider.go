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
		{Name: "VidLink", URLPattern: "https://vidlink.pro/movie/%d"},
		{Name: "AutoEmbed", URLPattern: "https://player.autoembed.cc/embed/movie/%d"},
		{Name: "MultiEmbed", URLPattern: "https://vidsrc.me/embed/movie?tmdb=%d"},
	}
}

func GetTVEmbedProviders() []EmbedProvider {
	return []EmbedProvider{
		{Name: "VidSrc", URLPattern: "https://vidsrc.to/embed/tv/%d/%d/%d"},
		{Name: "2Embed", URLPattern: "https://www.2embed.cc/embedtv/%d&s=%d&e=%d"},
		{Name: "SuperEmbed", URLPattern: "https://multiembed.mov/?video_id=%d&tmdb=1&s=%d&e=%d"},
		{Name: "VidLink", URLPattern: "https://vidlink.pro/tv/%d/%d/%d"},
		{Name: "AutoEmbed", URLPattern: "https://player.autoembed.cc/embed/tv/%d/%d/%d"},
		{Name: "MultiEmbed", URLPattern: "https://vidsrc.me/embed/tv?tmdb=%d&s=%d&e=%d"},
	}
}

func GenerateMovieURL(provider EmbedProvider, tmdbID int) string {
	return fmt.Sprintf(provider.URLPattern, tmdbID)
}

func GenerateTVURL(provider EmbedProvider, tmdbID, season, episode int) string {
	return fmt.Sprintf(provider.URLPattern, tmdbID, season, episode)
}
