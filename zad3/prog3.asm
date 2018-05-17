	assume cs:code1
dane1 segment
	hin		dw ?	;uchwyty do plikow
	hout	dw ?
	nagLen	db 24
	naglowek db "Raport z pliku o nazwie "
	wejscie db 100 dup(0) 
	wyjscie db 100 dup(0)
	
	argLen	db 2 dup(0)	                     		         ;dlugosc argumentow
	
	buf1	db 1024 dup( 0 )                            ;buffor danych
	bufsize dw 1024
	
	counts	db 1024 dup( 0 )                            ;tablica przechowujaca ilosci wystapien bajtow ( ilosc wystapien bajtu jest pamietana na dword )
	
	error1	db "Blad otwacia pliku",10,13,'$'         ;komunikat bledu otwarcia pliku
	error2	db "Blad tworzenia pliku",10,13,'$'       ;komunikat bledu przy tworzeniu pliku
	error3	db "Blad odczytu",10,13,'$'               ;komunikat bledu przy odczycie pliku
	error5	db "Blad zamkniecia pliku",10,13,'$'                   ;komunikat bledu przy przsunieciu kursora pliku
	error6	db "Blad zapisu",10,13,'$'                   ;komunikat bledu przy przsunieciu kursora pliku
	
	pliki	db "Nazwy pliku wejsciowego i wyjsciowego sa indentyczne.",13,10
			db "Kontynucja zniszczy plik wyjsciowy. (t/n)",13,10,'$'
			
	istnieje	db "Udalo sie odnalesc plik ktorego nazwa pasuje do wzorca nazwy pliku wyjsciowego.",13,10
				db "Upewnij sie ze nazwy sa rozne, poniewaz kontynucja zniszczy plik wyjsciowy.(t/n)",13,10,'$'
	
	brakArg db "Niepoprawna liczna argumentow!",13,10
			db "prog3.exe wejscie wyjscie ",13,10
			db "Program pobiera plik wejsciowy oraz tworzy raport zawierajacy ilosc wystapien bajtow w zrodle",13,10
			db "Nadmiarowe argumenty sa pomijane",13,10,'$'
	
	nrbitu	dd 0                                        ;zienna przecowujaca wartosci bitów
	bitdec	db 3 dup(0)
	delimit	db ":  "                                    ;sekwencja oddzielajaca wartosc bajtu od ilosci jesgo wystapien w pliku
	numDec	db 10 dup (' ')                             ;talica do ktorej zapisywana jest dziesietnie liczba binarna
	CRLF	db 0Dh,0Ah,'$'                      ; sekwencja nowej linii
dane1 ends

stos1 segment stack
	dw 256 dup(?)
sw	dw ?
stos1 ends
	
	
code1 segment
	
start1:
	
	;inicjacja stosu
	mov	ax, seg sw
	mov	ss, ax
	mov	sp, offset sw
	
	
	;przygotowanie rejestrów do pobrania parametrow przeslanych do pliku
	mov	ax, seg wejscie
	mov	es,ax
	xor	bx, bx
	xor ax, ax
	mov	si,082h
	mov	di, offset wejscie
	xor	cx,cx
	mov	cl,byte ptr ds:[080h]
	
	dec cx ;pominiecie entera
	;petla wczytujaca kolejne znaki i zapisujaca je do pamieci
	
p1:
	mov al, byte ptr ds:[si]
	cmp al, ' '	;czy to spacja
	jne con ;jesli nie spacja przejdz do zapisu znaku
		;napotkano spacje
		mov byte ptr es:[argLen+bx], dl ;zapisz dlugosc argunetu		
		pomin_spacje:
                    inc si
                    mov al, byte ptr ds:[si]
                    cmp al, ' '
        loopz pomin_spacje
		
		mov di, offset wyjscie
		xor dx, dx
		inc bx
con:
	cmp bx, 2
	je argReady
	mov	es:[di], al ;zapisz znak do pamieci
	inc	di
	inc	si
	inc dx
loop	p1
	
argReady:
	mov ax, seg wejscie
	mov ds, ax
	mov byte ptr es:[argLen+bx], dl
	
	cmp byte ptr es:[argLen], 0
	je brak_arg
	cmp byte ptr es:[argLen+1], 0
	je brak_arg
	jmp sprPliki ;sprawdzenie nazw plikow
rozne:
	;Proba otwarcia pliku 
	clc; zerowanie CF jezeli napotkany zostanie blad to zostanie ustawiona flaga

	mov dx, offset wejscie
	mov ah, 3Dh	;kod 3D otwarci pliku
	mov al, 00h ;otwarcie tylko do odczytu
	int 21h
	jc err_open ;jezeli napotkano blad zwroc blad i zakoncz program
	
	mov bx, ax	;ax po udanym otwarciu pliku zawiera numer uchwytu, ale operacje na pliku korzystaja z bx
	mov di, offset hin
	mov word ptr ds:[di], bx ;zachowanie uchwytu do pliku w pamieci	
	
	xor cx, cx ; cx atrybuty pliku

	clc	;po nastepnej operacji bedzie weryfikowana 
	mov dx, offset wyjscie
	mov ah, 4Eh ;odszukanie pliku pasujacego nazwa
	int 21h
	jnc znaleziono	;jezeli znaleziono plik o tej nazwie CF=0, brak pliku -> CF=1

	zgoda:
	mov ah, 3Ch
	int 21h	
	jc err_create
	

	mov si, offset buf1
	mov di, offset counts
	
	zliczaj:
		xor ax, ax
		;Pobranie danych z pliku wejsciowego
		clc
		mov dx, offset buf1
		mov bx, ds:[hin]
		mov ah, 3Fh
		mov cx, word ptr ds:[bufsize]
		int 21h
		jc err_read
		
		;jesli udalo sie dokonac odczytu to AX zawiera liczbe poprawnie przeczytanych bajtow
		mov cx, ax
		mov si, offset buf1
		
		cmp cx, 0000h ;jesli odczyt zakonczyl sie sukcesem, ale pobrano 0B to plik sie skonczyl przejdz do generowania raportu
		je gen

		xor dx, dx
		
		;;petla zliczajaca znaki
		
		zwieksz_znak:
			
			xor di, di
			xor ax, ax
			xor bx, bx
			mov di, offset counts
			;AX posluzy do wyliczenia offsetu poniewaz dword to 4B mnozymy kod ASCII *4
			xor ax, ax
			mov al, byte ptr es:[si]
			mov bl, 4
			mul bl
			add di, ax
			
			clc
			add word ptr es:[di], 1	;inkrementacja ilosci wystapien bitu
			adc word ptr es:[di+2], 0 ;dodawnie z przeniesieniem
		
			inc si
		
		loop zwieksz_znak
	jmp zliczaj
	
gen:

	mov bx, word ptr ds:[hin]
	mov ah, 3Eh ;zamkniecie pliku zrodlowego
	int 21h
	jc err_close
	
	;proba utworzenia pliku wyjciowego	
	xor ax, ax
	xor cx, cx
	xor dx, dx

	mov ax, seg wyjscie
	mov ds, ax
	mov dx, offset wyjscie
	mov ah, 3Dh ;otwarcie pliku
	mov al, 1	;tryb zapisu
	int 21h
	jc err_open
	
	;przechowanie nr uchwytu pliku wyjsciowego
	mov bx, ax
	mov word ptr ds:[hout], bx
	
	;generowenie raportu
	
	;wstawienie naglowka
	xor cx, cx
	mov ah, 40h
	mov dx, offset naglowek
	mov cl, byte ptr ds:[argLen]
	add cx, 24
	int 21h
	
	mov cx, 2
	addLF:
		push cx
		mov ah, 40h
		mov dx, offset CRLF
		mov cx, 2
		int 21h
		pop cx
	loop addLF
	
	
	mov cx, 256	;potrzebna lista 256 wartosci 0-255
	mov bx, 0	;bx przechowuje bajt dla ktorego generowana bedzie linia
	druk:
		push cx
		push bx
		
		;przelicznie wartosci bitu na system dzisietny
		mov word ptr ds:[nrbitu], bx
		mov al, 0			
		mov si, offset nrbitu
		mov di, offset bitdec
			call bin2dec
		
		pop bx
		push bx
		
		mov ax, bx
		mov bx, 4
		mul bx 
		mov si, offset counts
		add si, ax
		mov di, offset numDec
		mov al, 1
			call bin2dec
		
		mov dx, offset bitdec
		mov bx, ds:[hout]
		mov ah, 40h
		mov cx, 18
		int 21h
		jc err_write
		pop bx
		inc bx
		pop cx
	loop druk
	
	q:
	;zamkniecie pliku
	mov bx, word ptr ds:[hout]
	mov ah, 3Eh
	int 21h
	
	;wyjscie z programu
	mov ax, 04c00h
	int 21h
	
	
	
;....................................................................
	
	brak_arg:
		mov dx, offset brakArg
		call print1
	jmp q
	
	znaleziono:
		push dx
		mov dx, offset istnieje
		call print1
		
		xor ax, ax
		mov ah, 01h
		int 21h
		
		pop dx
		cmp al, 't'
		je zgoda
		
	jmp q
	
	
	jmp q
	
	err_close:
		mov dx, offset error5
		call print1
	jmp q
		
	err_write:
		mov dx, offset error6
		call print1
		jmp q
	
	err_read:
		mov dx, offset error3
		call print1
		jmp q
		
	err_open:
		mov dx, offset error1
		call print1
	jmp q
		
	err_create:
		mov bx, ds:[hin]
		mov ah, 3Eh
		int 21h
		mov dx, offset error2
		call print1
	jmp q
		
	sprPliki:
	
		xor cx, cx
		mov cl, byte ptr es:[argLen]
		mov si, offset wejscie
		mov di, offset wyjscie
		
		porownaj:
			mov al, byte ptr es:[si]
			cmp al, byte ptr es:[di]
			jne rozne
			inc si
			inc di
		loop porownaj
		
		mov dx, offset pliki
		call print1
		
		xor ax, ax
		mov ah, 01h
		int 21h
		
		cmp al, 't'
		je rozne
		
	jmp q

	
;..............................................................
	print1 proc
		mov ah, 09h
		int 21h
		ret
	print1 endp
;..............................................................

;..............................................................

;..............................................................
;bin2dec tworzy zapis dziesietny
;si - dword zawierajacy liczbe do przeksztalcenia
;di - miejsce zapisu wyniku
;al - 0 - konwersja wartosci bajtu, ~0 konwersja licznika
;..............................................................
	bin2dec proc
        
		;si zrodlo
		;di cel
		;al 0 - konwesja bitow, 1 - licznika
        push di
		push cx
		cmp al, 0
		jne counter
			mov al, '0'
			mov cx, 3
			jmp clean
		counter:
			mov al, ' '
			mov cx, 9
			mov byte ptr ds:[di], '0'
			inc di
		
		clean:
        zer:
            mov byte ptr ds:[di], al
            inc di
        loop zer
		pop cx
        pop di
		;; bx	podstawa systemu
		; ds:si	slowo do konwersji
		xor bx, bx
		xor ax, ax
		xor cx, cx 
		xor dx, dx
		mov bx, 10
		
		mov dx, word ptr ds:[si+2]
		mov ax, word ptr ds:[si]
		
		cmp ax, 0000h
		jne go
		cmp dx, 0000h
		je numend
	
		go:
		getd:
			div bx ; dzieli dx, ax prez 10
			add dx, '0'
			push dx
			xor dx, dx
			inc cx			;licznik ile el trafi na stos = dlugosc liczyby
			cmp ax, 0
		jne getd
		
		;wypelnienie w zaleznosci od celu
		cmp byte ptr ds:[di+1], '0'
		je reversefill
		saveD:
			pop ax
			mov byte ptr ds:[di], al
			inc di
		loop saveD
		jmp numend
		
		reversefill:
		add di, 3
		sub di, cx
		saveB:
			pop ax
			mov byte ptr ds:[di], al
			inc di
		loop saveB
	numend:
		ret
	bin2dec endp
	
	
;..............................................................
	
code1 ends
end start1
