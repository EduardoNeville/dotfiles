#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#define WORK_TIME 25 
#define REST_TIME 5

void countdown(int minutes) {
    time_t start_time = time(NULL);
    time_t end_time = start_time + (minutes * 60);
    int seconds_left;

    while (time(NULL) < end_time) {
        seconds_left = end_time - time(NULL);
        printf("\r%02d:%02d", seconds_left / 60, seconds_left % 60);
        fflush(stdout);
        sleep(1);
    }
    printf("\r00:00");
}

void notify(char *message) {
    char command[256];
    sprintf(command, "notify-send \"%s\" -t 0", message);
    system(command);
}

int main() {
    int pomodoros_completed = 0;

    while (1) {
        printf("Pomodoro %d - Work time\n", pomodoros_completed + 1);
        countdown(WORK_TIME);
        notify("Time's up! Take a break.");

        printf("Pomodoro %d - Rest time\n", pomodoros_completed + 1);
        countdown(REST_TIME);
        notify("Break's over! Time to get back to work.");

        pomodoros_completed++;
        printf("Pomodoro completed. Total completed: %d\n", pomodoros_completed);
    }

    return 0;
}
