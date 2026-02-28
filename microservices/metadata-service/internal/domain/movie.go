package domain

type Movie struct {
	ID          string   `json:"id"`
	Title       string   `json:"title"`
	Description string   `json:"description"`
	PosterURL   string   `json:"poster_url"`
	VideoURL    string   `json:"video_url"` // Path to master.m3u8
	Genre       string   `json:"genre"`
	Year        int      `json:"year"`
	Duration    string   `json:"duration"`
	Rating      float64  `json:"rating"`
	IsFeatured  bool     `json:"is_featured"`
}

type Category struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Order int    `json:"order"`
}

type MovieRepository interface {
	GetByID(id string) (*Movie, error)
	ListFeatured() ([]*Movie, error)
	ListByCategory(category string, page, limit int) ([]*Movie, int, error)
}
