#include <ncurses.h>
#include <stdlib.h>

#define MENU_ITEMS 3
#define COLOR_DEFAULT 1
#define COLOR_HIGHLIGHT 2

// Структура пункта меню
typedef struct {
    char *title;
    void (*action)();
} MenuItem;

// Прототипы функций
void start_game();
void options();
void exit_app();

// Данные меню
MenuItem items[MENU_ITEMS] = {
    {"1. Start Game", start_game},
    {"2. Options", options},
    {"3. Exit", exit_app}
};

int current_selection = 0;

void init_colors() {
    start_color();
    init_pair(COLOR_DEFAULT, COLOR_WHITE, COLOR_BLACK);
    init_pair(COLOR_HIGHLIGHT, COLOR_BLACK, COLOR_WHITE);
}

void draw_menu() {
    clear();
    
    // Заголовок
    attron(COLOR_PAIR(COLOR_DEFAULT));
    mvprintw(0, 0, "Terminal Menu");
    attroff(COLOR_PAIR(COLOR_DEFAULT));

    // Пункты меню
    for(int i = 0; i < MENU_ITEMS; i++) {
        if(i == current_selection) {
            attron(COLOR_PAIR(COLOR_HIGHLIGHT));
        } else {
            attron(COLOR_PAIR(COLOR_DEFAULT));
        }
        mvprintw(i + 2, 2, "%s", items[i].title);
    }
    refresh();
}

void handle_input() {
    int ch = getch();
    switch(ch) {
        case KEY_UP:
            current_selection--;
            if(current_selection < 0) current_selection = MENU_ITEMS - 1;
            break;
        case KEY_DOWN:
            current_selection++;
            if(current_selection >= MENU_ITEMS) current_selection = 0;
            break;
        case 10: // Enter
            items[current_selection].action();
            break;
        case 27: // ESC
            exit_app();
            break;
    }
}

// Реализации действий
void start_game() {
    clear();
    mvprintw(10, 2, "Game Started!");
    refresh();
    getch();
}

void options() {
    clear();
    mvprintw(10, 2, "Options Menu");
    refresh();
    getch();
}

void exit_app() {
    endwin();
    exit(0);
}

int main() {
    // Инициализация ncurses
    initscr();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
    
    init_colors();
    curs_set(0); // Скрыть курсор

    while(1) {
        draw_menu();
        handle_input();
    }

    endwin();
    return 0;
}