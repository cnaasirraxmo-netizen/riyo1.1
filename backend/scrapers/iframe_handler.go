package scrapers

import (
	"regexp"
	"strings"
)

var iframeRe = regexp.MustCompile(`(?i)<iframe.*?src=["'](.*?)["']`)

func ExtractIframes(html string) []string {
	matches := iframeRe.FindAllStringSubmatch(html, -1)

	var urls []string
	for _, m := range matches {
		if len(m) > 1 {
			u := m[1]
			if strings.HasPrefix(u, "//") {
				u = "https:" + u
			}
			urls = append(urls, u)
		}
	}
	return urls
}
