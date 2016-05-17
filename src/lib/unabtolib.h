// Library is not re-entrant
#ifndef UNABTOLIB_H_
#define UNABTOLIB_H_

#include <unabto/unabto_app.h>

// Returns the currently implemented version of uNabto.
char* unabtoVersion();

// Defines a configuration of uNabto.
struct UnabtoConfig {
  // The id of the server. This has to be unique.
  char* id;
  // The preshared key of the secure connection.
  char* presharedKey;
};
typedef struct UnabtoConfig UnabtoConfig;

// Sets a new configuration.
void unabtoConfigure(UnabtoConfig* config);

// Init and start the uNabto server with the specified configuration
int unabtoInit();

// Close the uNabto server.
void unabtoClose();

// Gives the uNabto a chance to process any external events, and invoke
// callbacks for any new event. This has to be called at least every
// 10 milliseconds to prevent communication issues.
void unabtoTick();

// Registers a new event handler callback function.
// No more than MAX_EVENT_HANDLERS handlers may be set.
#define MAX_EVENT_HANDLERS 32
typedef application_event_result (*unabtoEventHandler)(
    application_request* request, buffer_read_t* read_buffer,
    buffer_write_t* write_buffer);
int unabtoRegisterEventHandler(int queryId, unabtoEventHandler handler);

#endif  // UNABTOLIB_H_
