; Системные вызовы Linux x86_64
SYS_READ      = 0
SYS_WRITE     = 1
SYS_OPEN      = 2
SYS_CLOSE     = 3
SYS_EXIT      = 60
SYS_FORK      = 57
SYS_WAIT4     = 61

; Флаги для open()
O_RDONLY      = 0      ; Только чтение
O_WRONLY      = 1      ; Только запись
O_RDWR        = 2      ; Чтение и запись
O_CREAT       = 64     ; Создать если не существует
O_APPEND      = 1024   ; Добавление в конец файла
O_TRUNC       = 512    ; Очистить файл при открытии

; Стандартные файловые дескрипторы
STDIN         = 0      ; Стандартный ввод
STDOUT        = 1      ; Стандартный вывод
STDERR        = 2      ; Стандартный вывод ошибок

; Права доступа к файлу (mode)
S_IRWXU       = 0700o  ; rwx для владельца
S_IRUSR       = 0400o  ; read для владельца
S_IWUSR       = 0200o  ; write для владельца
S_IXUSR       = 0100o  ; execute для владельца
S_IRWXG       = 0070o  ; rwx для группы
S_IRGRP       = 0040o  ; read для группы
S_IWGRP       = 0020o  ; write для группы
S_IXGRP       = 0010o  ; execute для группы
S_IRWXO       = 0007o  ; rwx для других
S_IROTH       = 0004o  ; read для других
S_IWOTH       = 0002o  ; write для других
S_IXOTH       = 0001o  ; execute для других