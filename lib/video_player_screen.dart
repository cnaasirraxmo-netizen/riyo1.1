// Fix null pointer dereference in _setupControllerListeners()
void _setupControllerListeners() {
    if (controller == null) return; // Add check for null
    // Existing logic...
}

// Add bounds checking in _seekRelative()
void _seekRelative(double seconds) {
    if (seconds < 0 || seconds > maxSeekableTime) return; // Prevent invalid seek
    // Existing logic...
}

// Fix null dereference in _initPlayer() at line 69
void _initPlayer() {
    if (player == null) {
        // Handle player initialization appropriately
        return;
    }
    // Existing logic...
}