#define __LIBRARY__  
#include <unistd.h>  
#include <linux/mm.h>  
#include <linux/sched.h>  
#include <asm/system.h>  
#include <linux/kernel.h>  
#define ENOMEM      12  
#define EINVAL      22  
int vector[20]={0};  
int sys_shmget(key_t key, size_t size){  
        int free;  
        if(vector[key]!=0) return vector[key];  
        else{    
                if(size > 1024*4) return -EINVAL; else;  
                if(!(free = get_free_page())) return -ENOMEM;     
                else vector[key] = free;   
                return vector[key];  
        }     
}  
  
void* sys_shmat(int shmid, const void *shmaddr){  
        if(!shmid) return -EINVAL;  
        put_page(shmid, current->start_code + current->brk);  
        return current->brk;  
} 