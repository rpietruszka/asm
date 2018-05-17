DANE segment
    ;RP
    intro   db "Program generuje kod kreskowy ( w standardzie EAN-128 )",13,10
            db	"Posze wprowadzic ciag znakow do zakodowania ( max. 24 znaki).",13,10,'$'
    ;wystarczyl awk, fold
	bars_array	db 2,1,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,1,1,2,1,2,2,3,1,2,1,3,2,2
				db 1,3,1,2,2,2,1,2,2,2,1,3,1,2,2,3,1,2,1,3,2,2,1,2,2,2,1,2,1,3
				db 2,2,1,3,1,2,2,3,1,2,1,2,1,1,2,2,3,2,1,2,2,1,3,2,1,2,2,2,3,1
				db 1,1,3,2,2,2,1,2,3,1,2,2,1,2,3,2,2,1,2,2,3,2,1,1,2,2,1,1,3,2
				db 2,2,1,2,3,1,2,1,3,2,1,2,2,2,3,1,1,2,3,1,2,1,3,1,3,1,1,2,2,2
				db 3,2,1,1,2,2,3,2,1,2,2,1,3,1,2,2,1,2,3,2,2,1,1,2,3,2,2,2,1,1
				db 2,1,2,1,2,3,2,1,2,3,2,1,2,3,2,1,2,1,1,1,1,3,2,3,1,3,1,1,2,3
				db 1,3,1,3,2,1,1,1,2,3,1,3,1,3,2,1,1,3,1,3,2,3,1,1,2,1,1,3,1,3
				db 2,3,1,1,1,3,2,3,1,3,1,1,1,1,2,1,3,3,1,1,2,3,3,1,1,3,2,1,3,1
				db 1,1,3,1,2,3,1,1,3,3,2,1,1,3,3,1,2,1,3,1,3,1,2,1,2,1,1,3,3,1
				db 2,3,1,1,3,1,2,1,3,1,1,3,2,1,3,3,1,1,2,1,3,1,3,1,3,1,1,1,2,3
				db 3,1,1,3,2,1,3,3,1,1,2,1,3,1,2,1,1,3,3,1,2,3,1,1,3,3,2,1,1,1
				db 3,1,4,1,1,1,2,2,1,4,1,1,4,3,1,1,1,1,1,1,1,2,2,4,1,1,1,4,2,2
				db 1,2,1,1,2,4,1,2,1,4,2,1,1,4,1,1,2,2,1,4,1,2,2,1,1,1,2,2,1,4
				db 1,1,2,4,1,2,1,2,2,1,1,4,1,2,2,4,1,1,1,4,2,1,1,2,1,4,2,2,1,1
				db 2,4,1,2,1,1,2,2,1,1,1,4,4,1,3,1,1,1,2,4,1,1,1,2,1,3,4,1,1,1
				db 1,1,1,2,4,2,1,2,1,1,4,2,1,2,1,2,4,1,1,1,4,2,1,2,1,2,4,1,1,2
				db 1,2,4,2,1,1,4,1,1,2,1,2,4,2,1,1,1,2,4,2,1,2,1,1,2,1,2,1,4,1
				db 2,1,4,1,2,1,4,1,2,1,2,1,1,1,1,1,4,3,1,1,1,3,4,1,1,3,1,1,4,1
				db 1,1,4,1,1,3,1,1,4,3,1,1,4,1,1,1,1,3,4,1,1,3,1,1,1,1,3,1,4,1
				db 1,1,4,1,3,1,3,1,1,1,4,1,4,1,1,1,3,1,2,1,1,4,1,2,2,1,1,2,1,4
				db 2,1,1,2,3,2,2,3,3,1,1,1,2

    buffor  db 24 dup(0),'$'
    arg_len db 0
	offs	dw 0
	pusty_ciag	db	"Nie podano cigu.",13,10,'$'
	bledny_znak	db	"Wprowadzono znak, ktorego nie mozna zapisac w CODE-128",13,10,'$'
	zla_dlugosc	db	"Wprowadzono za duzo znakow. (max = 24).",13,10,'$'
	control_char dw 104	;znak kontrolny inicjowany 104 -> START_B
DANE ends
KOD segment

    start_:
		;inicjacja stosu
		mov ax, seg ws
		mov ss, ax
		mov sp, offset ws
	
		
		mov ax, seg buffor
		mov es, ax
		
		call pobierz_dane
		
		call wysrodkuj
		
		;Przejscie do trybu graficznego 320x200 256 kolorow
		mov al, 13h
		mov ah, 0
		int 10h
		
		call cls	;czyszczenie trybu graficznego
		
		;inicjacja odpowiednich rejestrow wykorzystywanych w zapalaniu punktow na ekranie
		mov ax, seg buffor
		mov ds, ax				;ds -> segment danych z ciagiem do zakodowania
		mov ax, 0A000h			
		mov es, ax
		xor di,di				;0A000h:0000	-> poczatek obszaru grafiki
		mov si, offset buffor	
		mov bx, offset bars_array	;tablica z kodami znakow
		
		call STARTB_char
		
		call zakoduj_ciag
		
		call STOP_char
		
		mov al, 0
		out 060h, al
		xor ax,ax
		;odczekiwanie na  klawisz
		get_ESC:	
			in	al,060h
			cmp	al, 1
			je quit
		jmp get_ESC
		
		quit:
		;Zmiana trybu graficznego na tekstowy
		mov ah, 0
		mov al, 3
		int 10h
		
		;Wypisanie na ekran ciagu wpisanego przez uzytkownika, gdyby zapomial co wpisal do porowania
		;mov ah, 9
		;mov dx, offset buffor
		;int 21h
		
		go_end:
		
		mov ah, 04ch
		int 21h

;Wprowadzenie
	Wprowadzenie proc
		;Wprowadzenie do programu
		mov ax, seg intro
		mov ds, ax
		mov ah, 9
		mov dx, offset intro
		int 21h
		jmp go_end
	Wprowadzenie endp
	
;---------------------------------------------------------------------------+
;	pobierz_dane -> pobiera z klawiatury ciago do zakodowania:				|
;	1) obslugiwane sa znaki o kodach ASCII wiekszych od 32					|
;	   poniewaz mniejse nie sa przewidziane w zestawie znakow B				|
;---------------------------------------------------------------------------+
	pobierz_dane proc
		xor ax, ax
		xor cx, cx
		
		mov cl, byte ptr ds:[080h]
		dec cl
		mov byte ptr es:[arg_len], cl	;zachowanie dlugosci ciagu wejsciowego w pamieci

		cmp cl, 0
		jg nie_pusty	;jesli pobrano mozliwy do zakodowania ciag przystepuje do jego kodowania
			call Wprowadzenie
		nie_pusty:
		
		cmp cl, 24
		jle dobra_dlugosc	
			mov ax, seg zla_dlugosc
			mov ds, ax
			mov dx, offset zla_dlugosc
			mov ah, 9
			int 21h
		jmp go_end
			
		dobra_dlugosc:
		mov si, 082h
		mov di, offset buffor
		pobierz_ciag:

			mov al, byte ptr ds:[si]
			cmp al, 32
			jge cnt		;znak mozliwy do zapisu
				jmp	zly_znak
				;jmp pobierz_ciag
			cnt:
			mov byte ptr es:[di], al
			inc di
			inc si
		loop pobierz_ciag
		jmp go_encode
		zly_znak:
			mov ax, seg bledny_znak
			mov ds, ax
			mov ah, 9
			mov dx, offset bledny_znak	;Podano znak ktorego kod ASCII jest mniejszy od 32
			int 21h
		jmp go_end
			
		go_encode:
		mov ax, seg buffor
		mov ds, ax
		ret
	pobierz_dane endp

;-------------------------------------------------------------+
;STARTB_char - koduje znak START_B okreslajacy zestaw znakow  |
;Wymaga zmiennej offs - zawierajacej addres piksela startowego|
;-------------------------------------------------------------+	
	STARTB_char proc
	   mov di, word ptr ds:[offs]
	   add di, 10
	   xor ax, ax
	   mov ax, 104
	   mov dl, 6
	   mul dl
	   push bx
	   add bx, ax
	   mov cx, 6
	   call koduj_znak
	   mov word ptr ds:[offs], di
	   pop bx
	   ret
	STARTB_char endp
	
	zakoduj_ciag proc
		xor cx, cx
		xor dx, dx
		xor ax, ax
		xor di, di
		mov dh, 1 ;licznik znaku
		mov di, word ptr ds:[offs]
		;mov di, ax
		mov ax, 104	;znak kontrolny inicjpwany wartoscia STARTB
		mov cl, byte ptr ds:[arg_len]
		mov si, offset buffor		;ciag do zakodowania
		
		;	zakoduj_znak:
		;	cx -> liczba pobranych znakow
		;	bx -> offset znaku w tablicy bars_array
		;	di -> offset na ekranie
		;	dh -> pozycja znaku w ciagu
		;	dl -> monoznik

		zakoduj_znak:
			push cx
			push dx
			
			mov bx, offset bars_array	;tablica z kodami znakow
			xor ax, ax
			mov al, byte ptr ds:[si]	;pobierz znak do zakodowania
			sub al, 32					;kody zestawu B zaczynaja sie od <SPC> -> kod ASCII 32
			
			push ax
				mul dh
				add word ptr ds:[control_char], ax
			pop ax
			
			mov dl, 6 ;do zapisu kodu 1 znaku wykorzystujemy 3 paski i 3 przewy kazda reprezentowa na przez 1B
			mul dl
			add bx, ax
			xor cx, cx
			mov cx, 6
			call koduj_znak
			pop dx
			pop cx
			inc dh
			inc si
		loop zakoduj_znak
		
		;Kod ponizej odpowiada za wyliczenie i wyswietlenie znaku kontrolnego
		xor ax, ax
		xor dx, dx
		mov ax, word ptr ds:[control_char]
		mov bx, 103
		div bx		;kod znaku kontrolnego jest rowny reszcie z dzielenia sumy kontrolnej przez 103
		xchg dx, ax
		mov dl, 6
		mul dl
		mov bx, offset bars_array
		add bx, ax
		mov cx, 6
		call koduj_znak
		ret
	zakoduj_ciag endp
	
;------------------------------------------------------------------------------+
;STOP_char zapisuje na ekran znak stopu										   |
;Zakaladam ze STOP_char jest wywlywana po zakoduj_ciag						   |
;oraz es:[di] wskazuja piksel startowy										   |
;------------------------------------------------------------------------------+
	STOP_char proc
		mov cx,	7 ;3 przerwy 4 paski
		mov bx, offset bars_array
		add bx, 636	;wczesniej wyliczony "offset" znaku stopu = 106*6
		call koduj_znak
		ret
	STOP_char endp

;---------------------------------------------------------------------------+
;	char_encode zapisuje do pamieci pojedynczy znak ASCII w CODE-128		|
;	Przyjmuje parametry:													|
;	al -> kolor paska		-												|
;	bx -> offset pierwszego paska (w talbicy bars_array)					|
;	di -> punkt startowy w obszarze pamieci grafiki							|
;	dx -> |																	|
;---------------------------------------------------------------------------+
	koduj_znak proc
		push dx
		xor dx, dx
		
		;Kolorowanie bialy/czarny
		mov dl, 15 ; bialy na start
		stop:
			
			push cx
			push di
			mov cx, 100
			
			cmp dl, 15
			je chg
			mov dl, 15
			jmp w3
			chg:
			xor dx, dx
			w3:
				push cx
				;xor cx, cx
				mov cl, byte ptr ds:[bx]
				push di
				p3:	
					;push cx
					mov byte ptr es:[di], dl
					inc di
					;pop cx
				loop p3
				pop di
				add di, 320	;przejscie do nowej lini
				pop cx
			loop w3
			
			xor ax, ax
			pop di
			mov al, byte ptr ds:[bx]
			add di, ax
			inc bx		;kolejny modul kodu
			pop cx
			
		loop stop
		
		pop dx
		ret
	koduj_znak endp 
	
;---------------------------------------------------------------------------+
;	Oblicznie wysrodkowania kodu na ekranie wymaga zmiennej arg_len (1B) 	|
;---------------------------------------------------------------------------+
	
	wysrodkuj proc
		push ax
		push cx
		xor ax, ax
		xor cx, cx
		mov cl,byte ptr ds:[arg_len]
		add cx, 4	; dodaje 4 znaki do pobranego ciagu ( START_B, 2xQuietZone, STOP)
		mov ax, 28	;28 to maksymala liczba znakow mozliwa do zapisana przy 200px 
		sub ax, cx
		shr al, 1	;dzielenie przez 2
		mov cl, 11	;jeden znak 11 px
		mul cl
		xor ah, ah
		add ax, (320*50)	;50 px w dol + 10px w wierszu (QuietZone)
		mov word ptr ds:[offs], ax
		pop cx
		pop ax
		ret
	wysrodkuj endp
				
	;CLS nie przyjmuje argumentow wypelnia pamiec grafiki bialym kolorem
	cls proc
		push cx
		mov ax, 0A000h
		mov es, ax
		xor di,di
		mov cx, 200
		wi:
			push cx
			mov cx, 320
			ko:
				push cx
				mov byte ptr es:[di], 0fh ;0f -> bialy
				inc di
				pop cx
			loop ko
			pop cx
		loop wi
		pop cx
		ret
	cls endp 
		
KOD ends

stosik segment stack
		dw 256 dup(?)
	ws	dw ?
stosik ends

end start_
