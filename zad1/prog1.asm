 ;Rafal Pietruszka
;Zadanie 1 - Rysowanie wykresu funkcji liniowej w trybie tekstowym

Dane segment
	A	dw	0
	B	dw	0

	wzor	db	13,10,"f(x)="
	A_t	db	6 dup(0),"x   "
	B_t	db	'+'
		db	5 dup(0),". $"

	arg_max	db	4
	
	znak_ox db '-'
	znak_oy db '|'
	
	punkt	db '/'
	
	OX	dw	0
	podzial	dw	0
	podzialj dw 0
	;23x25 znakow na wykres
	wykr 	db	11 dup (' '),'^',11 dup (' '),13,10
	ekran	db	(23*25) dup(' ')	;wypelnienie spacja -> bo niewidoczy znak
	e_end	db	25 dup ('_')
	ekran_end		db	'$'			;dla celow kontroli pamieci
	
	intro	db	"Program rysuje przyblizony wykres funkcji liniowej y=ax-b w trybie tekstowym",13,10
			db 	"oraz wylicza miesce zerowe",13,10,'$'
	a_get	db	"Prosze podac wszpolczynnik kierunkowy a = $"
	b_get	db	13,10,"Prosze podac wyraz wolny b = $"
	OX_k	db	13,10,"OX=(  "
	OX_t	db	5 dup (' ')
			db	"    , 0.0  ). "
	skala_k	db	"|/- = "
	skala_t	db	5 dup(' ')
			db	13,10,'$'
	z_err	db	13,10,"Wprowadzono znak ktorzy nie jest cyfra ani seprarotem"
	zly_wpr	db	13,10,"Wprowadzono liczbe w niepoprawnej formie ( znak - znajduje sie miedzy cyframi liczby)",13,10,'$'
	CRLF	db	13,10,'$'
Dane ends

Kod	segment
	
	start_:
	
	;stos_init
	mov ax, seg sw
	mov ss, ax
	mov sp, offset sw
	;gotowy stos
	
	mov ax, seg A
	mov ds, ax
	
	call Wprowadzenie
	call Argumenty
	
	call Rysuj_uklad
	call Przeciecie_OX
	call Skaluj
	call Inf

	call Rysuj_wykres
	call Print_grap
	err:
	
	mov ah, 04Ch
	int 21h

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	;Wypisz wprowadzenie
	Wprowadzenie proc
		mov dx, offset intro
		call Print
		ret
	Wprowadzenie endp
	
	;print zaklada ds:dx wszkazuja ciag do wypisania
	Print proc
		push ax
		mov ah, 9
		int 21h
		pop ax
		ret
	Print endp
	
	;Pobiera argument w postaci ciagu znakow i zapisuje do pamieci
	;di -> docelowe miejsce w pamieci
	Arg_pars proc
		push ax
		xor si, si ;si -> 1 = ulamek; 0 = calkowia -> *10 + informacja o znaku na 2b
		xor ax, ax
		xor cx, cx
		mov cl, byte ptr ds:[arg_max] 
		xor bx, bx	;bx przechowuje aktualna przeliczona warosc liczby
		znak:
			mov ah, 01h	;Pobranie 1 znaku z echem na ekran
			int 21h  ;kod ASCII pobranego znaku do al
			
			;Sprawdzanie poprawnosci znaku
			cmp al, 13	;ENTER konec arg
			je k
			
			;Jesli znak jest cyfra przystepuje do aktualizoania pobranej warosci
			cmp al, '9'  ;kody ASCII 0-9 z przedialu 48-57
			jg	zly_znak
			cmp al, '0'
			jge	zapisz
		
			cmp al, '-'	;podawana liczba bedzie ujemna
			jg separator
			cmp cl,byte ptr ds:[arg_max]
			jne zle_wprowadzony_znak
			xor si, 2	;jesli podawana liczba jest ujemna to di na ma bit odpowiadjacy 2^1 = 1
			;mov ds:[is_neg], 1
			jmp znak
			
			;jl	zle_wprowadzony_znak
			separator:
			cmp al, '.'
			jne	zly_znak
				or si, 1
				jmp znak
			jmp zly_znak
			zapisz:
			xor ah, ah
			sub al, '0'
			add ax, bx
			;jesli si=1 to koniec, bo pobrano liczbe z maksymalna dokladnocia
			push si
				and si, 1 ;xor modyfikuje ZF na ktorej bazuje porowanie je
				cmp si, 1
			pop si
			je cont
			mov dx, 10
			mul dx
			cont:
			mov bx, ax
		loopnz znak	; loopnz poniewaz najmniej znaczacy bit si decyduje o dalszym wykonywani petli
		
		k:
		cmp si, 2
		jl	zl
			;liczba byla ujemna a zliczona jest jako dodatnia
			;minus tego rozwiazania nie osiagnie sie minimalnej wartosci
			xor ax, ax
			sub ax, bx
			mov bx, ax
		zl:
		mov ds:[di], bx
		pop ax
		ret
		zly_znak:
			call Z_znak
		zle_wprowadzony_znak:
			mov dx, offset zly_wpr
			call Print
		jmp err

	Arg_pars endp
	
	;Argumenty pobiera A oraz B
	Argumenty proc
		
		mov dx, offset a_get
		call Print
		mov di, offset A
		call Arg_pars
		
		mov dx, offset b_get
		call Print
		mov di, offset B
		call Arg_pars
		
		ret
	Argumenty endp
	
	Przeciecie_OX proc
		;OX -> ( -b/a, 0 )
		push ax
		push bx
		push dx
		xor dx, dx
		
		mov bx, word ptr ds:[A]
		cmp bx, 0
		je prosta
		;ax=-b
		mov ax, word ptr ds:[B]
		mov dx, -1
		imul dx

		;mov bx, word ptr ds:[A]
		
		;ax= -b/a
		idiv bx
		push ax
		;dokladnosc 1 cyfry
		mov ax, dx
		xor dx, dx
		mov bx, 10
		imul bx
		mov bx, word ptr ds:[A]
		idiv bx
		
		;dopisanie czesci ulamkowej
		pop bx
		xchg ax, bx
		push bx
		mov bx, 10
		imul bx
		pop bx
		add bx, ax
		jmp gotowa_skala
		
		prosta:
			mov ds:[punkt], '-'
		gotowa_skala:
		mov word ptr ds:[OX], bx
		
		pop dx
		pop bx
		pop ax
		ret
	Przeciecie_OX endp
	
	;Sprawdzenie wlasnosci wykresu
	Spr proc
		
		push ax
		
		mov ax, word ptr ds:[A]
		cmp ax, 0
		jne liniowy	;Tu do rysowania
		;wyskres to f stala

		liniowy:
		pop ax
		ret
	Spr endp
	
	
	Skaluj proc
		push ax
		push bx
		
		mov ax, ds:[OX]
		call Ab
		push ax
		mov ax, ds:[B]
		call Ab
		mov bx, ax
		pop ax
		
		cmp ax, bx
		jg skala
			xchg ax, bx
		skala:

		xor dx, dx
		mov bx, 10	
		div bx
		
		
		cmp ax, 0
		jne zapisz_skale
			mov ax, 10
		zapisz_skale:

		mov word ptr ds:[podzial], ax
		
		pop ax	
		pop bx
	Skaluj endp
	
	Rysuj_uklad proc
		push ax
		push cx
		
		mov bx, offset ekran
		push bx
		mov cx, 23			;iloc lini zajmowanych przez wykres os pinowa
		mov al, byte ptr ds:[znak_oy]
		rysuj:
			push bx
			add bx, 11
			mov byte ptr ds:[bx], al
			pop bx
			add bx, 23
			mov word ptr ds:[bx], 00A0Dh ;CRLF
			add bx, 2
		loop rysuj		
		
		pop bx
		
		cld
		mov ax, seg ekran
		mov es, ax
		add bx, 25*11
		mov di, bx
		mov cx, 23
		mov al, byte ptr ds:[znak_ox]
		rep stosb
		mov byte ptr ds:[di], '>'
		mov byte ptr ds:[di-12], '+'
		
		pop cx
		pop ax
		ret
	Rysuj_uklad endp
	
	Inf proc
		push dx
		
		mov si, offset A
		mov di, offset A_t
		call bin2dec
		
		mov si, offset B
		mov di, offset B_t
		call bin2dec
		
		mov dx, offset wzor
		call Print
		
		mov si,	offset podzial
		mov di, offset skala_t
		call bin2dec
		
		mov si, offset OX
		mov di, offset OX_t
		call bin2dec
		
		mov dx, offset OX_k
		call Print
		pop dx
		ret
	Inf endp
		
	Rysuj_wykres proc
		;si przyrost na jednostke
		xor si, si
		xor dx, dx
		
		mov ax, word ptr ds:[A]
		cmp ax, 0
		jge gtrtzero
			mov di, -25
			mov byte ptr ds:[punkt], '\'
			jmp cont_r
		gtrtzero:
			mov di, 25
		cont_r:
		
		mov si, ax
		;wykres ma serokosc 23 jednostek -> pierwsza kratka odpowiada -11
		mov bx, -11
		imul bx
		cwd
		mov bx, 10
		idiv bx
		;wykres przechowywany jest w tablicy, ktrej wiersz ma 25 znakow
		mov bx, 25
		imul bx
		;tak dla debuga do pamieci 
		mov word ptr ds:[podzialj], ax
		;ax=przyrost na
		push ax
		mov ah, 1
		int 21h
		pop ax
		
		;Wylicznie wysokosci b

		mov ax, word ptr ds:[B]
		cwd
		mov bx, word ptr ds:[podzial]
		idiv bx
		mov bx, 25
		imul bx
		
		mov bx, word ptr ds:[podzialj]
		add ax, bx	;sprawdzic

		
		
		mov bx, offset ekran
		add bx, 25*11;25*11 os OX
		sub bx, ax
		xor ax, ax
		mov cx, 23

		xor ax, ax
		xor dx, dx
		
		lo:	
			push cx
			
			add ax, si
				mov cx, 10
				cwd
				idiv cx
				push dx	;reszta
				push ax
				mov cx, 25
				imul cx
				
				pop ax	;czesc calkowita do petli
				call Ab
				mov cx, ax

				mov al, byte ptr ds:[punkt]
				cmp cx, 0
				jne put
					mov byte ptr ds:[bx], al
				jmp cx_0_end
				
			put:
				cmp bx, offset ekran
				jle mem_leak
				cmp bx, offset e_end
				jge mem_leak
					
					mov byte ptr ds:[bx], al
				mem_leak:
					sub bx, di
			loop put
			
			cx_0_end:
				;reszta do ax
				pop ax
				inc bx
				pop cx
		loop lo
		
		ret
	Rysuj_wykres endp
	

;..............................................................
;bin2dec tworzy zapis dziesietny
;si - dword zawierajacy liczbe do przeksztalcenia
;di - miejsce zapisu wyniku
;..............................................................
	bin2dec proc
        push di
		push cx
	
		mov al, ' '
		mov cx, 3
		add di, 4
		mov byte ptr ds:[di], '0'
		
        zer:
            dec di
            mov byte ptr ds:[di], ' '
        loop zer
		
		pop cx
        pop di
		; bx	podstawa systemu
		; ds:si	slowo do konwersji
		xor bx, bx
		xor ax, ax
		xor cx, cx 
		xor dx, dx
		mov bx, 10

		mov ax, word ptr ds:[si]
		
		cmp ax, 0
		jnl positive
			call Ab
			mov byte ptr ds:[di], '-'
			inc di
		positive:
		cmp ax, 0000h
		je numend

		getd:
			div bx ; dzieli dx, ax prez 10
			add dx, '0'
			push dx
			xor dx, dx
			inc cx			;licznik ile el trafi na stos = dlugosc liczyby
			cmp ax, 0
		jne getd
		
		add di, 5
		sub di, cx
		saveD:
			pop ax
			cmp cx, 1
			jne cyfra
				mov byte ptr ds:[di], '.'
				inc di
			cyfra:
			mov byte ptr ds:[di], al
			inc di
		loop saveD
	numend:
		ret
	bin2dec endp
	
	Ab proc
		cmp ax, 0
		jge dodatnie
			push bx
			xor bx, bx
			sub bx, ax
			mov ax, bx
			pop bx
		dodatnie:
		ret
	Ab endp
		
	Print_grap proc
		mov dx, offset wykr
		call Print
	print_end:
		ret
	Print_grap endp
	
	Z_znak proc
		mov dx, offset z_err
		call Print
		jmp err
		ret		
	Z_znak endp
	
Kod ends

Stos1 segment stack
		dw 128 dup(?)
	sw	dw ?
Stos1 ends
end start_
