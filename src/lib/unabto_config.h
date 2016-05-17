#ifndef _UNABTO_CONFIG_H_
#define _UNABTO_CONFIG_H_

// This header contains the specific Nabto settings for this project.
// All available settings can be read about in "unabto_config_defaults.h".
// The default value will be used if a specific setting is not set here.

#define NABTO_ENABLE_STREAM                         0

#define NABTO_ENABLE_LOGGING                        1
#define NABTO_LOG_SEVERITY_FILTER NABTO_LOG_SEVERITY_LEVEL_INFO

#define NABTO_ENABLE_REMOTE_CONNECTION              1
#define NABTO_ENABLE_LOCAL_CONNECTION               1

#define NABTO_ENABLE_DNS_FALLBACK                   1

#endif // _UNABTO_CONFIG_H_
