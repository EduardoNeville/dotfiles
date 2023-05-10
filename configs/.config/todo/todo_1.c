#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LINE_MAX 256 

int main(int argc, char *argv[]) {

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
    if (argc != 2) {
        printf("Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "r+");
    if (!file) {
        printf("Error opening file.\n");
        return 1;
    }

    char line[LINE_MAX];
    int current_line = 1;
    int previous_pos = 0;
    while (fgets(line, LINE_MAX, file)) {
        if (current_line != 1) {
            // We're not on the first line, so update the previous position
            previous_pos = ftell(file) - strlen(line);
        }
        if (line[strlen(line) - 1] == '\n') {
            // Remove the newline character
            line[strlen(line) - 1] = '\0';
        }
        printf("%s\n", line);
        fflush(stdout); // Flush the output buffer
        int c = getchar();
        if (c == 'j') {
            // Print the next line and add a * to the beginning
            if (fgets(line, LINE_MAX, file)) {
                fseek(file, -strlen(line), SEEK_CUR); // Move back to the beginning of the line
                fputc('*', file); // Add the *
                fputs(line, file); // Write the rest of the line
                fflush(file); // Flush the output buffer
                printf("%s*\n", line); // Print the line with the added *
                fflush(stdout); // Flush the output buffer
                current_line++;
            }
        } else if (c == 'k') {
            // Go back to the previous line
            if (previous_pos != 0) {
                fseek(file, previous_pos, SEEK_SET);
                fgets(line, LINE_MAX, file);  // Read the previous line
                if (line[strlen(line) - 1] == '\n') {
                    // Remove the newline character
                    line[strlen(line) - 1] = '\0';
                }
                printf("%s\n", line);
                fflush(stdout); // Flush the output buffer
                current_line--;
            }
        }
    }

    fclose(file);
    return 0;
}
