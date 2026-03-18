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
	internal_services "github.com/riyobox/backend/internal/services" // Import the new internal services
	"github.com/riyobox/backend/services"
	"github.com/riyobox/backend/utils"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

var MetadataSvc *services.MetadataService

func GetHome(c *gin.Context) {
	cached, err := cache.GetOrSetCache("home_data", cache.TrendingTTL, func() (interface{}, error) {
		collection := db.DB.Collection("movies")

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
		}

		opts := options.Find().SetLimit(10).SetSort(bson.M{"createdAt": -1}).SetProjection(projection)

		cursor, _ := collection.Find(context.TODO(), bson.M{"isTrending": true, "isTvShow": false, "isPublished": true}, opts)
		cursor.All(context.TODO(), &trendingMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTvShow": false, "isPublished": true}, opts)
		cursor.All(context.TODO(), &popularMovies)

		optsRating := options.Find().SetLimit(10).SetSort(bson.M{"rating": -1}).SetProjection(projection)
		cursor, _ = collection.Find(context.TODO(), bson.M{"isTvShow": false, "isPublished": true}, optsRating)
		cursor.All(context.TODO(), &topRatedMovies)

		cursor, _ = collection.Find(context.TODO(), bson.M{"isTrending": true, "isTvShow": true, "isPublished": true}, opts)
		cursor.All(context.TODO(), &trendingTV)

		return gin.H{
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

	// Detect if it's an HLS manifest
	contentType := resp.Header.Get("Content-Type")
	isM3U8 := strings.Contains(targetURL, ".m3u8") ||
		strings.Contains(contentType, "mpegurl") ||
		strings.Contains(contentType, "x-mpegURL")

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

	if movie.TMDbID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Movie not found"})
		return
	}

	cacheKey := fmt.Sprintf("movie_sources_%d", movie.TMDbID)
	cached, err := cache.GetOrSetCache(cacheKey, cache.SourcesTTL, func() (interface{}, error) {
		// Use the new ProviderService for deep extraction
		newSources := internal_services.CallProviders(movie.TMDbID, movie.Title, movie.IsTvShow, 0, 0)

		// Map new model back to old model for compatibility with current frontend/proxy
		var sources []models.StreamSource
		for _, ns := range newSources {
			sources = append(sources, models.StreamSource{
				URL:      ns.URL,
				Quality:  ns.Quality,
				Provider: ns.Provider,
				Type:     ns.Type,
				Label:    fmt.Sprintf("%s (%s)", ns.Provider, ns.Quality),
			})
		}

		subtitles := utils.GetSubtitles(movie.TMDbID, movie.IsTvShow, 0, 0)

		return gin.H{
			"sources":   sources,
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

	if movie.TMDbID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Not found"})
		return
	}

	cacheKey := fmt.Sprintf("tv_sources_%d_%d_%d", movie.TMDbID, season, episode)
	cached, err := cache.GetOrSetCache(cacheKey, cache.SourcesTTL, func() (interface{}, error) {
		// Use the new ProviderService for deep extraction
		newSources := internal_services.CallProviders(movie.TMDbID, movie.Title, true, season, episode)

		// Map new model back to old model for compatibility
		var sources []models.StreamSource
		for _, ns := range newSources {
			sources = append(sources, models.StreamSource{
				URL:      ns.URL,
				Quality:  ns.Quality,
				Provider: ns.Provider,
				Type:     ns.Type,
				Label:    fmt.Sprintf("%s (%s)", ns.Provider, ns.Quality),
			})
		}

		subtitles := utils.GetSubtitles(movie.TMDbID, true, season, episode)

		return gin.H{
			"sources":   sources,
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
