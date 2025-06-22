[BITS 16]                    ; Código 16-bit para modo real
[ORG 0x7C00]                 ; Endereço onde BIOS carrega o bootloader

start:
    ; Configura segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00           ; Stack pointer abaixo do bootloader

    ; Limpa a tela
    mov ax, 0x0003           ; Função para limpar tela (modo texto 80x25)
    int 0x10

    ; Exibe prompt para o usuário
    mov si, prompt_msg
    call print_string

    ; Lê entrada do usuário
    mov di, user_input       ; DI aponta para buffer de entrada
    call read_string

    ; Monta a string de saudação
    mov si, greeting_msg     ; "Olá, "
    mov di, final_output     ; Buffer de saída
    call copy_string

    ; Adiciona o nome do usuário
    mov si, user_input
    call copy_string

    ; Exibe a mensagem final
    mov si, final_output
    call print_string

    ; Loop infinito
hang:
    jmp hang

; Função para imprimir string
; SI = ponteiro para string (terminada em 0)
print_string:
    push ax
    push bx
    mov ah, 0x0E             ; Função teletype da BIOS
    mov bh, 0                ; Página de vídeo 0
.loop:
    lodsb                    ; Carrega byte de [SI] em AL e incrementa SI
    test al, al              ; Testa se é 0 (fim da string)
    jz .done
    int 0x10                 ; Chama interrupção da BIOS
    jmp .loop
.done:
    pop bx
    pop ax
    ret

; Função para ler string do teclado
; DI = ponteiro para buffer de destino
read_string:
    push ax
    push di
    mov cx, 30               ; Máximo de 30 caracteres
.loop:
    mov ah, 0x00             ; Função para ler tecla
    int 0x16                 ; Interrupção do teclado
    
    cmp al, 0x0D             ; Enter?
    je .done
    
    cmp al, 0x08             ; Backspace?
    je .backspace
    
    cmp al, 0x20             ; Caractere imprimível?
    jb .loop
    
    cmp cx, 0                ; Buffer cheio?
    je .loop
    
    ; Armazena caractere e exibe
    stosb                    ; Armazena AL em [DI] e incrementa DI
    mov ah, 0x0E             ; Exibe caractere
    int 0x10
    dec cx
    jmp .loop

.backspace:
    cmp cx, 30               ; Verifica se há algo para apagar
    je .loop
    
    dec di                   ; Volta um caractere no buffer
    inc cx
    
    ; Apaga caractere na tela
    mov ah, 0x0E
    mov al, 0x08             ; Backspace
    int 0x10
    mov al, ' '              ; Espaço
    int 0x10
    mov al, 0x08             ; Backspace novamente
    int 0x10
    jmp .loop

.done:
    mov byte [di], 0         ; Termina string com 0
    
    ; Nova linha
    mov ah, 0x0E
    mov al, 0x0D             ; Carriage return
    int 0x10
    mov al, 0x0A             ; Line feed
    int 0x10
    
    pop di
    pop ax
    ret

; Função para copiar string
; SI = origem, DI = destino (DI é atualizado)
copy_string:
    push ax
    push si
.loop:
    lodsb                    ; Carrega byte de [SI]
    test al, al              ; Fim da string?
    jz .done
    stosb                    ; Armazena em [DI]
    jmp .loop
.done:
    pop si
    pop ax
    ret

; Dados
prompt_msg      db 'Digite seu nome: ', 0
greeting_msg    db 'Ola, ', 0
user_input      times 32 db 0    ; Buffer para entrada do usuário
final_output    times 64 db 0    ; Buffer para saída final

; Preenchimento e assinatura do bootloader
times 510-($-$$) db 0            ; Preenche com zeros até byte 510
dw 0xAA55                        ; Assinatura do bootloader