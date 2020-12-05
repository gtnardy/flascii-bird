Include ..\Irvine32.inc
includelib winmm.lib

PlaySound PROTO,
        pszSound:PTR BYTE, 
        hmod:DWORD, 
        fdwSound:DWORD
		
.data
	SND_ALIAS    DWORD 00010000h
	SND_RESOURCE DWORD 00040005h
	SND_FILENAME DWORD 00020000h
	SND_ASYNC DWORD 1h
	
	wavPoint BYTE "C:\LabArq2\MASM\sfx_point.wav", 0
	wavCrash BYTE "C:\LabArq2\MASM\sfx_hit.wav", 0
	wavWing BYTE "C:\LabArq2\MASM\sfx_wing.wav", 0

	floorCharacter byte 119 DUP(177), 0 ; string de caracteres do chão
	lostText db	5 DUP(10),
		36 DUP(" "), "  _____                         ____             	  ", 10,
		36 DUP(" "), " / ____|                       / __ \                ", 10,
		36 DUP(" "), "| |  __  __ _ _ __ ___   ___  | |  | __   _____ _ __ ", 10,
		36 DUP(" "), "| | |_ |/ _` | '_ ` _ \ / _ \ | |  | \ \ / / _ | '__|", 10,
		36 DUP(" "), "| |__| | (_| | | | | | |  __/ | |__| |\ V /  __| |   ", 10,
		36 DUP(" "), " \_____|\__,_|_| |_| |_|\___|  \____/  \_/ \___|_|   ", 0
	  
	menuText db	5 DUP(10),
		37 DUP(" "), " ______ _                _ _  ____  _         _ ", 10,
		37 DUP(" "), "|  ____| |              (_(_)|  _ \(_)       | |", 10,
		37 DUP(" "), "| |__  | | __ _ ___  ___ _ _ | |_) |_ _ __ __| |", 10,
		37 DUP(" "), "|  __| | |/ _` / __|/ __| | ||  _ <| | '__/ _` |", 10,
		37 DUP(" "), "| |    | | (_| \__ | (__| | || |_) | | | | (_| |", 10,
		37 DUP(" "), "|_|    |_|\__,_|___/\___|_|_||____/|_|_|  \__,_|", 0
		
	screenSize dword 120, 29 ; tamanho da tela em pixel
	pipesMatrix byte 29 DUP(120 DUP(" ")), 1 DUP(" "), 0 ; matriz dos canos
	auxMatrix dword 0 ; auxiliar de matriz (para torna-la linear)
	birdPosition byte 60, 16 ; posição do pássaro
	tickCount byte 18 ; timeout para gerar um novo cano
	jumping sbyte 4 ; gravidade aplicada ao pássaro
	gameState byte 1 ; estado do jogo
	drawFirst byte 0 ; se já desenhou a matriz pelo menos uma vez
	tickClock byte 50 ; velocidade do clock (quantos frames por segundo)
	points word 0
	pointsCount byte 56
	
.code
main PROC

innerTick:
	; tick principal para funcionamento do jogo, seria como o clock que roda a cada 'tickClock' milisegundos,
	; desenhando e calculando a engine do jogo
	call tick
	
	mov al, tickClock
	call Delay
	jmp innerTick
	
	exit
main endp

tick proc
	
	; onKeyPress checker
	call onKeyPress
	
	; limpa a tela
	mov dl, 0
	mov dh, 0
	call Gotoxy
	
	; se estiver jogando
	cmp gameState, 2
	je a1

	; se não estiver jogando, verifica se já desenhou a matriz pelo menos uma vez na tela
	cmp drawFirst, 1
	je endTick
	
	mov drawFirst, 1
	
	a1: 
	
	; checa a colisão
	call checkCollision

	; valor padrão para o auxiliar da matriz
	mov auxMatrix, 0
	
	; aumenta o valor do tick count
	dec pointsCount
	cmp pointsCount, 0
	jne l3
	
	inc points
    INVOKE PlaySound, OFFSET wavPoint, NULL, SND_ASYNC
	mov pointsCount, 20
	
	l3:
		 
	
	; aumenta o valor do tick count
	inc tickCount
	cmp tickCount, 20
	jne l1
	
	; caso tickCount = 20, gerar um pipe e zerar tickCount
	call generatePipe
	mov tickCount, 0
	
	l1:
	
	; iteração em todos caracteres da matriz
	; setar screen height
	mov ebx, screenSize + 4

	loopHeight:
		; setar screen width
		mov ecx, screenSize
		
		loopWidth:
			
			; move pra esquerda
			mov eax, auxMatrix
			push ebx
			
			cmp ecx, screenSize
			je cleanChar
			
			; move cada caracter um pixel para esquerda para dar sensação de movimento
			mov bl, pipesMatrix[eax + 1]
			mov pipesMatrix[eax], bl
			jmp l2
			
			; limpa o primeiro caracter horizontal
			cleanChar:
				mov pipesMatrix[eax], " "
			
			l2:
			pop ebx
			
			; incrementa auxiliar da matrix
			inc auxMatrix
			
			; loop horizontal
			dec ecx
			cmp ecx, 0
			jne loopWidth
		
		; loop vertical
		dec ebx
		cmp ebx, 0
		jne loopHeight

	; calcula a gravidade
	call gravity
	
	; desenha matrix
	mov eax, lightGreen
	call SetTextColor
	mov edx, offset pipesMatrix
	call WriteString
	
	; desenha o chão
	mov dl, 0
	mov dh, 29
	call Gotoxy
	
	mov eax, brown
	call SetTextColor
	mov edx, offset floorCharacter
	call WriteString

	
	endTick:
	
	; printa mensagens
	cmp gameState, 1
	jne a2
	
	; mensagem menu
	mov dl, 0
	mov dh, 0
	call Gotoxy
	mov eax, white
	call SetTextColor
	mov edx, offset menuText
	call WriteString
	
	a2:
	
	cmp gameState, 3
	jne a3
	
	; mensagem perdeu
	mov dl, 0
	mov dh, 0
	call Gotoxy
	mov eax, lightRed
	call SetTextColor
	mov edx, offset lostText
	call WriteString
	
	a3:
	
	cmp gameState, 1
	je a7
	
	; desenha os pontos
	mov eax, white
	call SetTextColor
	mov dl, 61
	mov dh, 2
	call Gotoxy
	mov ax, points
	call WriteDec
	
	a7:
	; desenha o pássaro
	mov eax, yellow
	call SetTextColor
	mov dh, [birdPosition + 1]
	mov dl, birdPosition
	call Gotoxy
	
	; desenha a asa do pássaro
	push eax
	cmp jumping, 4
	jbe windup
	mov al, "\"
	jmp winddown
	
	windup:
	mov al, "/"
	
	winddown:
	
	call WriteChar
	
	mov al, "O"
	call WriteChar
	
	pop eax
	
	
	ret
tick endp

checkCollision proc
	push eax
	push edx
	
	mov eax, [screenSize + 4]
	sub eax, 2
	
	; verifica se a posição do pássaro é menor que o tamanho da tela - 2
	cmp [birdPosition + 1], al
	jae crashed
	
	; verifica se a posição do pássaro é maior que o tamanho da tela
	cmp [birdPosition + 1], 0
	je crashed
	
	; calcula o caracter de intersecção com o pássaro
	; (y - 1) * xLength + x
	mov eax, 0
	mov al, [birdPosition + 1]
	dec al
	mul screenSize
	add al, birdPosition
	
	mov al, pipesMatrix[eax]
	
	; compara se o caracter de intersecção é espaço em branco
	cmp al, 20h
	je endCheckCollision
	
	; se crashou, seta estado como 3 - lost
	crashed:
    INVOKE PlaySound, OFFSET wavCrash, NULL, SND_ASYNC
	mov gameState, 3
	
	endCheckCollision:
	pop edx
	pop eax
	
	ret
checkCollision endp

generatePipe proc
	; meio que será gerado aleatoriamente
	mov eax, 10
	call RandomRange 
	mov ecx, eax
	add ecx, 5
	
	mov ebx, 0
	
	; edx = posição do cano
	mov edx, 0
	sub edx, 5
	call loopHeightGeneratePipe
	
	; bordas superiores
	mov pipesMatrix[edx], 200
	mov pipesMatrix[edx + 1], 205
	mov pipesMatrix[edx + 2], 205
	mov pipesMatrix[edx + 3], 188
	
	; chama o metodo novamente com os parametros do cano inferior
	push edx
	mov eax, 10
	mul screenSize ; quantidade de espaço entre os canos (meio)
	pop edx
	add edx, eax
	
	mov ebx, 0
	mov ecx, [screenSize + 4]
	sub ecx, 10

	; bordas inferiores
	mov pipesMatrix[edx], 201
	mov pipesMatrix[edx + 1], 205
	mov pipesMatrix[edx + 2], 205
	mov pipesMatrix[edx + 3], 187
	
	call loopHeightGeneratePipe
	ret
generatePipe endp

loopHeightGeneratePipe proc
	add edx, screenSize
	mov pipesMatrix[edx], 186
	mov pipesMatrix[edx + 3], 186
	
	inc ebx
	cmp ebx, ecx
	jne loopHeightGeneratePipe
	
	ret
loopHeightGeneratePipe endp

; param: dx key
onKeyPress proc
	call ReadKey
    jz endKey
	
	cmp gameState, 1
	je state1
	
	cmp gameState, 2
	je state2
	
	cmp gameState, 3
	je state3
	
	; caso esteja no estado menu
	state1:
		; inicia o jogo
		INVOKE PlaySound, OFFSET wavWing, NULL, SND_ASYNC
		mov gameState, 2
		jmp endKey
	
	; caso esteja no estado jogando
	state2:
	
		mov jumping, 4
		jmp endKey
		
	; caso esteja no estado perdeu	
	state3:
		; muda para menu
		mov drawFirst, 0
		; limpa matriz
		mov ecx, lengthof pipesMatrix
		clearArray:
			mov pipesMatrix[ecx], " "
			loop clearArray
		
		mov auxMatrix, 0
		mov [birdPosition + 1], 16
		mov tickCount, 19
		mov jumping, 4
		
		mov gameState, 1
		mov points, 0
		mov pointsCount, 57
	
	endKey:
	ret
onKeyPress endP

gravity proc
	cmp gameState, 3
	je endGravity
	; cmp jumping, 0
	mov eax, 0
	dec jumping
	js belowZero
	
	; pulando
	aboveZero:
		mov al, jumping
		sub [birdPosition + 1], al
		
		; caso a posição do pássaro seja menor que 0, seta como 0
		cmp [birdPosition + 1], 29
		jb l7
		mov [birdPosition + 1], 0
		l7:
		ret
	
	; caindo
	belowZero:
		add [birdPosition + 1], 1
		
	endGravity:
	ret
gravity endp

end main