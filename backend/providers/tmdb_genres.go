package providers

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (p *TMDbProvider) FetchGenres() (map[int]string, error) {
	url := fmt.Sprintf("%s/genre/movie/list?api_key=%s", p.BaseURL, p.APIKey)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data struct {
		Genres []struct {
			ID   int    `json:"id"`
			Name string `json:"name"`
		} `json:"genres"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	genreMap := make(map[int]string)
	for _, g := range data.Genres {
		genreMap[g.ID] = g.Name
	}
	return genreMap, nil
}
