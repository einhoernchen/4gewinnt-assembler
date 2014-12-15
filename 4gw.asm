; 4gw.asm
; 
; 4-Gewinnt als 64-Bit assembler unter Linux :)
; ma gucken ob das klappt

; hier kommen die daten rein also strings und variablen und so
section	.data
	hallo_msg	db 10,10,10,"Hallo und willkommen bei"
			db " 4 gewinnt in 64bit Assembler für Linux"
			db 10,10,10 ; 10 = \n
	hallo_msg_l	equ $-hallo_msg		; String länge
	; oben und unten vom brett
	brett_o_u	db "  +---+---+---+---+---+---+---+",10
	brett_o_u_l	equ $-brett_o_u		; länge
	; linker rand von jeder zelle und rechts auch
	brett_l_r	db " |"
	brett_l_r_l	equ $-brett_l_r
	; Leerzeichen
	leerzeichen	db " "
	leerzeichen_l	equ $-leerzeichen
	; die spielers
	spieler_1	db "o"
	spieler_1_l	equ $-spieler_1
	spieler_2	db "x"
	spieler_2_l	equ $-spieler_2
	; das spielbrett. Am anfang sind noch alle 6 * 7 felder leer
	spielbrett	db 1,0,0,0,0,0,0
			db 0,0,0,2,0,0,0
			db 0,0,0,0,0,0,0
			db 0,0,0,0,0,0,0
			db 0,0,0,0,0,0,0
			db 0,0,0,0,0,0,0
	spielbrett_l	equ $-spielbrett
	; die spaltennummern 
	spaltennummern	db "    1   2   3   4   5   6   7",10,10,10
	spaltennummern_l equ $-spaltennummern
	; NewLine
	newline		db 10
	newline_l	equ $-newline
	feddisch	db 0			; wenn feddisch 1 oder 2 hat einer gewonnt
	frage_zug	db "Bitte gib deinen Zug ein (1 - 7): "
	frage_zug_l	equ $-frage_zug
	eingabe		times 10 db 0			; die eingabe vom spieler 
	eingabe_l	equ $-eingabe			; reserviere mal 10 byte für evtl später
	spieler		db 1				; der aktuelle spieler halt
	sieger		db 0				; spieler der wo gewonnen hat

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hier is das Programm
section	.text
global _start					; Hey linker hier bin ich
_start:						; main ()
; zuerst hallo_msg ausgeben
	mov	rax, 0x1			; rax = 1 -> code für write()
	mov	rdi, 0x1			; rdi = 1 -> code für stdout
	mov 	rsi, hallo_msg			; rsi = (addr)hallo_msg
	mov	rdx, hallo_msg_l		; rdx = die länge halt
	syscall					; kernel, tu was (write(stdout...))
; spielbrett ausgeben 
; c calling convention kapier ich ned ganz -> meine calling convention
; die funktion muss alle register die wo sie verändert selber sichern und vorm 
; return wieder herstellen :)
	call	spielbrett_anzeigen		; ne funktion halt :)
spiel_schleife:
	mov	esi, feddisch			; adresse von feddisch nach esi
	lodsb					; hole wert nach al
	cmp	al,0				; is 0?
	jne	_ende				; ok ende, sonst weiter
; spiel noch ned zu ende -> eingabe abfragen
	call	mache_zug			; noch ne funktion 




_ende:						; Hier ist das prog zu ende
	mov	rax, 60				; rax = 60 -> code für exit()
	xor	rdi, rdi			; rdi = 0 -> retörncode
	syscall					; kernel tu was (exit(0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Hier wird das Spielbrett angezeigt
; fürs drucken brauch ich Register rax, rdi, rsi und rdx
; auserdem brauch ich noch zwei schleifen i und j. auserdem brauch ich noch
; eine variable  wo dann auf das Spielbrett zeigt damit ich rauslesen kann wer drauf is
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spielbrett_anzeigen:
	; Register sichern
	push	rax
	push	rbx
	push	rdi
	push 	rsi
	push	rdx
	push	rbp
	push	rsp

	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, brett_o_u			; 1. Zeile (Rahmen)
	mov	rdx, brett_o_u_l		; länge
	syscall
	mov	bl, 5				; bl = 5 (i als Schleifenvar für zeilen)

schleife_i:					; Zeilenweise	
	mov	bh, 0				; bh = 0 (j als schleifenvar für spalten)
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, leerzeichen		; rsi = (addr) leerzeichen wg. Rand
	mov	rdx, leerzeichen_l		; rdx = (addr) länge
	syscall

	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, brett_l_r			; rsi = (addr) senkr. strich
	mov	rdx, brett_l_r_l		; rdx = (addr) länge
	syscall					; schreibs hin

schleife_j:					; spaltenweise
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, leerzeichen		; rsi = (addr) leerzeichen
	mov	rdx, leerzeichen_l		; rdx = (addr) länge
	syscall					; schreiben

	; jetzt den Feldinhalt ausgeben. Aktuelles Feld errechnet sich aus
	; (addr)spielfeld +(bl*7)+bh (hoff ich)
	; hab noch kein plan wie drum isses glaub ich unnötig umständlich
	; vielleicht hat ja jemand n tipp wie das besser geht ;)
	push	bx				; bl sichern
	mov	al, 7				; al = 7
	imul	bl				; ax = bl * 7
	add	al, bh				; al += bh
						; jetzt müsste der richtige index in al stehn
	mov	ebx, spielbrett			; adresse von spielbrett nach ebx
	xlatb					; wert von spielbrett+al -> al

	cmp 	byte al,2			; al = 2? (also spieler 2)
	jne	test_sp_1			; nein? dann vieleicht spieler 1
druck_o:
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, spieler_2			; ja?,"o" ausgeben
	mov	rdx, spieler_2_l
	jmp	test_ende			; und raus hier
test_sp_1:
	cmp 	byte al,1			; Spieler 1 auf dem feld?
	jne	druck_leer			; nein? dann isses leer
druck_x:
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, spieler_1			; "x" ausgeben
	mov	rdx, spieler_1_l
	jmp	test_ende
druck_leer:
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, leerzeichen		; leerzeichen ausgeben
	mov	rdx, leerzeichen_l
test_ende:
	syscall					; und aufn schirm damit
		
	pop	bx				; altes bl wieder holen

	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, brett_l_r			; rsi ) (addr) senkr. strich
	mov	rdx, brett_l_r_l		; rdx = (addr) länge
	syscall					; schreiben
	
	inc	bh				; bh++
	cmp	bh, 7				; bh == 7?
	jl	schleife_j			; j < 7, nochmal
	
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov 	rsi, newline			; \n
	mov 	rdx, newline_l			; länge
	syscall
	
	dec	bl				; bl--
	cmp	bl, 0				; bl == 0?
	jge	schleife_i			; >= 0: nächste Zeile
	
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, brett_o_u			; rsi = (addr)brett_o_u
	mov	rdx, brett_o_u_l		; rdx = (addr)länge
	syscall
	
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, spaltennummern		; rsi = (addr)spaltennummern
	mov	rdx, spaltennummern_l		; rdx = (addr)länge
	syscall

	; Register wieder herstelln
	pop 	rsp
	pop 	rbp
	pop 	rdx
	pop	rsi
	pop	rdi
	pop	rbx
	pop	rax
	ret					; und wieder zurück

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mache_zug
; funktion die wo ne eingabe vom stdin nimmt und nen zug berechnen tut
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mache_zug:

	; Register sichern
	push	rax
	push	rbx
	push	rdi
	push 	rsi
	push	rdx
	push	rbp
	push	rsp

_frage_zug:
	mov	rax, 0x1			; write()
	mov	rdi, 0x1			; -> stdout
	mov	rsi, frage_zug			; rsi = (addr)fragezug
	mov	rdx, frage_zug_l		; rdx = (addr)länge
	syscall

	; die Eingabe hier:
	mov	rax, 0x0			; read()
	mov 	rdi, 0x0			; stdin
	mov	rsi, eingabe			; rsi = (addr) eingabe
	mov	rdx, eingabe_l			; rdx = (addr) länge
	syscall
	
	; Testen ob die eingabe richtig war
	mov 	bx, [eingabe]			; ebx = eingabe
	; brauche jetzt nur al weil kleine zahl
	sub	bl, 48				; bl -= 48 (ascii -> zahl)
	; ist al < 1 oder > 7 -> falsche eingabe -> nochmal
	cmp 	bl,1
	jl	_frage_zug
	cmp	bl,7
	jg	_frage_zug

	; ok dann ham wir was korrektes
	; jetzt checken, ob in der spalte überhaupt noch n stein reinpasst
	mov	bh,0				; zähler für schleife
	dec	bl				; bl-- weil array bei 0 anfängt
_teste_spalte:
	mov	al,7				; al = 7 (faktor für zeilen berechnen)
	imul	bh				; al *= bh (die gesuchte zeile)
	add	al,bl				; noch die eingegebne spalte dazu
	push	rbx				; rbx sichern weils gleich überschriebn wird
	mov	ebx, spielbrett			; startadresse vom spielbrett
	xlatb					; wert von spielbrett+al -> al

	; schon was drin?
	cmp	byte al,0			; al = 0 (also leer)
	je	_schreibe_spieler		; nö, also nächste zeile gucken
	pop	rbx				; und den zähler wieder holen
	inc	bh				; nächste zeile
	cmp 	bh,7				; ham wir noch ne zeile?
	jg	_frage_zug			; dann wars nix, also nochmal
	jmp	_teste_spalte			; ansonsten nächste zeile testen

	; wenn das prog bis hierher kommt müsst an der richtigen stelle ein platz frei sein
_schreibe_spieler:
	pop	rbx				; rbx vom stack holen, in bh ist die zeile, bl spalte
	mov	al, 7				; al = 7
	imul	bh				; al *= bh
	add	al,bl				; al += bl -> die richtige stelle im array
	xor	ah,ah				; nur das in al bleibt übrig, rest von eax auf 0
	lea	ebx, [spielbrett+eax]		; position setzen
	mov	cl, al
	mov	al, byte [spieler]		; al = spieler; welcher spieler is dran?
	mov	[ebx],byte 1			; setze den spielerwert

	call spielbrett_anzeigen		; und neu pinseln
	
	; jetzt dann testen, ob ein spieler schon gewonnen hat oder obs weitergeht
	call teste_gewonnen

	

	; Register wieder herstelln
	pop 	rsp
	pop 	rbp
	pop 	rdx
	pop	rsi
	pop	rdi
	pop	rbx
	pop	rax
	ret					; und wieder zurück

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Testen ob der Spieler gewonnen hat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
teste_gewonnen:
	; boah das wird jetzt kompliziert
	; erst die waagerechten möglichkeiten testen
	; dann senkrecht 
	; und dann auch noch diagonahl ächzuff

	; Register sichern
	push	rax
	push	rbx
	push	rdi
	push 	rsi
	push	rdx
	push	rbp
	push	rsp
	call teste_waagerecht			; 4 waagerecht = gewonnen
	mov al, [gewonnen]			; schon gewinn festgestellt?
	cmp al, 0				; 0 = kein gewinner
	jne test_ende				; sonst fertig mit testen
	call teste_senkrecht			; 4 senkrecht
	mov al, [gewonnen]			; al = gewonnen
	cmp al, 0				; 0 = kein gewinner
	jne test_ende				; es gibt n gewinner
	call teste_diagonal			; also noch diagonal
	mov al, [gewonnen]			; al = gewonnen
	cmp al, 0				; 0 = kein gewinner
	jne test_ende				; es gibt n gewinner
	teste_unentschieden			; evtl alle felder voll und kein gewinner
	mov al, [gewonnen]			; al = gewonnen
	cmp al, 3				; 3 ist halt unentschieden
test_ende:
	; Register wieder herstelln
	pop 	rsp
	pop 	rbp
	pop 	rdx
	pop	rsi
	pop	rdi
	pop	rbx
	pop	rax
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; gibts irgwo 4 waagerecht?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hab grad gelesen, es gibt 8 zusätzliche registers in meim 64bit prozessor
; r8 - 15. das is sau praktisch weil ich die für die variablen nehmen kann
; brauch glaub ich 3 schleifenvariablen und nen zähler. also brauch ich 
; r8 bis r11. das machts leichter als oben im code mit al ah bl bh und so 
; rumgebazel
; Idee:
; für zeile (r8) von 0 bis <6 (alle 7 zeilen testen)
;	für spalte (r9) von 0 bis <4 (aufpassen das ich ned übers array rauslauf)
;		für i (r10) von 0 bis <4
;			wenn (aktueller spieler) in feld spalte+i, zeile steht
;				zähler(r11)++
;			sonst
;				nächste spalte
;		wenn zähler(r11) >= 4
;			gewinner = aktueller spieler
;			ret
; alles durch und kein gewinner
; gewinner = 0
; ret
teste_waagerecht:
	; Register sichern
	push	rax
	push	rbx
	push	rdi
	push 	rsi
	push	rdx
	push	rbp
	push	rsp
	push	r8
	push	r9
	push	r10
	push	r11

_zeilen_schleife_w:
	xor	r8, r8				; r8 = 0 (zeilenzähler)
_spalten_schleife_w:
	xor	r9, r9				; r9 = 0 (spaltenzähler)
	xor	r11, r11			; r11 = 0 (steinchenzähler)
_steinchen_schleife_w:
	xor	r10,10				; r10 = 0 (i)
		

	; Register wieder herstelln
	pop 	r11
	pop	r10
	pop	r9
	pop	r8
	pop 	rsp
	pop 	rbp
	pop 	rdx
	pop	rsi
	pop	rdi
	pop	rbx
	pop	rax
	ret
