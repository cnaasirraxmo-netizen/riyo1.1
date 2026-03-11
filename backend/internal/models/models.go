package models

import (
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
)

type UserSettings struct {
	ThemeMode                string   `bson:"themeMode" json:"themeMode"`
	AmoledMode               bool     `bson:"amoledMode" json:"amoledMode"`
	AppLanguage              string   `bson:"appLanguage" json:"appLanguage"`
	DefaultVideoQuality      string   `bson:"defaultVideoQuality" json:"defaultVideoQuality"`
	DownloadQuality          string   `bson:"downloadQuality" json:"downloadQuality"`
	FavoriteGenres           []string `bson:"favoriteGenres" json:"favoriteGenres"`
	NotificationsEnabled     bool     `bson:"notificationsEnabled" json:"notificationsEnabled"`
	AutoplayNextEpisode      bool     `bson:"autoplayNextEpisode" json:"autoplayNextEpisode"`
}

type User struct {
	ID        bson.ObjectID   `bson:"_id,omitempty" json:"_id,omitempty"`
	Name      string          `bson:"name" json:"name"`
	Email     string          `bson:"email" json:"email"`
	Password  string          `bson:"password" json:"-"`
	Role      string          `bson:"role" json:"role"`
	Watchlist []bson.ObjectID `bson:"watchlist" json:"watchlist"`
	Settings  UserSettings    `bson:"settings" json:"settings"`
	CreatedAt time.Time       `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time       `bson:"updatedAt" json:"updatedAt"`
}

type SystemConfig struct {
	ID              bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	DownloadsEnabled bool          `bson:"downloadsEnabled" json:"downloadsEnabled"`
	CastingEnabled   bool          `bson:"castingEnabled" json:"castingEnabled"`
	NotificationsOn  bool          `bson:"notificationsOn" json:"notificationsOn"`
	TrailerAutoplay  bool          `bson:"trailerAutoplay" json:"trailerAutoplay"`
	CommentsEnabled  bool          `bson:"commentsEnabled" json:"commentsEnabled"`
	UpdatedAt       time.Time     `bson:"updatedAt" json:"updatedAt"`
}

type VideoJob struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	MovieID   bson.ObjectID `bson:"movieId" json:"movieId"`
	InputURL  string        `bson:"inputUrl" json:"inputUrl"`
	Status    string        `bson:"status" json:"status"` // PENDING, PROCESSING, COMPLETED, FAILED
	Error     string        `bson:"error,omitempty" json:"error,omitempty"`
	Progress  int           `bson:"progress" json:"progress"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time     `bson:"updatedAt" json:"updatedAt"`
}

type Episode struct {
	Number   int    `bson:"number" json:"number"`
	Title    string `bson:"title" json:"title"`
	Duration string `bson:"duration" json:"duration"`
	VideoURL string `bson:"videoUrl" json:"videoUrl"`
}

type Season struct {
	Number   int       `bson:"number" json:"number"`
	Title    string    `bson:"title" json:"title"`
	Episodes []Episode `bson:"episodes" json:"episodes"`
}

type Movie struct {
	ID            bson.ObjectID   `bson:"_id,omitempty" json:"_id,omitempty"`
	Title         string          `bson:"title" json:"title"`
	Description   string          `bson:"description" json:"description"`
	PosterURL     string          `bson:"posterUrl" json:"posterUrl"`
	BackdropURL   string          `bson:"backdropUrl" json:"backdropUrl"`
	VideoURL      string          `bson:"videoUrl" json:"videoUrl"`
	Duration      string          `bson:"duration" json:"duration"`
	Year          int             `bson:"year" json:"year"`
	Genre         []string        `bson:"genre" json:"genre"`
	Rating        float64         `bson:"rating" json:"rating"`
	IsTrending    bool            `bson:"isTrending" json:"isTrending"`
	IsFeatured    bool            `bson:"isFeatured" json:"isFeatured"`
	ContentType   string          `bson:"contentType" json:"contentType"`
	TrailerURL    string          `bson:"trailerUrl" json:"trailerUrl"`
	IsPublished   bool            `bson:"isPublished" json:"isPublished"`
	NotifyUsers   []bson.ObjectID `bson:"notifyUsers" json:"notifyUsers"`
	ContentRating string          `bson:"contentRating" json:"contentRating"`
	IsTvShow      bool            `bson:"isTvShow" json:"isTvShow"`
	Seasons       []Season        `bson:"seasons" json:"seasons"`
	CreatedAt     time.Time       `bson:"createdAt" json:"createdAt"`
	UpdatedAt     time.Time       `bson:"updatedAt" json:"updatedAt"`
}

type Category struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	Name      string        `bson:"name" json:"name"`
	Order     int           `bson:"order" json:"order"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time     `bson:"updatedAt" json:"updatedAt"`
}

type HomeSection struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	Title     string        `bson:"title" json:"title"`
	Type      string        `bson:"type" json:"type"`
	Genre     string        `bson:"genre,omitempty" json:"genre,omitempty"`
	Order     int           `bson:"order" json:"order"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time     `bson:"updatedAt" json:"updatedAt"`
}

type Notification struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	User      bson.ObjectID `bson:"user" json:"user"`
	Title     string        `bson:"title" json:"title"`
	Message   string        `bson:"message" json:"message"`
	Movie     bson.ObjectID `bson:"movie,omitempty" json:"movie,omitempty"`
	IsRead    bool          `bson:"isRead" json:"isRead"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time     `bson:"updatedAt" json:"updatedAt"`
}
