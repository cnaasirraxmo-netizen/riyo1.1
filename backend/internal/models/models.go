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
	ID          bson.ObjectID   `bson:"_id,omitempty" json:"_id,omitempty"`
	Name        string          `bson:"name" json:"name"`
	Email       string          `bson:"email" json:"email"`
	PhoneNumber string          `bson:"phoneNumber" json:"phoneNumber"`
	Password    string          `bson:"password" json:"-"`
	Role        string          `bson:"role" json:"role"`
	Watchlist   []bson.ObjectID `bson:"watchlist" json:"watchlist"`
	FCMTokens   []string        `bson:"fcmTokens" json:"fcmTokens"`
	Settings    UserSettings    `bson:"settings" json:"settings"`
	DeviceInfo  DeviceInfo      `bson:"deviceInfo" json:"deviceInfo"`
	Location    LocationData    `bson:"location" json:"location"`
	CreatedAt   time.Time       `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time       `bson:"updatedAt" json:"updatedAt"`
}

type DeviceInfo struct {
	Model     string `bson:"model" json:"model"`
	OS        string `bson:"os" json:"os"`
	IP        string `bson:"ip" json:"ip"`
	DeviceID  string `bson:"deviceId" json:"deviceId"`
	UserAgent string `bson:"userAgent" json:"userAgent"`
}

type LocationData struct {
	Country string `bson:"country" json:"country"`
	City    string `bson:"city" json:"city"`
	Lat     string `bson:"lat" json:"lat"`
	Lon     string `bson:"lon" json:"lon"`
}

type UsageLog struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	UserID    bson.ObjectID `bson:"userId" json:"userId"`
	Screen    string        `bson:"screen" json:"screen"`
	Feature   string        `bson:"feature" json:"feature"`
	Duration  int           `bson:"duration" json:"duration"` // in seconds
	Timestamp time.Time     `bson:"timestamp" json:"timestamp"`
}

type Review struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	UserID    bson.ObjectID `bson:"userId" json:"userId"`
	MovieID   bson.ObjectID `bson:"movieId" json:"movieId"`
	Rating    float64       `bson:"rating" json:"rating"`
	Comment   string        `bson:"comment" json:"comment"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
}

type SystemConfig struct {
	ID               bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	DownloadsEnabled bool          `bson:"downloadsEnabled" json:"downloadsEnabled"`
	CastingEnabled   bool          `bson:"castingEnabled" json:"castingEnabled"`
	NotificationsOn  bool          `bson:"notificationsOn" json:"notificationsOn"`
	TrailerAutoplay  bool          `bson:"trailerAutoplay" json:"trailerAutoplay"`
	CommentsEnabled  bool          `bson:"commentsEnabled" json:"commentsEnabled"`
	SportsEnabled    bool          `bson:"sportsEnabled" json:"sportsEnabled"`
	KidsEnabled      bool          `bson:"kidsEnabled" json:"kidsEnabled"`
	UpdatedAt        time.Time     `bson:"updatedAt" json:"updatedAt"`
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

type PasswordReset struct {
	ID        bson.ObjectID `bson:"_id,omitempty" json:"_id,omitempty"`
	Email     string        `bson:"email" json:"email"`
	Code      string        `bson:"code" json:"code"`
	ExpiresAt time.Time     `bson:"expiresAt" json:"expiresAt"`
	IsUsed    bool          `bson:"isUsed" json:"isUsed"`
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
}

type Episode struct {
	Number   int            `bson:"number" json:"number"`
	Title    string         `bson:"title" json:"title"`
	Duration string         `bson:"duration" json:"duration"`
	VideoURL string         `bson:"videoUrl" json:"videoUrl"` // Direct link or fallback
	Sources  []StreamSource `bson:"sources" json:"sources"`
}

type Season struct {
	Number   int       `bson:"number" json:"number"`
	Title    string    `bson:"title" json:"title"`
	Episodes []Episode `bson:"episodes" json:"episodes"`
}

type StreamSource struct {
	Label    string `bson:"label" json:"label"`       // Primary, Backup 1, etc.
	URL      string `bson:"url" json:"url"`           // URL to the video
	Type     string `bson:"type" json:"type"`         // direct, hls, dash, embed
	Provider string `bson:"provider" json:"provider"` // local, url, youtube, vidsrc, 2embed
	Quality  string `bson:"quality" json:"quality"`   // 1080p, 720p, etc.
}

type Movie struct {
	ID            bson.ObjectID    `bson:"_id,omitempty" json:"_id,omitempty"`
	TMDbID        int              `bson:"tmdbId" json:"tmdbId"`
	Title         string           `bson:"title" json:"title"`
	ShortDesc     string           `bson:"shortDesc" json:"shortDesc"`
	Description   string           `bson:"description" json:"description"`
	PosterURL     string           `bson:"posterUrl" json:"posterUrl"`
	BannerURL     string           `bson:"bannerUrl" json:"bannerUrl"`
	ThumbnailURL  string           `bson:"thumbnailUrl" json:"thumbnailUrl"`
	VideoURL      string           `bson:"videoUrl" json:"videoUrl"` // For backward compatibility
	Sources       []StreamSource   `bson:"sources" json:"sources"`
	TrailerURL    string           `bson:"trailerUrl" json:"trailerUrl"`
	TrailerType   string           `bson:"trailerType" json:"trailerType"` // local, youtube, link
	Duration      int              `bson:"duration" json:"duration"`       // in minutes
	Year          int              `bson:"year" json:"year"`
	Genre         []string         `bson:"genre" json:"genre"`
	Language      string           `bson:"language" json:"language"`
	Country       string           `bson:"country" json:"country"`
	Director      string           `bson:"director" json:"director"`
	Cast          []string         `bson:"cast" json:"cast"`
	Rating        float64          `bson:"rating" json:"rating"`
	AgeRating     string           `bson:"ageRating" json:"ageRating"` // 13+, 18+, etc.
	Tags          []string         `bson:"tags" json:"tags"`
	Quality       string           `bson:"quality" json:"quality"`       // HD, Full HD, 4K
	Status        string           `bson:"status" json:"status"`         // published, draft, coming_soon, premium, trailer_only
	AccessType    string           `bson:"accessType" json:"accessType"` // free, premium, subscription
	Views         int64            `bson:"views" json:"views"`
	DailyViews    map[string]int64 `bson:"dailyViews" json:"dailyViews"` // date string -> count
	IsTrending    bool             `bson:"isTrending" json:"isTrending"`
	IsFeatured    bool             `bson:"isFeatured" json:"isFeatured"`
	IsTvShow      bool             `bson:"isTvShow" json:"isTvShow"`
	IsKidsContent bool             `bson:"isKidsContent" json:"isKidsContent"`
	IsPublished   bool             `bson:"isPublished" json:"isPublished"`
	Seasons       []Season         `bson:"seasons" json:"seasons"`
	NotifyUsers   []bson.ObjectID  `bson:"notifyUsers" json:"notifyUsers"`
	ContentRating string           `bson:"contentRating" json:"contentRating"` // Deprecated but kept for compat
	CreatedAt     time.Time        `bson:"createdAt" json:"createdAt"`
	UpdatedAt     time.Time        `bson:"updatedAt" json:"updatedAt"`
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
	User      bson.ObjectID `bson:"user,omitempty" json:"user,omitempty"` // If empty, it's a broadcast
	Title     string        `bson:"title" json:"title"`
	Message   string        `bson:"message" json:"message"`
	Movie     bson.ObjectID `bson:"movie,omitempty" json:"movie,omitempty"`
	IsRead    bool          `bson:"isRead" json:"isRead"`
	Type      string        `bson:"type" json:"type"` // e.g., "welcome", "admin", "movie_release"
	Status    string        `bson:"status" json:"status"` // "sent", "failed"
	CreatedAt time.Time     `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time     `bson:"updatedAt" json:"updatedAt"`
}
