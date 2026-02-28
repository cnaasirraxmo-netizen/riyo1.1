#ifndef RIYO_PLAYER_H
#define RIYO_PLAYER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*RiyoEventCallback)(int event_type, const char* data);

void* riyo_create_player(const char* url, RiyoEventCallback callback);
void riyo_play(void* player);
void riyo_pause(void* player);
void riyo_seek(void* player, long ms);
long riyo_get_position(void* player);
long riyo_get_duration(void* player);
void riyo_set_surface(void* player, void* surface_handle);
void riyo_destroy_player(void* player);

// Event Types
#define RIYO_EVENT_PLAYING 1
#define RIYO_EVENT_PAUSED 2
#define RIYO_EVENT_BUFFERING_START 3
#define RIYO_EVENT_BUFFERING_STOP 4
#define RIYO_EVENT_QUALITY_CHANGE 5
#define RIYO_EVENT_ERROR 6

#ifdef __cplusplus
}
#endif

#endif // RIYO_PLAYER_H
