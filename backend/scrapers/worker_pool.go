package scrapers

import (
	"context"
	"sync"
)

type WorkerTask struct {
	URL      string
	ScrapeFn func(string) ([]string, error)
}

type WorkerResult struct {
	URL     string
	Sources []string
	Error   error
}

func RunWorkerPool(ctx context.Context, tasks []WorkerTask, maxConcurrent int) []WorkerResult {
	taskChan := make(chan WorkerTask, len(tasks))
	resultChan := make(chan WorkerResult, len(tasks))
	var wg sync.WaitGroup

	// Fill tasks
	for _, t := range tasks {
		taskChan <- t
	}
	close(taskChan)

	// Start workers
	for i := 0; i < maxConcurrent; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for t := range taskChan {
				select {
				case <-ctx.Done():
					resultChan <- WorkerResult{URL: t.URL, Error: ctx.Err()}
					return
				default:
					sources, err := t.ScrapeFn(t.URL)
					resultChan <- WorkerResult{URL: t.URL, Sources: sources, Error: err}
				}
			}
		}()
	}

	wg.Wait()
	close(resultChan)

	var results []WorkerResult
	for r := range resultChan {
		results = append(results, r)
	}
	return results
}
