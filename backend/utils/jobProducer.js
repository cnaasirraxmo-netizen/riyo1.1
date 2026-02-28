const axios = require('axios');

class JobProducer {
    constructor() {
        this.processingServiceUrl = process.env.VIDEO_PROCESSING_SERVICE_URL || 'http://localhost:5001';
    }

    async emitVideoUploaded(movieData) {
        console.log(`[JobProducer] Emitting video_uploaded event for movie: ${movieData.title}`);

        // Mocking an event emission to Kafka.
        // In a real implementation, we'd use a Kafka client (kafkajs).
        // Here we'll simulate it by calling a webhook or just logging.

        try {
            const jobData = {
                id: movieData._id || Date.now().toString(),
                source_url: movieData.videoUrl,
                target_folder: `/videos/processed/${movieData._id}`,
                resolutions: ['1080p', '720p', '480p', '360p']
            };

            console.log(`[JobProducer] Job Data:`, jobData);

            // Simulating internal service communication
            // await axios.post(`${this.processingServiceUrl}/jobs`, jobData);

            return true;
        } catch (error) {
            console.error(`[JobProducer] Failed to emit event:`, error.message);
            return false;
        }
    }
}

module.exports = new JobProducer();
