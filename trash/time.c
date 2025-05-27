#include <time.h>

// Возвращает указатель на строку с временем в формате HH:MM:SS
const char* get_time() {
    static char buffer[9];
    time_t rawtime;
    struct tm *timeinfo;

    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(buffer, sizeof(buffer), "%T", timeinfo);
    return buffer;
}