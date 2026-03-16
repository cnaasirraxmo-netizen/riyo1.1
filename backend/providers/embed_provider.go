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
		{Name: "VidSrcPro", URLPattern: "https://vidsrc.pro/embed/movie/%d"},
		{Name: "MovieBox", URLPattern: "https://moviebox.pro/embed/movie/%d"},
		{Name: "FMovies", URLPattern: "https://fmovies.to/embed/movie/%d"},
		{Name: "Sflix", URLPattern: "https://sflix.to/embed/movie/%d"},
		{Name: "Dopebox", URLPattern: "https://dopebox.to/embed/movie/%d"},
		{Name: "SmashyStream", URLPattern: "https://embed.smashystream.com/playere.php?tmdb=%d"},
		{Name: "StreamTape", URLPattern: "https://streamtape.com/e/%d"},
		{Name: "MixDrop", URLPattern: "https://mixdrop.co/e/%d"},
		{Name: "EmbedFlix", URLPattern: "https://embedflix.net/movie/%d"},
		{Name: "MoviesAPI", URLPattern: "https://moviesapi.club/movie/%d"},
		{Name: "MultiEmbed", URLPattern: "https://vidsrc.me/embed/movie?tmdb=%d"},
		{Name: "AutoEmbed", URLPattern: "https://player.autoembed.cc/embed/movie/%d"},
	}
}

func GetTVEmbedProviders() []EmbedProvider {
	return []EmbedProvider{
		{Name: "VidSrc", URLPattern: "https://vidsrc.to/embed/tv/%d/%d/%d"},
		{Name: "2Embed", URLPattern: "https://www.2embed.cc/embedtv/%d&s=%d&e=%d"},
		{Name: "SuperEmbed", URLPattern: "https://multiembed.mov/?video_id=%d&tmdb=1&s=%d&e=%d"},
		{Name: "VidLink", URLPattern: "https://vidlink.pro/tv/%d/%d/%d"},
		{Name: "VidSrcPro", URLPattern: "https://vidsrc.pro/embed/tv/%d/%d/%d"},
		{Name: "MovieBox", URLPattern: "https://moviebox.pro/embed/tv/%d/%d/%d"},
		{Name: "FMovies", URLPattern: "https://fmovies.to/embed/tv/%d/%d/%d"},
		{Name: "Sflix", URLPattern: "https://sflix.to/embed/tv/%d/%d/%d"},
		{Name: "Dopebox", URLPattern: "https://dopebox.to/embed/tv/%d/%d/%d"},
		{Name: "SmashyStream", URLPattern: "https://embed.smashystream.com/playere.php?tmdb=%d&s=%d&e=%d"},
		{Name: "StreamTape", URLPattern: "https://streamtape.com/e/%d"},
		{Name: "MixDrop", URLPattern: "https://mixdrop.co/e/%d"},
		{Name: "EmbedFlix", URLPattern: "https://embedflix.net/tv/%d/%d/%d"},
		{Name: "MoviesAPI", URLPattern: "https://moviesapi.club/tv/%d-%d-%d"},
		{Name: "MultiEmbed", URLPattern: "https://vidsrc.me/embed/tv?tmdb=%d&s=%d&e=%d"},
		{Name: "AutoEmbed", URLPattern: "https://player.autoembed.cc/embed/tv/%d/%d/%d"},
	}
}

func GenerateMovieURL(provider EmbedProvider, tmdbID int) string {
	return fmt.Sprintf(provider.URLPattern, tmdbID)
}

func GenerateTVURL(provider EmbedProvider, tmdbID, season, episode int) string {
	return fmt.Sprintf(provider.URLPattern, tmdbID, season, episode)
}
