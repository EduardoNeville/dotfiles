#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

#define FILE_NAME "todo.md"

int getch() {
    struct termios oldattr, newattr;
    int ch;
    tcgetattr(STDIN_FILENO, &oldattr);
    newattr = oldattr;
    newattr.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
    return ch;
}

int main() {
    FILE *fp;
    bool exists = false;
    char c;
    int cursor = 0;
    char line[256];

    // check if the file exists
    fp = fopen(FILE_NAME, "r");
    if (fp != NULL) {
        exists = true;
        fclose(fp);
    }

    // if the file does not exist, create it and prompt the user for a todo item
    if (!exists) {
        fp = fopen(FILE_NAME, "w");
        printf("No todo items found. Please add a todo item:\n");
        fgets(line, sizeof(line), stdin);
        fprintf(fp, "- [ ] %s", line);
        fclose(fp);
        printf("Todo item added successfully!\n");
        return 0;
    }

    // if the file exists, display the todo items and allow the user to navigate them
    fp = fopen(FILE_NAME, "r+");
    printf("Todo items:\n\n");
    while (fgets(line, sizeof(line), fp)) {
        printf("%s", line);
    }
    fflush(stdout);
    fseek(fp, 0, SEEK_SET);
    while ((c = getch()) != 'q') {
        if (c == 'j') {
            if (fgets(line, sizeof(line), fp)) {
                cursor++;
                line[0] = '*';
                while (fgets(line, sizeof(line), fp)) {
                    printf("%s", line);
                }
                fflush(stdout);
            } else {
                fseek(fp, 0, SEEK_SET);
                cursor = 0;
            }
        } else if (c == 'k') {
            if (cursor > 0) {
                fseek(fp, -2 * strlen(line), SEEK_CUR);
                fgets(line, sizeof(line), fp);
                cursor--;
                line[0] = '*';
                while (fgets(line, sizeof(line), fp)) {
                    printf("%s", line);
                }
                fflush(stdout);
            }
        } else if (c == 32) {
            if (line[4] == ' ') {
                line[4] = 'x';
                fseek(fp, -strlen(line), SEEK_CUR);
                fputs(line, fp);
                fseek(fp, 0, SEEK_CUR);
                while (fgets(line, sizeof(line), fp)) {
                    printf("%s", line);
                }
                fflush(stdout);
            } else {
                line[4] = ' ';
                fseek(fp, -strlen(line), SEEK_CUR);
                fputs(line, fp);
                fseek(fp, 0, SEEK_CUR);
            }
        }
    }
    fclose(fp);
    printf("Exiting...\n");
    return 0;
}
