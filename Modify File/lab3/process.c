#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/times.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <errno.h>

#define HZ      100


/*
 * �˺������ղ���ռ��CPU��I/Oʱ��
 * last: ����ʵ��ռ��CPU��I/O����ʱ�䣬�����ھ��������е�ʱ�䣬>=0�Ǳ����
 * cpu_time: һ������ռ��CPU��ʱ�䣬>=0�Ǳ����
 * io_time: һ��I/O���ĵ�ʱ�䣬>=0�Ǳ����
 * ���last > cpu_time + io_time�����������ռ��CPU��I/O
 * ����ʱ��ĵ�λΪ��
 */
void cpuio_bound(int last, int cpu_time, int io_time)
{
    struct tms start_time, current_time;
    clock_t utime, stime;
    int sleep_time;

    while (last > 0)
    {
        /* CPU Burst */
        times(&start_time);
        /* ��ʵֻ��t.tms_utime����������CPUʱ�䡣����������ģ��һ��
         * ֻ���û�״̬���е�CPU�󻧣�����for(;;);�������԰�t.tms_stime
         * ���Ϻܺ���*/
        do
        {
            times(&current_time);
            utime = current_time.tms_utime - start_time.tms_utime;
            stime = current_time.tms_stime - start_time.tms_stime;
        } while ( ( (utime + stime) / HZ )  < cpu_time );
        last -= cpu_time;

        if (last <= 0 )
            break;

        /* IO Burst */
        /* ��sleep(1)ģ��1���ӵ�I/O���� */
        sleep_time=0;
        while (sleep_time < io_time)
        {
            sleep(1);
            sleep_time++;
        }
        last -= sleep_time;
    }
}

  
   void main()
  
   {
        pid_t c_p1;
        pid_t c_p2;
        pid_t c_p3;
        pid_t c_p4;
          
          if((c_p1 = fork())==0 )
          {
                  cpuio_bound( 5 , 2 , 2);
          }
          else if((c_p2 = fork())==0)
          {
                 cpuio_bound( 5 , 4 , 0);
          }
          else if((c_p3 = fork())==0)
          {
                  cpuio_bound(5, 0 , 4);
          }
          else if((c_p4 = fork())==0)
          {
                 cpuio_bound( 4 , 2 , 2);
          }
          else if(c_p1==-1||c_p2==-1||c_p3==-1||c_p4==-1)
          {
                 perror("fork");
                 exit(1);         
          }
          else
          {
                  printf("====================This is parent process====================\n");
                  printf("My parent pid is %d\n",getpid());
                  printf("The pid of child1 is %d\n",c_p1);
                  printf("The pid of child2 is %d\n",c_p2);
                  printf("The pid of child3 is %d\n",c_p3);
                  printf("The pid of child4 is %d\n",c_p4);
         }
      wait(NULL);
 
  }