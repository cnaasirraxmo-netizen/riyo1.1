package services

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"sort"
	"strings"
	"sync"
	"time"
)

type ProviderConfig struct {
	Name           string `json:"name"`
	URLPattern     string `json:"url_pattern"`
	TVPattern      string `json:"tv_pattern"`
	Type           string `json:"type"` // movie, tv, both
	Priority       int    `json:"priority"`
	Enabled        bool   `json:"enabled"`
	TimeoutSeconds int    `json:"timeout_seconds"`
}

type ProviderRegistry struct {
	providers []ProviderConfig
	mu        sync.RWMutex
	filePath  string
}

var (
	GlobalRegistry *ProviderRegistry
	registryOnce   sync.Once
)

func InitProviderRegistry(filePath string) error {
	var err error
	registryOnce.Do(func() {
		GlobalRegistry = &ProviderRegistry{
			filePath: filePath,
		}
		err = GlobalRegistry.Load()
		if err == nil {
			go GlobalRegistry.watch()
		}
	})
	return err
}

func (pr *ProviderRegistry) Load() error {
	data, err := ioutil.ReadFile(pr.filePath)
	if err != nil {
		return err
	}

	var providers []ProviderConfig
	if err := json.Unmarshal(data, &providers); err != nil {
		return err
	}

	// Filter enabled and sort by priority
	var active []ProviderConfig
	for _, p := range providers {
		if p.Enabled {
			active = append(active, p)
		}
	}

	sort.Slice(active, func(i, j int) bool {
		return active[i].Priority < active[j].Priority
	})

	pr.mu.Lock()
	pr.providers = active
	pr.mu.Unlock()

	log.Printf("[REGISTRY] Loaded %d active providers", len(active))
	return nil
}

func (pr *ProviderRegistry) GetProviders(contentType string) []ProviderConfig {
	pr.mu.RLock()
	defer pr.mu.RUnlock()

	var filtered []ProviderConfig
	for _, p := range pr.providers {
		if p.Type == "both" || p.Type == contentType {
			filtered = append(filtered, p)
		}
	}
	return filtered
}

func (pr *ProviderRegistry) StartHotReload(interval time.Duration) {
	// watch() handles it, keeping for API compatibility
}

func (pr *ProviderRegistry) watch() {
	ticker := time.NewTicker(30 * time.Second)
	var lastModified time.Time

	for range ticker.C {
		info, err := os.Stat(pr.filePath)
		if err != nil {
			continue
		}

		if info.ModTime().After(lastModified) {
			if err := pr.Load(); err == nil {
				lastModified = info.ModTime()
			}
		}
	}
}

func GenerateURL(p ProviderConfig, tmdbID string, season, episode int) (string, error) {
	var pattern string
	if season > 0 || episode > 0 {
		pattern = p.TVPattern
	} else {
		pattern = p.URLPattern
	}

	if pattern == "" {
		return "", fmt.Errorf("no pattern for content type")
	}

	url := pattern
	url = strings.ReplaceAll(url, "{tmdb_id}", tmdbID)
	url = strings.ReplaceAll(url, "{season}", fmt.Sprintf("%d", season))
	url = strings.ReplaceAll(url, "{episode}", fmt.Sprintf("%d", episode))
	url = strings.ReplaceAll(url, "{s}", fmt.Sprintf("%d", season))
	url = strings.ReplaceAll(url, "{e}", fmt.Sprintf("%d", episode))

	return url, nil
}
