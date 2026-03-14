package providers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type TMDbProvider struct {
	APIKey string
	BaseURL string
}

func NewTMDbProvider() *TMDbProvider {
	return &TMDbProvider{
		APIKey: os.Getenv("TMDB_API_KEY"),
		BaseURL: "https://api.themoviedb.org/3",
	}
}

type TMDbMovie struct {
	ID               int      `json:"id"`
	Title            string   `json:"title"`
	OriginalTitle    string   `json:"original_title"`
	Overview         string   `json:"overview"`
	PosterPath       string   `json:"poster_path"`
	BackdropPath     string   `json:"backdrop_path"`
	ReleaseDate      string   `json:"release_date"`
	VoteAverage      float64  `json:"vote_average"`
	GenreIDs         []int    `json:"genre_ids"`
	Runtime          int      `json:"runtime"`
}

type TMDbTVShow struct {
	ID               int      `json:"id"`
	Name             string   `json:"name"`
	OriginalName     string   `json:"original_name"`
	Overview         string   `json:"overview"`
	PosterPath       string   `json:"poster_path"`
	BackdropPath     string   `json:"backdrop_path"`
	FirstAirDate     string   `json:"first_air_date"`
	VoteAverage      float64  `json:"vote_average"`
	GenreIDs         []int    `json:"genre_ids"`
	NumberOfSeasons  int      `json:"number_of_seasons"`
}

type TMDbSeason struct {
	SeasonNumber int `json:"season_number"`
	Name         string `json:"name"`
	Episodes     []TMDbEpisode `json:"episodes"`
}

type TMDbEpisode struct {
	EpisodeNumber int    `json:"episode_number"`
	Name          string `json:"name"`
	Overview      string `json:"overview"`
	StillPath     string `json:"still_path"`
	AirDate       string `json:"air_date"`
	Runtime       int    `json:"runtime"`
}

type TMDbResponse struct {
	Results []json.RawMessage `json:"results"`
}

func (p *TMDbProvider) FetchTrendingMovies() ([]TMDbMovie, error) {
	url := fmt.Sprintf("%s/trending/movie/day?api_key=%s", p.BaseURL, p.APIKey)
	return p.fetchMovies(url)
}

func (p *TMDbProvider) FetchPopularMovies() ([]TMDbMovie, error) {
	url := fmt.Sprintf("%s/movie/popular?api_key=%s", p.BaseURL, p.APIKey)
	return p.fetchMovies(url)
}

func (p *TMDbProvider) FetchTrendingTVShows() ([]TMDbTVShow, error) {
	url := fmt.Sprintf("%s/trending/tv/day?api_key=%s", p.BaseURL, p.APIKey)
	return p.fetchTVShows(url)
}

func (p *TMDbProvider) fetchMovies(url string) ([]TMDbMovie, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var tmdbResp TMDbResponse
	if err := json.NewDecoder(resp.Body).Decode(&tmdbResp); err != nil {
		return nil, err
	}

	var movies []TMDbMovie
	for _, result := range tmdbResp.Results {
		var movie TMDbMovie
		if err := json.Unmarshal(result, &movie); err == nil {
			movies = append(movies, movie)
		}
	}
	return movies, nil
}

func (p *TMDbProvider) fetchTVShows(url string) ([]TMDbTVShow, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var tmdbResp TMDbResponse
	if err := json.NewDecoder(resp.Body).Decode(&tmdbResp); err != nil {
		return nil, err
	}

	var tvShows []TMDbTVShow
	for _, result := range tmdbResp.Results {
		var tvShow TMDbTVShow
		if err := json.Unmarshal(result, &tvShow); err == nil {
			tvShows = append(tvShows, tvShow)
		}
	}
	return tvShows, nil
}

func (p *TMDbProvider) FetchMovieDetails(tmdbID int) (TMDbMovie, error) {
	url := fmt.Sprintf("%s/movie/%d?api_key=%s", p.BaseURL, tmdbID, p.APIKey)
	resp, err := http.Get(url)
	if err != nil {
		return TMDbMovie{}, err
	}
	defer resp.Body.Close()

	var movie TMDbMovie
	if err := json.NewDecoder(resp.Body).Decode(&movie); err != nil {
		return TMDbMovie{}, err
	}
	return movie, nil
}

func (p *TMDbProvider) FetchTVShowDetails(tmdbID int) (TMDbTVShow, error) {
	url := fmt.Sprintf("%s/tv/%d?api_key=%s", p.BaseURL, tmdbID, p.APIKey)
	resp, err := http.Get(url)
	if err != nil {
		return TMDbTVShow{}, err
	}
	defer resp.Body.Close()

	var tvShow TMDbTVShow
	if err := json.NewDecoder(resp.Body).Decode(&tvShow); err != nil {
		return TMDbTVShow{}, err
	}
	return tvShow, nil
}

func (p *TMDbProvider) FetchSeasonDetails(tvID int, seasonNumber int) (TMDbSeason, error) {
	url := fmt.Sprintf("%s/tv/%d/season/%d?api_key=%s", p.BaseURL, tvID, seasonNumber, p.APIKey)
	resp, err := http.Get(url)
	if err != nil {
		return TMDbSeason{}, err
	}
	defer resp.Body.Close()

	var season TMDbSeason
	if err := json.NewDecoder(resp.Body).Decode(&season); err != nil {
		return TMDbSeason{}, err
	}
	return season, nil
}
