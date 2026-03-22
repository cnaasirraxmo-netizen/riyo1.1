package handlers

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"time"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/riyobox/backend/cache"
	"github.com/riyobox/backend/internal/db"
	"github.com/riyobox/backend/internal/models"
	"github.com/riyobox/backend/services"
	"github.com/riyobox/backend/scrapers"
	"github.com/riyobox/backend/utils"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

var MetadataSvc *services.MetadataService
var VideoExt *services.VideoExtractor

func GetHome(c *gin.Context) {
	cached, err := cache.GetOrSetCache("home_data", cache.TrendingTTL, func() (interface{}, error) {
		collection := db.DB.Collection("movies")

		adminMovies := []models.Movie{}
		trendingMovies := []models.Movie{}
		popularMovies := []models.Movie{}
		topRatedMovies := []models.Movie{}
		trendingTV := []models.Movie{}

		projection := bson.M{
			"title":       1,
			"posterUrl":   1,
			"backdropUrl": 1,
			"year":        1,
			"rating":      1,
			"genre":       1,
			"contentType": 1,
			"isTvShow":    1,
			"isPublished": 1,
			"status":      1,
			"accessType":  1,
			"videoUrl":    1,
			"directUrl":   1,
			"sourceType":  1,
		}

		opts := options.Find().SetLimit(10).SetSort(bson.M{"createdAt": -1}).SetProjection(projection)

		cursor, _ := collection.Find(context.TODO(), bson.M{"sourceType": "admin", "isPublished": true}, opts)
		cursor.All(context.TODO(), &adminMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTrending": true, "isTvShow": false, "isPublished": true}, opts)
		cursor.All(context.TODO(), &trendingMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTvShow": false, "isPublished": true}, opts)
		cursor.All(context.TODO(), &popularMovies)

		optsRating := options.Find().SetLimit(10).SetSort(bson.M{"rating": -1}).SetProjection(projection)
		cursor, _ = collection.Find(context.TODO(), bson.M{"isTvShow": false, "isPublished": true}, optsRating)
		cursor.All(context.TODO(), &topRatedMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTrending": true, "isTvShow": true, "isPublished": true}, opts)
		cursor.All(context.TODO(), &trendingTV)

		return gin.H{
			"adminMovies":    adminMovies,
			"trendingMovies": trendingMovies,
			"popularMovies":  popularMovies,
			"topRatedMovies": topRatedMovies,
			"latestMovies":   popularMovies, // Simplified
			"trendingTV":     trendingTV,
			"popularTV":      trendingTV, // Simplified
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Wrap sources with proxy URLs outside of cache to handle dynamic hosts correctly
	responseMap := make(map[string]interface{})
	if m, ok := cached.(map[string]interface{}); ok {
		for k, v := range m {
			responseMap[k] = v
		}
	} else if h, ok := cached.(gin.H); ok {
		for k, v := range h {
			responseMap[k] = v
		}
	}

	if sourcesData, ok := responseMap["sources"]; ok {
		var sources []models.StreamSource
		b, _ := json.Marshal(sourcesData)
		json.Unmarshal(b, &sources)

		proxiedSources := make([]models.StreamSource, len(sources))
		baseURL := GetBaseURL(c.Request.Host)
		for i, s := range sources {
			if s.Type == "embed" {
				proxiedSources[i] = s
				continue
			}

			// Detect if it's already proxied to avoid double proxying
			if strings.Contains(s.URL, "/api/v1/stream/") {
				proxiedSources[i] = s
				continue
			}

			encodedURL := base64.URLEncoding.EncodeToString([]byte(s.URL))
			s.URL = fmt.Sprintf("%s/api/v1/stream/%s", baseURL, encodedURL)
			proxiedSources[i] = s
		}
		responseMap["sources"] = proxiedSources
	}

	c.JSON(http.StatusOK, responseMap)
}

func ProxyStream(c *gin.Context) {
	encodedURL := c.Param("id")
	decodedURLBytes, err := base64.URLEncoding.DecodeString(encodedURL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid stream ID"})
		return
	}
	targetURL := string(decodedURLBytes)

	// Create request to original source
	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create stream request"})
		return
	}

	// Forward important headers from the client (like Range for seeking)
	for name, values := range c.Request.Header {
		if name == "Range" || name == "User-Agent" || name == "Referer" || name == "Origin" {
			for _, value := range values {
				req.Header.Add(name, value)
			}
		}
	}

	// Some providers require a valid Referer to serve content
	if req.Header.Get("Referer") == "" {
		req.Header.Set("Referer", targetURL)
	}

	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	fmt.Printf("Proxying request to: %s\n", targetURL)
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Proxy error: %v for %s\n", err, targetURL)
		c.JSON(http.StatusBadGateway, gin.H{"message": "Failed to reach source domain"})
		return
	}
	defer resp.Body.Close()

	// Detect if it's an HLS manifest or DASH
	contentType := resp.Header.Get("Content-Type")
	isM3U8 := strings.Contains(targetURL, ".m3u8") ||
		strings.Contains(contentType, "mpegurl") ||
		strings.Contains(contentType, "x-mpegURL") ||
		strings.Contains(contentType, "vnd.apple.mpegurl")

	isDASH := strings.Contains(targetURL, ".mpd") ||
		strings.Contains(contentType, "dash+xml")

	if isM3U8 {
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to read manifest"})
			return
		}

		rewrittenManifest := rewriteHLSManifest(string(body), targetURL, c.Request.Host)

		// Copy headers back to the client, but update Content-Length
		for name, values := range resp.Header {
			if name != "Content-Length" {
				for _, value := range values {
					c.Header(name, value)
				}
			}
		}
		c.Header("Content-Length", strconv.Itoa(len(rewrittenManifest)))
		c.String(resp.StatusCode, rewrittenManifest)
	} else if isDASH {
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to read manifest"})
			return
		}

		rewrittenManifest := rewriteDASHManifest(string(body), targetURL, c.Request.Host)

		for name, values := range resp.Header {
			if name != "Content-Length" {
				for _, value := range values {
					c.Header(name, value)
				}
			}
		}
		c.Header("Content-Length", strconv.Itoa(len(rewrittenManifest)))
		c.String(resp.StatusCode, rewrittenManifest)
	} else {
		// Copy headers back to the client
		for name, values := range resp.Header {
			for _, value := range values {
				c.Header(name, value)
			}
		}
		c.Status(resp.StatusCode)
		io.Copy(c.Writer, resp.Body)
	}
}

func rewriteHLSManifest(manifest, originalURL, requestHost string) string {
	baseURL := os.Getenv("API_BASE_URL")
	if baseURL == "" {
		scheme := "http"
		if strings.Contains(requestHost, "localhost") {
			scheme = "http"
		} else {
			scheme = "https"
		}
		baseURL = fmt.Sprintf("%s://%s", scheme, requestHost)
	}

	// Get base URL of the manifest to resolve relative paths
	parsedURL, _ := url.Parse(originalURL)

	// Normalize line endings
	lineSeparator := "\n"
	if strings.Contains(manifest, "\r\n") {
		lineSeparator = "\r\n"
	}
	manifest = strings.ReplaceAll(manifest, "\r\n", "\n")
	lines := strings.Split(manifest, "\n")

	outputLines := make([]string, len(lines))
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			outputLines[i] = line
			continue
		}

		if strings.HasPrefix(trimmed, "#") {
			// Check for URI in tags like #EXT-X-KEY or #EXT-X-MEDIA
			if strings.Contains(trimmed, "URI=") {
				re := regexp.MustCompile(`URI=["'](.*?)["']`)
				outputLines[i] = re.ReplaceAllStringFunc(line, func(match string) string {
					submatch := re.FindStringSubmatch(match)
					if len(submatch) > 1 {
						resolvedURL := resolveURL(submatch[1], parsedURL)
						encodedURL := base64.URLEncoding.EncodeToString([]byte(resolvedURL))
						return fmt.Sprintf(`URI="%s/api/v1/stream/%s"`, baseURL, encodedURL)
					}
					return match
				})
			} else {
				outputLines[i] = line
			}
		} else {
			// It's a URL (segment or sub-playlist)
			resolvedURL := resolveURL(trimmed, parsedURL)
			encodedURL := base64.URLEncoding.EncodeToString([]byte(resolvedURL))
			// Keep the original indentation/spacing
			outputLines[i] = strings.Replace(line, trimmed, fmt.Sprintf("%s/api/v1/stream/%s", baseURL, encodedURL), 1)
		}
	}

	return strings.Join(outputLines, lineSeparator)
}

func rewriteDASHManifest(manifest, originalURL, requestHost string) string {
	baseURL := os.Getenv("API_BASE_URL")
	if baseURL == "" {
		scheme := "https"
		if strings.Contains(requestHost, "localhost") {
			scheme = "http"
		}
		baseURL = fmt.Sprintf("%s://%s", scheme, requestHost)
	}

	parsedURL, _ := url.Parse(originalURL)

	// DASH manifests are XML. We need to find BaseURL tags and segment URLs.
	// This is a simplified regex approach for common DASH structures.

	// 1. Rewrite BaseURL tags
	reBaseURL := regexp.MustCompile(`(?i)<BaseURL>(.*?)</BaseURL>`)
	manifest = reBaseURL.ReplaceAllStringFunc(manifest, func(match string) string {
		submatch := reBaseURL.FindStringSubmatch(match)
		if len(submatch) > 1 {
			resolvedURL := resolveURL(submatch[1], parsedURL)
			encodedURL := base64.URLEncoding.EncodeToString([]byte(resolvedURL))
			return fmt.Sprintf("<BaseURL>%s/api/v1/stream/%s/</BaseURL>", baseURL, encodedURL)
		}
		return match
	})

	// 2. Rewrite media/initialization attributes in SegmentTemplate
	reAttribs := regexp.MustCompile(`(?i)(media|initialization|sourceURL)=["'](.*?)["']`)
	manifest = reAttribs.ReplaceAllStringFunc(manifest, func(match string) string {
		submatch := reAttribs.FindStringSubmatch(match)
		if len(submatch) > 2 {
			attrName := submatch[1]
			attrVal := submatch[2]

			// Don't encode if it's already an absolute URL through our proxy
			if strings.Contains(attrVal, "/api/v1/stream/") {
				return match
			}

			resolvedURL := resolveURL(attrVal, parsedURL)
			encodedURL := base64.URLEncoding.EncodeToString([]byte(resolvedURL))
			return fmt.Sprintf(`%s="%s/api/v1/stream/%s"`, attrName, baseURL, encodedURL)
		}
		return match
	})

	return manifest
}

func resolveURL(link string, parsedBase *url.URL) string {
	if strings.HasPrefix(link, "//") {
		return "https:" + link
	}
	u, err := url.Parse(link)
	if err != nil {
		return link
	}
	if u.IsAbs() {
		return link
	}
	if parsedBase == nil {
		return link
	}
	return parsedBase.ResolveReference(u).String()
}

func GetMoviesByFilter(filter bson.M) gin.HandlerFunc {
	return func(c *gin.Context) {
		collection := db.DB.Collection("movies")
		opts := options.Find().SetLimit(20).SetSort(bson.M{"createdAt": -1})

		var results []models.Movie
		cursor, err := collection.Find(context.TODO(), filter, opts)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
			return
		}
		cursor.All(context.TODO(), &results)
		c.JSON(http.StatusOK, results)
	}
}

func GetMovieSources(c *gin.Context) {
	idStr := c.Param("id")
	collection := db.DB.Collection("movies")
	var movie models.Movie

	if id, err := bson.ObjectIDFromHex(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
	} else if tmdbID, err := strconv.Atoi(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&movie)
	}

	if movie.ID.IsZero() {
		c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
		return
	}

	cacheKey := fmt.Sprintf("movie_sources_%s", movie.ID.Hex())
	if movie.TMDbID != 0 {
		cacheKey = fmt.Sprintf("movie_sources_%d", movie.TMDbID)
	}
	cached, err := cache.GetOrSetCache(cacheKey, cache.SourcesTTL, func() (interface{}, error) {
		scrapedSources := VideoExt.ExtractSources(movie.TMDbID, movie.Title, movie.IsTvShow, 0, 0)

		var allSources []models.StreamSource

		// 1. Admin direct VideoURL (Highest Priority)
		if movie.VideoURL != "" {
			allSources = append(allSources, models.StreamSource{
				Label:    "Official Server",
				URL:      movie.VideoURL,
				Type:     VideoExt.DetectType(movie.VideoURL, ""),
				Provider: "admin",
				Quality:  "Auto",
			})
		}

		// 2. Admin specific Sources
		if len(movie.Sources) > 0 {
			allSources = append(allSources, movie.Sources...)
		}

		// 3. Scraped sources
		allSources = append(allSources, scrapedSources...)

		subtitles := utils.GetSubtitles(movie.TMDbID, movie.IsTvShow, 0, 0)

		return gin.H{
			"sources":   allSources,
			"subtitles": subtitles,
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Wrap sources with proxy URLs outside of cache to handle dynamic hosts correctly
	responseMap := make(map[string]interface{})
	if m, ok := cached.(map[string]interface{}); ok {
		for k, v := range m {
			responseMap[k] = v
		}
	} else if h, ok := cached.(gin.H); ok {
		for k, v := range h {
			responseMap[k] = v
		}
	}

	if sourcesData, ok := responseMap["sources"]; ok {
		var sources []models.StreamSource
		b, _ := json.Marshal(sourcesData)
		json.Unmarshal(b, &sources)

		proxiedSources := make([]models.StreamSource, len(sources))
		baseURL := GetBaseURL(c.Request.Host)
		for i, s := range sources {
			if s.Type == "embed" {
				proxiedSources[i] = s
				continue
			}

			if strings.Contains(s.URL, "/api/v1/stream/") {
				proxiedSources[i] = s
				continue
			}

			encodedURL := base64.URLEncoding.EncodeToString([]byte(s.URL))
			s.URL = fmt.Sprintf("%s/api/v1/stream/%s", baseURL, encodedURL)
			proxiedSources[i] = s
		}
		responseMap["sources"] = proxiedSources
	}

	c.JSON(http.StatusOK, responseMap)
}

func GetTVSources(c *gin.Context) {
	idStr := c.Param("id")
	season, _ := strconv.Atoi(c.Param("season"))
	episode, _ := strconv.Atoi(c.Param("episode"))

	collection := db.DB.Collection("movies")
	var movie models.Movie

	if id, err := bson.ObjectIDFromHex(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"_id": id}).Decode(&movie)
	} else if tmdbID, err := strconv.Atoi(idStr); err == nil {
		collection.FindOne(context.TODO(), bson.M{"tmdbId": tmdbID}).Decode(&movie)
	}

	if movie.ID.IsZero() {
		c.JSON(http.StatusNotFound, gin.H{"message": "Not found"})
		return
	}

	cacheKey := fmt.Sprintf("tv_sources_%s_%d_%d", movie.ID.Hex(), season, episode)
	if movie.TMDbID != 0 {
		cacheKey = fmt.Sprintf("tv_sources_%d_%d_%d", movie.TMDbID, season, episode)
	}
	cached, err := cache.GetOrSetCache(cacheKey, cache.SourcesTTL, func() (interface{}, error) {
		scrapedSources := VideoExt.ExtractSources(movie.TMDbID, movie.Title, true, season, episode)

		var allSources []models.StreamSource

		// Find admin episode sources (Highest Priority)
		for _, s := range movie.Seasons {
			if s.Number == season {
				for _, e := range s.Episodes {
					if e.Number == episode {
						if e.VideoURL != "" {
							allSources = append(allSources, models.StreamSource{
								Label:    "Official Server",
								URL:      e.VideoURL,
								Type:     VideoExt.DetectType(e.VideoURL, ""),
								Provider: "admin",
								Quality:  "Auto",
							})
						}
						allSources = append(allSources, e.Sources...)
						break
					}
				}
				break
			}
		}

		allSources = append(allSources, scrapedSources...)

		subtitles := utils.GetSubtitles(movie.TMDbID, true, season, episode)

		return gin.H{
			"sources":   allSources,
			"subtitles": subtitles,
		}, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	// Wrap sources with proxy URLs outside of cache to handle dynamic hosts correctly
	responseMap := make(map[string]interface{})
	if m, ok := cached.(map[string]interface{}); ok {
		for k, v := range m {
			responseMap[k] = v
		}
	} else if h, ok := cached.(gin.H); ok {
		for k, v := range h {
			responseMap[k] = v
		}
	}

	if sourcesData, ok := responseMap["sources"]; ok {
		var sources []models.StreamSource
		b, _ := json.Marshal(sourcesData)
		json.Unmarshal(b, &sources)

		proxiedSources := make([]models.StreamSource, len(sources))
		baseURL := GetBaseURL(c.Request.Host)
		for i, s := range sources {
			if s.Type == "embed" {
				proxiedSources[i] = s
				continue
			}

			if strings.Contains(s.URL, "/api/v1/stream/") {
				proxiedSources[i] = s
				continue
			}

			encodedURL := base64.URLEncoding.EncodeToString([]byte(s.URL))
			s.URL = fmt.Sprintf("%s/api/v1/stream/%s", baseURL, encodedURL)
			proxiedSources[i] = s
		}
		responseMap["sources"] = proxiedSources
	}

	c.JSON(http.StatusOK, responseMap)
}

func GetBaseURL(requestHost string) string {
	baseURL := os.Getenv("API_BASE_URL")
	if baseURL != "" {
		return baseURL
	}
	scheme := "https"
	if strings.Contains(requestHost, "localhost") || strings.Contains(requestHost, "127.0.0.1") {
		scheme = "http"
	}
	return fmt.Sprintf("%s://%s", scheme, requestHost)
}

func SearchMovies(c *gin.Context) {
	query := c.Query("query")

	cacheKey := fmt.Sprintf("search_%s", strings.ReplaceAll(strings.ToLower(query), " ", "_"))
	cached, err := cache.GetOrSetCache(cacheKey, cache.SearchTTL, func() (interface{}, error) {
		collection := db.DB.Collection("movies")

		filter := bson.M{
			"title": bson.M{"$regex": query, "$options": "i"},
		}

		cursor, err := collection.Find(context.TODO(), filter)
		if err != nil {
			return nil, err
		}
		defer cursor.Close(context.TODO())

		var results []models.Movie
		cursor.All(context.TODO(), &results)

		return results, nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, cached)
}

func GetKidsHome(c *gin.Context) {
	collection := db.DB.Collection("movies")

	projection := bson.M{
		"title":       1,
		"posterUrl":   1,
		"year":        1,
		"rating":      1,
		"genre":       1,
		"contentType": 1,
		"isTvShow":    1,
		"isPublished": 1,
	}

	opts := options.Find().SetLimit(50).SetSort(bson.M{"createdAt": -1}).SetProjection(projection)
	filter := bson.M{"isKidsContent": true, "isPublished": true}

	cursor, err := collection.Find(context.TODO(), filter, opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	defer cursor.Close(context.TODO())

	var results []models.Movie
	cursor.All(context.TODO(), &results)

	c.JSON(http.StatusOK, results)
}

func SniffMedia(c *gin.Context) {
	var req struct {
		URL      string `json:"url" binding:"required"`
		Headless bool   `json:"headless"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}

	sniffer := scrapers.NewPlaywrightSniffer()
	if sniffer == nil {
		c.JSON(http.StatusOK, []interface{}{}) // Return empty list instead of error
		return
	}

	results, err := sniffer.Sniff(req.URL, req.Headless, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, results)
}
