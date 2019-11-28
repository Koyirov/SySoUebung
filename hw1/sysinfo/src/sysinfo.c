#include <stdio.h>
#include <sys/sysinfo.h>
#include <unistd.h>

int main() {

    struct sysinfo info;
    size_t len = 20;    
    char hostname[len];        
    
    int res = sysinfo(&info);
    if( res != 0){
        printf("Ein Fehler aufgetreten\n");
    }
    
    int res1 = gethostname(hostname, len);
    if(res1 != 0){
        printf("Ein Fehler aufgetreten\n");
    }

    printf("Hostname: %s\n", hostname);
    printf("Uptime: %ld s\n", info.uptime);
    printf("Process count: %lu\n", info.procs);
    printf("Total RAM: %lu\n", info.totalram);
    printf("Free RAM: %lu\n", info.freeram);
    printf("Page size: %d\n", info.mem_unit);
    
    return 0;
}

