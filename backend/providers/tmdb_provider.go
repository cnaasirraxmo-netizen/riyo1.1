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

func (p *TMDbProvider) FetchTopRatedMovies() ([]TMDbMovie, error) {
	url := fmt.Sprintf("%s/movie/top_rated?api_key=%s", p.BaseURL, p.APIKey)
	return p.fetchMovies(url)
}

func (p *TMDbProvider) FetchUpcomingMovies() ([]TMDbMovie, error) {
	url := fmt.Sprintf("%s/movie/upcoming?api_key=%s", p.BaseURL, p.APIKey)
	return p.fetchMovies(url)
}

func (p *TMDbProvider) FetchTrendingTVShows() ([]TMDbTVShow, error) {
	url := fmt.Sprintf("%s/trending/tv/day?api_key=%s", p.BaseURL, p.APIKey)
	return p.fetchTVShows(url)
}

func (p *TMDbProvider) FetchPopularTVShows() ([]TMDbTVShow, error) {
	url := fmt.Sprintf("%s/tv/popular?api_key=%s", p.BaseURL, p.APIKey)
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
