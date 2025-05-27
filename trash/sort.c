#define _XOPEN_SOURCE 1
#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_LINE 4096
#define MAX_LINES 1024

typedef struct {
    char *line;
    time_t timestamp;
} Event;

time_t parse_date(const char *line) {
    struct tm tm = {0};
    char date_str[20];
    
    if (sscanf(line, "[%19[^]]", date_str) != 1)
        return 0;

    char *result = strptime(date_str, "%Y-%m-%d %H:%M", &tm);
    if (result == NULL)
        return 0;

    return mktime(&tm);
}

int compare_events(const void *a, const void *b) {
    Event *event_a = (Event *)a;
    Event *event_b = (Event *)b;
    return (event_a->timestamp > event_b->timestamp) - (event_a->timestamp < event_b->timestamp);
}

int read_file_lines(const char *filename, Event *events, int *count) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        perror("Ошибка открытия файла");
        return 0;
    }

    char line[MAX_LINE];
    int index = 0;

    while (fgets(line, sizeof(line), file) && index < MAX_LINES) {
        events[index].line = strdup(line);
        events[index].timestamp = parse_date(line);
        index++;
    }

    fclose(file);
    *count = index;
    return 1;
}

int write_sorted_lines(const char *filename, Event *events, int count) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Ошибка открытия файла для записи");
        return 0;
    }

    for (int i = 0; i < count; i++) {
        fprintf(file, "%s", events[i].line);
        free(events[i].line);
    }

    fclose(file);
    return 1;
}

int main() {
    Event events[MAX_LINES];
    int event_count = 0;

    if (!read_file_lines("events.txt", events, &event_count)) {
        fprintf(stderr, "Не удалось прочитать файл\n");
        return 1;
    }

    qsort(events, event_count, sizeof(Event), compare_events);

    if (!write_sorted_lines("events.txt", events, event_count)) {
        fprintf(stderr, "Не удалось записать файл\n");
        return 1;
    }

    printf("Файл успешно отсортирован по дате и времени.\n");
    return 0;
}