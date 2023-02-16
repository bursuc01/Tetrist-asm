.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
game_over dd 0
spin dd 0
locker dd 0
window_title DB "Tetris",0
area_width EQU 588
area_height EQU 686
area DD 0
format db "%d",13,10,0

switch dd 0
area2 dd 130 DUP(0)
area_width2 EQU 10
area_height2 EQU 13

randomizer dd 0
generare_x2 dd 6
generare_y2 dd 0
generare_x DD 294
generare_y DD 0

cadere_y2 dd 0
cadere_x2 dd 6
cadere_x DD 294
cadere_y DD 0

counter DD 0 ; numara evenimentele de tip timer

designx DD 0 ;variabile desen
designy DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
button_x EQU 500
button_y EQU 150
button_size EQU 80

tip0 EQU 0
tip1 EQU 1
tip2 EQU 2
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
;se face linia cu care se creaza patratul
umplere_matrice2 MACRO darea,x,y,tip
pusha
;la coordonatele x si y in matrice pune 0 1 sau 2  
mov eax,y
mov ebx,area_width2
mul ebx
add eax,x
shl eax,2
mov [area2+eax],tip
popa
endm

linie MACRO darea,x,y,len,color
   local bucla_liniee,afara
	pusha
	mov eax,y
	mov ebx,area_width  ; aflarea pozitiei click
    mul ebx
    add eax,x
    shl eax,2
    add eax, darea
    mov edx,len
bucla_liniee:
	mov dword ptr[eax], color ;linia
	add eax,4
	dec edx
	cmp edx,0
	jle afara
	jmp bucla_liniee
	afara:
popa
endm

unitate_patrat MACRO darea, x , y , len , color
	local patrat
	pusha
	mov ecx,len
	mov ebx,y
patrat:
	linie darea,x,ebx,len,color
    inc ebx
loop patrat
	popa
endm

;pisele propriu-zise
piesa_patrat MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push x
   mov ebx,x
   add ebx,49
   mov x,ebx
   unitate_patrat darea,x,y,len,color
   pop x
   push y
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   push x
   mov ebx,x
   add ebx,49
   mov x,ebx
   unitate_patrat darea,x,y,len,color
   pop x
   pop y
   popa
endm

piesa_z MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push x
   mov ebx,x
   add ebx,49
   mov x,ebx
   unitate_patrat darea,x,y,len,color
   push y
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   mov ebx,x
   add ebx,49
   mov x,ebx
   unitate_patrat darea,x,y,len,color
   pop y
   pop x
   popa
endm

piesa_L MACRO darea,x,y,len,color
   pusha
   push x
   push y
   unitate_patrat darea,x,y,len,color
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
    mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   pop y
   pop x
   popa
endm

piesa_L_reverse MACRO darea,x,y,len,color
   pusha
   push x
   push y
   unitate_patrat darea,x,y,len,color
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
    mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   mov eax,x
   sub eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   pop y
   pop x
   popa
endm

piesa_linie MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push y
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
    mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   pop y
   popa
endm

piesa_z_reverse MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push x
   mov ebx,x
   sub ebx,49
   mov x,ebx
   unitate_patrat darea,x,y,len,color
   push y
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
   mov ebx,x
   sub ebx,49
   mov x,ebx
   unitate_patrat darea,x,y,len,color
   pop y
   pop x
   popa
endm

piesa_z_culcat MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push y
   mov ebx,y
   add ebx,len
   mov y,ebx
   unitate_patrat darea,x,y,len,color
   push x
   mov eax,x
   sub eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   mov ebx,y
   add ebx,len
   mov y,ebx
   unitate_patrat darea,x,y,len,color
   pop x
   pop y
   popa
endm

piesa_linie_culcat MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push x
   mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   pop x
   popa
endm

piesa_z_reverse_culcat MACRO darea,x,y,len,color
   pusha
   unitate_patrat darea,x,y,len,color
   push y
   mov ebx,y
   add ebx,len
   mov y,ebx
   unitate_patrat darea,x,y,len,color
   push x
   mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   mov ebx,y
   add ebx,len
   mov y,ebx
   unitate_patrat darea,x,y,len,color
   pop x
   pop y
   popa
endm

piesa_L_reverse_culcat MACRO darea,x,y,len,color
   pusha
   push x
   push y
   unitate_patrat darea,x,y,len,color
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
    mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   mov eax,x
   add eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   pop y
   pop x
   popa
endm
 
piesa_L_culcat MACRO darea,x,y,len,color
   pusha
   push x
   push y
   unitate_patrat darea,x,y,len,color
   mov eax,y
   add eax,len
   mov y,eax
   unitate_patrat darea,x,y,len,color
    mov eax,x
   sub eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   mov eax,x
   sub eax,49
   mov x,eax
   unitate_patrat darea,x,y,len,color
   pop y
   pop x
   popa
endm
;initializarea x-ului si y-ului pentru o noua piesa!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
initialize MACRO 
pusha

mov spin,0

mov eax,generare_x
mov cadere_x,eax

mov eax,generare_y
mov cadere_y,eax

mov eax,generare_x2
mov cadere_x2,eax

mov eax,generare_y2
mov cadere_y2,eax

popa
endm

;Macro-urile pentru cazut si oprit piesa L
miscare_piesa_L_culcat MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta

cmp cadere_x2,3
je cmp_dreapta
oprire_piesa_L_culcat cadere_x2,cadere_y2,tip0
;zone coliziune piese
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	sub eax,8
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	
piesa_L_culcat area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_L_culcat cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,10
je cmp_out
oprire_piesa_L_culcat cadere_x2,cadere_y2,tip0
;zona cadere piesa
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	

piesa_L_culcat area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_L_culcat cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_L_culcat MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,11
	jge stop
	oprire_piesa_L_culcat cadere_x2,cadere_y2,tip0
	;zona coliziune alta piesa
	mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8*area_width2
	
	cmp[area2+eax],tip2
	je stop
	
	sub eax,4
	cmp[area2+eax],tip2
	je stop
	
	sub eax,4
	cmp[area2+eax],tip2
	je stop
	
	
    piesa_L_culcat area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
    oprire_piesa_L_culcat cadere_x2,cadere_y2,tip1
	piesa_L_culcat area,cadere_x,cadere_y,49,0FF8000h
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_L_culcat cadere_x2,cadere_y2,tip2
	piesa_L_culcat area,cadere_x,cadere_y,49,0FF8000h
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_L_culcat MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;zona piesa_reverse_L
miscare_piesa_L_reverse MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta

cmp cadere_x2,2
je cmp_dreapta
oprire_piesa_L_reverse cadere_x2,cadere_y2,tip0
;zone coliziune piese
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	
piesa_L_reverse area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_L_reverse cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,10
je cmp_out
oprire_piesa_L_reverse cadere_x2,cadere_y2,tip0
;zona cadere piesa
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	

piesa_L_reverse area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_L_reverse cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_L_reverse MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,10
	jge stop
	oprire_piesa_L_reverse cadere_x2,cadere_y2,tip0
	;zona coliziune alta piesa
	mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,12*area_width2
	
	cmp[area2+eax],tip2
	je stop
	
	sub eax,4
	cmp[area2+eax],tip2
	je stop
	
	
    piesa_L_reverse area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
    oprire_piesa_L_reverse cadere_x2,cadere_y2,tip1
	piesa_L_reverse area,cadere_x,cadere_y,49,0F300FFh	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_L_reverse cadere_x2,cadere_y2,tip2
	piesa_L_reverse area,cadere_x,cadere_y,49,0F300FFh
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_L_reverse MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

miscare_piesa_L MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta

cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_L cadere_x2,cadere_y2,tip0
;zone coliziune piese
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	
piesa_L area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_L cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,9
je cmp_out
oprire_piesa_L cadere_x2,cadere_y2,tip0
;zona cadere piesa
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	

piesa_L area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_L cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_L MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,10
	jge stop
	oprire_piesa_L cadere_x2,cadere_y2,tip0
	;zona coliziune alta piesa
	mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,12*area_width2
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	cmp[area2+eax],tip2
	je stop
	
	
    piesa_L area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
    oprire_piesa_L cadere_x2,cadere_y2,tip1
	piesa_L area,cadere_x,cadere_y,49,0FF8000h	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_L cadere_x2,cadere_y2,tip2
	piesa_L area,cadere_x,cadere_y,49,0FF8000h
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_L MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm


;Macro-urile pentru cazut si oprit piesa linie
miscare_piesa_linie MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_linie cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	cmp [area2+eax],2
	je cmp_dreapta
	
piesa_linie area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_linie cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,10
je cmp_out
oprire_piesa_linie cadere_x2,cadere_y2,tip0
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	cmp [area2+eax],2
	je cmp_out
	
piesa_linie area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_linie cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_linie MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,9
	jge stop
	oprire_piesa_linie cadere_x2,cadere_y2,tip0
	
    piesa_linie area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
    oprire_piesa_linie cadere_x2,cadere_y2,tip1
	;zona cadere piesa linie
	mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,16*area_width2
	
	cmp[area2+eax],tip2
	je stop
	
	piesa_linie area,cadere_x,cadere_y,49,000FF00h	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_linie cadere_x2,cadere_y2,tip2
	piesa_linie area,cadere_x,cadere_y,49,000FF00h 
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	
	alta_data:
	popa
endm

oprire_piesa_linie MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;Macro-urile pentru cazut si oprit piesa z
miscare_piesa_z MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_z cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	add eax,4
	cmp [area2+eax],2
	je cmp_dreapta
	
piesa_z area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_z cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,8
je cmp_out
oprire_piesa_z cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	add eax,4
	cmp [area2+eax],2
	je cmp_out
	
piesa_z area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_z cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_z MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,11
	jge stop
	oprire_piesa_z cadere_x2,cadere_y2,tip0
	
	;cod pentru coliziune cu alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4*area_width2

  
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4*area_width2
	add eax,4
 
	cmp[area2+eax],tip2
	je stop
	
	add eax,4

	cmp[area2+eax],tip2
	je stop
	
    piesa_z area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
   
	oprire_piesa_z cadere_x2,cadere_y2,tip1
	piesa_z area,cadere_x,cadere_y,49,0F0FF00h	
	jmp alta_data
	stop:
	;initializare

	oprire_piesa_z cadere_x2,cadere_y2,tip2
	piesa_z area,cadere_x,cadere_y,49,0F0FF00h	
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_z MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;Macro-urile pentru cazut si oprit piesa z_reverse
miscare_piesa_z_reverse MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,3
je cmp_dreapta
oprire_piesa_z_reverse cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,8
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	sub eax,4
	cmp [area2+eax],2
	je cmp_out
	
piesa_z_reverse area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_z_reverse cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,10
je cmp_out
oprire_piesa_z_reverse cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	sub eax,8
	cmp [area2+eax],2
	je cmp_out
	
piesa_z_reverse area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_z_reverse cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_z_reverse MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,11
	jge stop
	oprire_piesa_z_reverse cadere_x2,cadere_y2,tip0
	
	;cod pentru coliziune cu alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4*area_width2

  
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4*area_width2
	sub eax,4
 
	cmp[area2+eax],tip2
	je stop
	
	sub eax,4

	cmp[area2+eax],tip2
	je stop
	
    piesa_z_reverse area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
   
	oprire_piesa_z_reverse cadere_x2,cadere_y2,tip1
	piesa_z_reverse area,cadere_x,cadere_y,49,000FFFBh	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_z_reverse cadere_x2,cadere_y2,tip2
	piesa_z_reverse area,cadere_x,cadere_y,49,000FFFBh	
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_z_reverse MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;Macro-urile pentru cazut si oprit piesa patrat
miscare_piesa_patrat MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_patrat cadere_x2,cadere_y2,tip0
;cod pentru coliziune cu alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
piesa_patrat area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_patrat cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,9
je cmp_out
oprire_piesa_patrat cadere_x2,cadere_y2,tip0
 ;zona coliziune alta piesa
 mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
piesa_patrat area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_patrat cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_patrat MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	

	jne o_secunda
    cmp cadere_y2,11
	jge stop	
	oprire_piesa_patrat cadere_x2,cadere_y2,tip0
    
	;cod pentru coliziune cu alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8*area_width2
	  
  
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	  
 
	cmp[area2+eax],tip2
	je stop
	


	piesa_patrat area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:

    oprire_piesa_patrat cadere_x2,cadere_y2,tip1
	piesa_patrat area,cadere_x,cadere_y,49,00000FFh	
	jmp alta_data
	stop:
	;initializare
    oprire_piesa_patrat cadere_x2,cadere_y2,tip2
	piesa_patrat area,cadere_x,cadere_y,49,00000FFh
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx

	alta_data:
	popa
endm

oprire_piesa_patrat MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2 
  
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;zona pentru piesele culcate si in alte unghiuri
;zona pentru piese culcate!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
miscare_piesa_L_reverse_culcat MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta

cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip0
;zone coliziune piese
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	
piesa_L_reverse_culcat area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,8
je cmp_out
oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip0
;zona cadere piesa
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	add eax,8
	cmp [area2+eax],2
	je cmp_out
	

piesa_L_reverse_culcat area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_L_reverse_culcat MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,11
	jge stop
	oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip0
	;zona coliziune alta piesa
	mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8*area_width2
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	cmp[area2+eax],tip2
	je stop
	
	
    piesa_L_reverse_culcat area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
    oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip1
	piesa_L_reverse_culcat area,cadere_x,cadere_y,49,0F300FFh	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_L_reverse_culcat cadere_x2,cadere_y2,tip2
	piesa_L_reverse_culcat area,cadere_x,cadere_y,49,0F300FFh
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_L_reverse_culcat MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

miscare_piesa_linie_culcat MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	
piesa_linie_culcat area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,7
je cmp_out
oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip0
mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,16
	
	cmp [area2+eax],2
	je cmp_out
	
	
piesa_linie_culcat area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_linie_culcat MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,12
	jge stop
	oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip0
	
    piesa_linie_culcat area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
    oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip1
	;zona cadere piesa linie
	mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4*area_width2
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4
	
	cmp[area2+eax],tip2
	je stop
	
	piesa_linie_culcat area,cadere_x,cadere_y,49,000FF00h	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_linie_culcat cadere_x2,cadere_y2,tip2
	piesa_linie_culcat area,cadere_x,cadere_y,49,000FF00h 
	initialize 
	mov switch,0
	alta_data:
	popa
endm

oprire_piesa_linie_culcat MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;piesa z reverse culcat
miscare_piesa_z_reverse_culcat MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,1
je cmp_dreapta
oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2

	cmp [area2+eax],2
	je cmp_out

    add eax,4
    add	eax,4*area_width2
	
	cmp[area2+eax],2
	je cmp_out
	
piesa_z_reverse_culcat area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,9
je cmp_out
oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	add eax,4
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2
	
	cmp [area2+eax],2
	je cmp_out
	
piesa_z_reverse_culcat area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_z_reverse_culcat MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,10
	jge stop
	oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip0
	
	;cod pentru coliziune cu alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8*area_width2

  
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4*area_width2
	add eax,4
 
	cmp[area2+eax],tip2
	je stop
	
	
    piesa_z_reverse_culcat area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
   
	oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip1
	piesa_z_reverse_culcat area,cadere_x,cadere_y,49,000FFFBh	
	jmp alta_data
	stop:
	;initializare
	oprire_piesa_z_reverse_culcat cadere_x2,cadere_y2,tip2
	piesa_z_reverse_culcat area,cadere_x,cadere_y,49,000FFFBh	
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_z_reverse_culcat MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;piesa_z
miscare_piesa_z_culcat MACRO 
    local cmp_dreapta,cmp_out
pusha

mov edx,[ebp+arg2]
cmp edx,25h 
jne cmp_dreapta
cmp cadere_x2,2
je cmp_dreapta
oprire_piesa_z_culcat cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	sub eax,4
	
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	sub eax,4
	cmp [area2+eax],2
	je cmp_dreapta
	
	add eax,4*area_width2
	cmp [area2+eax],2
	je cmp_dreapta
	
piesa_z_culcat area,cadere_x,cadere_y,49,010000h
sub cadere_x,49
sub cadere_x2,1 
oprire_piesa_z_culcat cadere_x2,cadere_y2,tip1
  
cmp_dreapta:
cmp edx,27h
jne cmp_out
cmp cadere_x2,10
je cmp_out
oprire_piesa_z_culcat cadere_x2,cadere_y2,tip0
;zona coliziune alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,4
	
	cmp [area2+eax],2
	je cmp_out
	
	add eax,4*area_width2

	cmp [area2+eax],2
	je cmp_out

    add eax,4*area_width2
    sub eax,4
   
    cmp [area2+eax],2
    je cmp_out
   
piesa_z_culcat area,cadere_x,cadere_y,49,010000h
add cadere_x,49
add cadere_x2,1
oprire_piesa_z_culcat cadere_x2,cadere_y2,tip1
cmp_out:

popa
endm

cadere_piesa_z_culcat MACRO counter
    local alta_data,o_secunda,stop
    pusha
	;numaram intervalele de timp
	mov eax,counter
	mov ebx,2
	xor edx,edx
	div ebx
	cmp edx,0
	jne o_secunda
	
	cmp cadere_y2,10
	jge stop
	oprire_piesa_z_culcat cadere_x2,cadere_y2,tip0
	
	;cod pentru coliziune cu alta piesa
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2
	add eax,8*area_width2

  
	
	cmp[area2+eax],tip2
	je stop
	
	add eax,4*area_width2
	sub eax,4
 
	cmp[area2+eax],tip2
	je stop
	
    piesa_z_culcat area,cadere_x,cadere_y,49,010000h
    add cadere_y,49	
	add cadere_y2,1
    
	o_secunda:
   
	oprire_piesa_z_culcat cadere_x2,cadere_y2,tip1
	piesa_z_culcat area,cadere_x,cadere_y,49,0F0FF00h	
	jmp alta_data
	stop:
	;initializare

	oprire_piesa_z_culcat cadere_x2,cadere_y2,tip2
	piesa_z_culcat area,cadere_x,cadere_y,49,0F0FF00h	
	initialize 
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	alta_data:
	popa
endm

oprire_piesa_z_culcat MACRO cadere_x2,cadere_y2,tip
    pusha	
	push cadere_x2
	push cadere_y2
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	sub cadere_x2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	add cadere_y2,1
	umplere_matrice2 area2,cadere_x2,cadere_y2,tip
	pop cadere_y2
	pop cadere_x2
	popa
endm

;zona pentru rotatia pieselor !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
cadere_spin_piesa_linie MACRO 
local heya1,heya2,spin_bot,salt1,salt2
pusha
cmp spin,0
jne salt1
cmp locker,1
jne heya1
piesa_linie_culcat area,cadere_x,cadere_y,49,010000h
mov locker,0
heya1:
cadere_piesa_linie counter
salt1:

cmp spin,1
jne salt2
cmp locker,1
jne heya2
piesa_linie area,cadere_x,cadere_y,49,010000h
mov locker,0
heya2:
cadere_piesa_linie_culcat counter
salt2:
popa
endm

miscare_spin_piesa_linie MACRO
local hol,col,spin_bot,salt1,salt2,spin_bot0,spin_bot1
pusha
mov edx,[ebp+arg2]
cmp edx,26h
jne spin_bot
mov locker,1
;vom verifica daca piesa se poate roti
    mov eax,cadere_y2
	mov ebx,area_width2
	mul ebx
	add eax,cadere_x2
	shl eax,2

add eax,4	
cmp [area2+eax],2
je spin_bot 
add eax,4*area_width2
cmp [area2+eax],2
je spin_bot
add eax,4*area_width2
cmp [area2+eax],2
je spin_bot
add eax,4*area_width2
cmp [area2+eax],2
je spin_bot


;piesa nu se invarte cand urmeaza sa ajunga jos
cmp cadere_x2,7
jle hol
piesa_linie area,cadere_x,cadere_y,49,010000h
mov cadere_x2,7
mov cadere_x,343
hol:

cmp cadere_y2,9
jle col
piesa_linie_culcat area,cadere_x,cadere_y,49,010000h
mov cadere_y2,9
mov cadere_y,441
mov locker,1
col:

cmp spin,0
jne spin_bot0
add spin,1
jmp spin_bot
spin_bot0:
cmp spin,1
jne spin_bot1
sub spin,1
spin_bot1:
spin_bot:

cmp spin,0
jne salt1
miscare_piesa_linie
salt1:
cmp spin,1
jne salt2
miscare_piesa_linie_culcat
salt2:
endm

;pieza z reversed culcat
cadere_spin_piesa_z_reverse MACRO 
local heya1,heya2,spin_bot,salt1,salt2
pusha
cmp spin,0
jne salt1
cmp locker,1
jne heya1
piesa_z_reverse_culcat area,cadere_x,cadere_y,49,010000h
mov locker,0
heya1:
cadere_piesa_z_reverse counter
salt1:

cmp spin,1
jne salt2
cmp locker,1
jne heya2
piesa_z_reverse area,cadere_x,cadere_y,49,010000h
mov locker,0
heya2:
cadere_piesa_z_reverse_culcat counter
salt2:
popa
endm

miscare_spin_piesa_z_reverse MACRO
local rasarit,less,hol,col,spin_bot,salt1,salt2,spin_bot0,spin_bot1
pusha
mov edx,[ebp+arg2]
cmp edx,26h
jne spin_bot
mov locker,1
;nu se invarte daca e in colturi
cmp spin,1
jne rasarit

cmp cadere_x2,2
jle spin_bot
rasarit:
cmp cadere_x2,10
jge spin_bot



cmp spin,0
jne spin_bot0
add spin,1
jmp spin_bot
spin_bot0:
cmp spin,1
jne spin_bot1
sub spin,1
spin_bot1:
spin_bot:

cmp spin,0
jne salt1
miscare_piesa_z_reverse
salt1:
cmp spin,1
jne salt2
miscare_piesa_z_reverse_culcat
salt2:
popa
endm

;piesa_z rotire
cadere_spin_piesa_z MACRO 
local heya1,heya2,spin_bot,salt1,salt2
pusha
cmp spin,0
jne salt1
cmp locker,1
jne heya1
piesa_z_culcat area,cadere_x,cadere_y,49,010000h
mov locker,0
heya1:
cadere_piesa_z counter
salt1:

cmp spin,1
jne salt2
cmp locker,1
jne heya2
piesa_z area,cadere_x,cadere_y,49,010000h
mov locker,0
heya2:
cadere_piesa_z_culcat counter
salt2:
popa
endm

miscare_spin_piesa_z MACRO
local rasarit,less,hol,col,spin_bot,salt1,salt2,spin_bot0,spin_bot1
pusha
mov edx,[ebp+arg2]
cmp edx,26h
jne spin_bot
mov locker,1
;nu se invarte daca e in colturi
cmp spin,1
jne rasarit

cmp cadere_x2,2
jle spin_bot
rasarit:
cmp cadere_x2,9
jge spin_bot



cmp spin,0
jne spin_bot0
add spin,1
jmp spin_bot
spin_bot0:
cmp spin,1
jne spin_bot1
sub spin,1
spin_bot1:
spin_bot:

cmp spin,0
jne salt1
miscare_piesa_z
salt1:
cmp spin,1
jne salt2
miscare_piesa_z_culcat
salt2:
popa
endm


cadere_spin_piesa_L_reverse MACRO 
local heya1,heya2,spin_bot,salt1,salt2
pusha
cmp spin,0
jne salt1
cmp locker,1
jne heya1
piesa_L_reverse_culcat area,cadere_x,cadere_y,49,010000h
mov locker,0
heya1:
cadere_piesa_L_reverse counter
salt1:

cmp spin,1
jne salt2
cmp locker,1
jne heya2
piesa_L_reverse area,cadere_x,cadere_y,49,010000h
mov locker,0
heya2:
cadere_piesa_L_reverse_culcat counter
salt2:
popa
endm

miscare_spin_piesa_L_reverse MACRO
local rasarit,less,hol,col,spin_bot,salt1,salt2,spin_bot0,spin_bot1
pusha
mov edx,[ebp+arg2]
cmp edx,26h
jne spin_bot
mov locker,1
;nu se invarte daca e in colturi
cmp spin,1
jne rasarit

cmp cadere_x2,1
jle spin_bot
rasarit:
cmp cadere_x2,8
jge spin_bot



cmp spin,0
jne spin_bot0
add spin,1
jmp spin_bot
spin_bot0:
cmp spin,1
jne spin_bot1
sub spin,1
spin_bot1:
spin_bot:

cmp spin,0
jne salt1
miscare_piesa_L_reverse
salt1:
cmp spin,1
jne salt2
miscare_piesa_L_reverse_culcat
salt2:
popa
endm

cadere_spin_piesa_L MACRO 
local heya1,heya2,spin_bot,salt1,salt2
pusha
cmp spin,0
jne salt1
cmp locker,1
jne heya1
piesa_L_culcat area,cadere_x,cadere_y,49,010000h
mov locker,0
heya1:
cadere_piesa_L counter
salt1:

cmp spin,1
jne salt2
cmp locker,1
jne heya2
piesa_L area,cadere_x,cadere_y,49,010000h
mov locker,0
heya2:
cadere_piesa_L_culcat counter
salt2:
popa
endm

miscare_spin_piesa_L MACRO
local rasarit,less,hol,col,spin_bot,salt1,salt2,spin_bot0,spin_bot1
pusha
mov edx,[ebp+arg2]
cmp edx,26h
jne spin_bot
mov locker,1
;nu se invarte daca e in colturi
cmp spin,1
jne rasarit

cmp cadere_x2,3
jle spin_bot
rasarit:
cmp cadere_x2,10
jge spin_bot



cmp spin,0
jne spin_bot0
add spin,1
jmp spin_bot
spin_bot0:
cmp spin,1
jne spin_bot1
sub spin,1
spin_bot1:
spin_bot:

cmp spin,0
jne salt1
miscare_piesa_L
salt1:
cmp spin,1
jne salt2
miscare_piesa_L_culcat
salt2:
popa
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax,24
	cmp [area2+eax],2
	jne game_done
	cmp game_over,1
	je gata_e_tot
	mov game_over,1
	game_done:
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	cmp eax,3
	jz evt_tasta
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	jmp afisare_generala
	
evt_click:
	;piesa_patrat area,[ebp+arg2],[ebp+arg3],49,03E9FAh
	;piesa_z area,[ebp+arg2],[ebp+arg3],49,0F4ED08h
	;piesa_L area,[ebp+arg2],[ebp+arg3],49,0F4ED08h
	;piesa_linie area,[ebp+arg2],[ebp+arg3],49,0FF0000h
	;piesa_z_reverse area,[ebp+arg2],[ebp+arg3],49,0FF0000h
	;piesa_L_reverse area,[ebp+arg2],[ebp+arg3],49,0FF0000h
	;piesa_linie_culcat area,[ebp+arg2],[ebp+arg3],49,0FF0000h
	;piesa_z_culcat area,[ebp+arg2],[ebp+arg3],49,0F0FF00h
	;piesa_z_reverse_culcat area,[ebp+arg2],[ebp+arg3],49,0F0FF00h
	;piesa_L_culcat area,[ebp+arg2],[ebp+arg3],49,0F0FF00h
	jmp afisare_generala
	
evt_timer:
	inc counter
	
	cmp switch,0
	jne alta_piesac1
	cadere_piesa_patrat counter
	alta_piesac1:
	cmp switch,1
	jne alta_piesac2
	cadere_spin_piesa_z
	alta_piesac2:
	cmp switch,2
	jne alta_piesac3
	cadere_spin_piesa_L_reverse
	alta_piesac3:
	cmp switch,3
	jne alta_piesac4
	cadere_spin_piesa_z_reverse 
	alta_piesac4:
	cmp switch,4
	jne alta_piesac5
	cadere_spin_piesa_L
    alta_piesac5:
	cmp switch,5
	jne alta_piesac6
	cadere_spin_piesa_linie 
	alta_piesac6:
	jmp afisare_generala
evt_tasta:

 cmp switch,0
 jne alta_piesam1
miscare_piesa_patrat
alta_piesam1:
cmp switch,1
jne alta_piesam2
miscare_spin_piesa_z
alta_piesam2:
cmp switch,2
jne alta_piesam3
miscare_spin_piesa_L_reverse
alta_piesam3:
 cmp switch,3
 jne alta_piesam4
 miscare_spin_piesa_z_reverse
 alta_piesam4:
 cmp switch,4
jne alta_piesam5
miscare_spin_piesa_L
 alta_piesam5:
cmp switch,5
jne alta_piesam6
miscare_spin_piesa_linie 
alta_piesam6:

mov edx,[ebp+arg2]
  cmp edx,28h
  jne need_for_speed
  mov counter,4
add counter,5
  need_for_speed:
	
	jmp afisare_generala
afisare_generala:

	gata_e_tot:
	mov eax,24
	cmp [area2+eax],2
	jne continua
	cmp game_over,1
	jne continua
	make_text_macro 'G',area,249,249
	make_text_macro 'A',area,259,249
	make_text_macro 'M',area,269,249
	make_text_macro 'E',area,279,249
	make_text_macro 'O',area,299,249
	make_text_macro 'V',area,309,249
	make_text_macro 'E',area,319,249
	make_text_macro 'R',area,329,249
	continua:
	;coloana 0-49
	unitate_patrat area,0,0,49,0808080h
	unitate_patrat area,0,49,49,0808080h
	unitate_patrat area,0,98,49,0808080h               
	unitate_patrat area,0,147,49,0808080h
    unitate_patrat area,0,196,49,0808080h
	unitate_patrat area,0,245,49,0808080h
	unitate_patrat area,0,294,49,0808080h  
	unitate_patrat area,0,343,49,0808080h
	unitate_patrat area,0,392,49,0808080h
	unitate_patrat area,0,441,49,0808080h
    unitate_patrat area,0,490,49,0808080h
	unitate_patrat area,0,539,49,0808080h
	unitate_patrat area,0,588,49,0808080h
	unitate_patrat area,0,637,49,0808080h	
	
	;liniile de la 637 la 686
	unitate_patrat area,49,637,49,0808080h
	unitate_patrat area,98,637,49,0808080h
	unitate_patrat area,147,637,49,0808080h
	unitate_patrat area,196,637,49,0808080h
	unitate_patrat area,245,637,49,0808080h
	unitate_patrat area,294,637,49,0808080h
	unitate_patrat area,343,637,49,0808080h
	unitate_patrat area,392,637,49,0808080h
	unitate_patrat area,441,637,49,0808080h
	unitate_patrat area,490,637,49,0808080h
	unitate_patrat area,539,637,49,0808080h
	
	;coloanele de la 637 la 686
	unitate_patrat area,539,588,49,0808080h
	unitate_patrat area,539,539,49,0808080h
	unitate_patrat area,539,490,49,0808080h
	unitate_patrat area,539,441,49,0808080h
	unitate_patrat area,539,392,49,0808080h
	unitate_patrat area,539,343,49,0808080h
	unitate_patrat area,539,294,49,0808080h
	unitate_patrat area,539,245,49,0808080h
	unitate_patrat area,539,196,49,0808080h
	unitate_patrat area,539,147,49,0808080h
	unitate_patrat area,539,98,49,0808080h
	unitate_patrat area,539,49,49,0808080h
	unitate_patrat area,539,0,49,0808080h
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	rdtsc
    xor edx,edx
    mov ebx,6
    div ebx
    mov switch,edx
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	;alocam memorie pentru matricea adiacenta care tine cont de granite
	
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	
	;terminarea programului
	push 0
	call exit
end start
