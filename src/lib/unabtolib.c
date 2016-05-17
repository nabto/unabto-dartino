#include "unabtolib.h"

#include "unabto/unabto_common_main.h"
#include "unabto_version.h"

// The uNabto main config structure.
nabto_main_setup* nms;

char* unabtoVersion() {
  static char version[21];
  sprintf(version, "%u.%u", RELEASE_MAJOR, RELEASE_MINOR);
  return version;
}

void unabtoConfigure(UnabtoConfig* config) {
  setbuf(stdout, NULL);
   
  // Set uNabto to default values.
  nms = unabto_init_context();

  // Set the uNabto ID.
  nms->id = strdup(config->id);

  // Enable encryption.
  nms->secureAttach = true;
  nms->secureData = true;
  nms->cryptoSuite = CRYPT_W_AES_CBC_HMAC_SHA256;

  // Set the pre-shared key from a hexadecimal string.
  size_t i, pskLen = strlen(config->presharedKey);
  for (i = 0; i < pskLen / 2 && i < PRE_SHARED_KEY_SIZE; i++)
    sscanf(&config->presharedKey[2 * i], "%02hhx", &nms->presharedKey[i]);
}

int unabtoInit() { return (nms != NULL && unabto_init()) ? 0 : -1; }

void unabtoClose() { unabto_close(); }

void unabtoTick() { unabto_tick(); }

struct handler {
  int queryId;
  unabtoEventHandler handler;
};
struct handler currentHandlers[MAX_EVENT_HANDLERS];
int nextHandlerSlot = 0;
int unabtoRegisterEventHandler(int queryId, unabtoEventHandler handler) {
  if (nextHandlerSlot >= MAX_EVENT_HANDLERS) return -1;
  currentHandlers[nextHandlerSlot].queryId = queryId;
  currentHandlers[nextHandlerSlot].handler = handler;
  nextHandlerSlot++;
  return 0;
}

application_event_result application_event(application_request* request,
                                           buffer_read_t* read_buffer,
                                           buffer_write_t* write_buffer) {
  for (int i = 0; i < nextHandlerSlot; i++)
    if (currentHandlers[i].queryId == request->queryId)
      return currentHandlers[i].handler(request, read_buffer, write_buffer);
  return AER_REQ_INV_QUERY_ID;
}
