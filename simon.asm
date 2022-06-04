;This is my simon game!!! enjoy :)
IDEAL 
MODEL small
STACK 100h 
 
DATASEG 
;Array:
ColorsPlayed db 100 dup (5)
index dw 0
;Counters and checkers:
checkerForPlay dw 0
checkerForPress dw 0
points dw 0
;Messages: 
levelMessage db 'Please select the wanted level:$'
scoreMessage db 'Your Score:$'
ErrorMsg db 'Error$' 
;Timer 
clock equ es:6Ch
timePeriode dw 18
timeSubstracter dw 0
limit dw 0
;Locations and sizes:
x	dw	0
y	dw	0
minX dw 0
maxX dw 0
minY dw 0
maxY dw 0
horLength dw 0
verLength dw 0
;Colors:
redColor dw 12
blueColor dw 6
yellowColor dw 29
greenColor dw 2
redButtonColor dw 3577
blueButtonColor dw 3580
yellowButtonColor dw 3579
greenButtonColor dw 3578
;Sounds:
redSound dw 7240h
blueSound dw 5424h
yellowSound dw 4305h
greenSound dw 3620h
currentSound dw 0h
;BMP files related
filename db ?
backgroundPic db 'SimonPic.bmp',0 
gameOverPic db 'gameOver.bmp',0
levelsPic db 'levels.bmp',0
filehandle dw  ? 
Header db 54 dup (0) 
Palette db 256*4 dup (0) 
ScrLine db 320 dup (0)
 
CODESEG 

proc OpenFile 

	; Opens file 
	mov ah, 3Dh 
	xor al, al 
	int 21h
	jc openerror
	mov [filehandle], ax
	ret 
	
	;printing error message
	openerror: 
	mov dx, offset ErrorMsg 
	mov ah, 9h 
	int 21h 
	ret  
	
endp OpenFile 
 
proc ReadHeader 
 
	; Read BMP file header, 54 bytes 
	mov ah, 3fh 
	mov bx, [filehandle] 
	mov cx, 54 
	mov dx, offset Header 
	int 21h                      
	ret
	
endp ReadHeader  
 
proc ReadPalette 

	; Read BMP file color palette, 256 colors * 4 bytes (400h) 
	mov ah, 3fh 
	mov cx, 400h                           
	mov dx, offset Palette 
	int 21h                      
	ret 
	
endp ReadPalette  
 
proc CopyPal
  
	; Copy the colors palette to the video memory  
	; The number of the first color should be sent to port 3C8h 
	; The palette is sent to port 3C9h 
	mov si,offset Palette        
	mov cx,256               
	mov dx,3C8h 
	mov al,0                     
	; Copy starting color to port 3C8h 
	out dx,al 
	; Copy palette itself to port 3C9h  
	inc dx  
	
	PalLoop: 
	; Note: Colors in a BMP file are saved as BGR values rather than RGB. 
	mov al,[si+2] ; Get red value. 
	shr al,2 ; Max. is 255, but video palette maximal value is 63. Therefore dividing by 4. 
	out dx,al ; Send it. 
	mov al,[si+1] ; Get green value. 
	shr al,2 
	out dx,al ; Send it. 
	mov al,[si] ; Get blue value. 
	shr al,2 
	out dx,al ; Send it. 
	add si,4 ; Point to next color. 
	;(There is a null chr. after every color.) 
	loop PalLoop 
	ret 
	
endp CopyPal  
 
proc CopyBitmap 

	; BMP graphics are saved upside-down. 
	; Read the graphic line by line (200 lines in VGA format), 
	; displaying the lines from bottom to top.  
	mov ax, 0A000h 
	mov es, ax 
	mov cx,200               
	PrintBMPLoop: 
	push cx 
	; di = cx*320, point to the correct screen line 
	mov di,cx                    
	shl cx,6                     
	shl di,8                     
	add di,cx 
	; Read one line 
	mov ah,3fh 
	mov cx,320 
	mov dx,offset ScrLine 
	int 21h                      
	; Copy one line into video memory 
	cld ; Clear direction flag, for movsb 
	mov cx,320 
	mov si,offset ScrLine 
	rep movsb ; Copy line to the screen  
	;rep movsb is same as the following code: 
	;mov es:di, ds:si 
	;inc si 
	;inc di 
	;dec cx 
	;loop until cx=0      
	pop cx 
	loop PrintBMPLoop 
	ret 
	
endp CopyBitmap 

;draws the game background (simon picture)
proc DrawBackground

	; Process BMP file 
	mov dx, offset backgroundPic
	call OpenFile 
	call ReadHeader 
	call ReadPalette 
	call CopyPal 
	call CopyBitmap 
 
	ret
 
endp DrawBackground

;draws the gameover background (gameover picture)
proc DrawGameOver

	; Process BMP file 
	mov dx, offset gameOverPic
	call OpenFile 
	call ReadHeader 
	call ReadPalette 
	call CopyPal 
	call CopyBitmap 
 
	ret
 
endp DrawGameOver

;draws the levels selection background (levels picture)
proc DrawLevelMenu

	; Process BMP file 
	mov dx, offset levelsPic
	call OpenFile 
	call ReadHeader 
	call ReadPalette 
	call CopyPal 
	call CopyBitmap 
 
	ret
 
endp DrawLevelMenu

proc Timer

push[timePeriode]
push bp 
mov bp, sp
timePeriodee equ [bp+2]


	; wait for first change in timer
	mov ax, 40h
	mov es, ax
	mov ax, [clock]

	firstTick:
	cmp ax, [clock]
	je firstTick

	; counts 'x' sec
	mov cx, timePeriodee ; 18x0.055sec = ~1sec

	delayLoop:
	mov ax, [clock]

	tick:
	cmp ax, [clock]
	je tick
	
	loop delayLoop
	
pop bp
pop [timePeriode]
ret

endp Timer

;making the timer count less time 
proc GoFaster

	mov dx, [timeSubstracter]
	sub [timePeriode], dx
	cmp [timePeriode], 3
	jg donee 
	mov [timePeriode], 3
	
	donee:
	ret
	
endp GoFaster
	
proc PlaySound

	; opens speaker
	in al, 61h
	or al, 00000011b
	out 61h, al

	; sends control word to change frequency
	mov al, 0B6h
	out 43h, al

	; plays requessted frequency

	out 42h, al ; Sending lower byte
	mov al, ah

	out 42h, al ; Sending upper byte

	call Timer

	; close the speaker
	in al, 61h
	and al, 11111100b
	out 61h, al
	ret
	
endp PlaySound

proc InitializeMouse

	; Initializes the mouse
	mov ax,0h
	int 33h

	; Shows mouse
	mov ax,1h
	int 33h

	ret

endp InitializeMouse

proc DisableMouse

	; Hides mouse
	mov ax,02
	int 33h

	ret

endp DisableMouse

;checking mouse left click input from the user on a spesific color, if pressed: continues the game, if not: gameover
proc IsOnColor

push ax
push bx
push cx
push dx

	; Loop until mouse left click
	MouseLP:
	mov ax,3h
	int 33h
	cmp bx, 01h ; check left mouse click
	jne MouseLP

	; Checks if the mouse location is on a specific button 
	cmp cx, [minX]
	jg continue1
	call DisableMouse
	call DrawGameOver
	jmp exit
	;----------------
	continue1:
	cmp cx, [maxX]
	jl continue2
	call DisableMouse
	call DrawGameOver
	jmp exit
	;----------------
	continue2:
	cmp dx, [maxY]
	jl continue3
	call DisableMouse
	call DrawGameOver
	jmp exit
	;----------------
	continue3:
	cmp dx, [minY]
	jg done
	call DisableMouse
	call DrawGameOver
	jmp exit

done:
pop dx
pop cx
pop bx
pop ax
ret

endp IsOnColor

;checking mouse left click input from the user untill he presses on the start button, then starts the game
proc IsOnStart

push ax
push bx
push cx
push dx

	;start button coordinates
	mov [minX], 00DAh
	mov [maxX], 01A6h
	mov [maxY], 007Dh
	mov [minY], 004Ah

	; Loop until mouse left click
	MouseLPP:
	mov ax,3h
	int 33h
	cmp bx, 01h ; check left mouse click
	jne MouseLPP

	; Checks if the mouse location is on a specific button 
	cmp cx, [minX]
	jg continuee1
	jmp MouseLPP
	;----------------
	continuee1:
	cmp cx, [maxX]
	jl continue2
	jmp MouseLPP
	;----------------
	continuee2:
	cmp dx, [maxY]
	jl continue3
	jmp MouseLPP
	;----------------
	continuee3:
	cmp dx, [minY]
	jg done
	jmp MouseLPP

doneee:
pop dx
pop cx
pop bx
pop ax
ret

endp IsOnStart

;checking mouse left click input from the user untill he presses on one of the level buttons, changes features in the game according to the level 
;that was selected
proc SelectLevel

push ax
push bx
push cx
push dx

	; Loops until mouse left click
	MouseLPPP:
	mov ax,3h
	int 33h
	cmp bx, 01h ; checks left mouse click
	jne MouseLPPP

	Easy:
	;easy button coordinates
	mov [minX], 0018h
	mov [maxX], 00D0h
	mov [maxY], 00A0h
	mov [minY], 0037h
	
	cmp cx, [minX]
	jl Normal
	;----------------
	continueee1:
	cmp cx, [maxX]
	jg Normal
	;----------------
	continueee2:
	cmp dx, [maxY]
	jg Normal
	;----------------
	continueee3:
	cmp dx, [minY]
	jl Normal
	;assining the substracter and the speed limit of the timer
	mov [timeSubstracter], 1
	mov [limit],5
	jmp doneeee
	
	Normal:
	mov [minX], 00E4h
	mov [maxX], 019Ah
	mov [maxY], 00A1h
	mov [minY], 0039h 
	
	cmp cx, [minX]
	jl Hard
	;----------------
	continueeee1:
	cmp cx, [maxX]
	jg Hard
	;----------------
	continueeee2:
	cmp dx, [maxY]
	jg Hard
	;----------------
	continueeee3:
	cmp dx, [minY]
	jl Hard
	mov [timeSubstracter], 2
	mov [limit],4
	jmp doneeee
	
	Hard:
	mov [minX], 01AEh
	mov [maxX], 0268h
	mov [maxY], 00A0h
	mov [minY], 0037h

	cmp cx, [minX]
	jl NoButtonDetected
	;----------------
	continueeeee1:
	cmp cx, [maxX]
	jg NoButtonDetected
	;----------------
	continueeeee2:
	cmp dx, [maxY]
	jg NoButtonDetected
	;----------------
	continueeeee3:
	cmp dx, [minY]
	jl NoButtonDetected
	mov [timeSubstracter], 5
	mov [limit],3
	jmp doneeee
	;----------------
	NoButtonDetected:
	jmp MouseLPPP

doneeee:
pop dx
pop cx
pop bx
pop ax

ret

endp SelectLevel

;checking if the user pressed on the red button
proc IsOnRed

	mov [minX], 0150h
	mov [maxX], 0258h
	mov [maxY], 005Fh
	mov [minY], 000Eh
	call IsOnColor
	mov ax, [redSound]
	call PlaySound

	ret

endp IsOnRed

proc IsOnBlue

	mov [minX], 0024h
	mov [maxX], 012Ah
	mov [maxY], 005Fh
	mov [minY], 000Eh
	call IsOnColor
	mov ax, [blueSound]
	call PlaySound

	ret

endp IsOnBlue

proc IsOnYellow

	mov [minX], 0024h
	mov [maxX], 012Ah
	mov [maxY], 00BAh
	mov [minY], 006Ah
	call IsOnColor
	mov ax, [yellowSound]
	call PlaySound

	ret

endp IsOnYellow

proc IsOnGreen

	mov [minX], 0150h
	mov [maxX], 0258h
	mov [maxY], 00BAh
	mov [minY], 006Ah
	call IsOnColor
	mov ax, [greenSound]
	call PlaySound

	ret

endp IsOnGreen

;creates a pixel according to the x,y coordinates
proc createPixel 

push ax 
push bx 
push cx 
push dx
	
	mov bh,0h 
	mov cx, [x]
	mov dx, [y] 
	mov ah,0ch 
	int 10h

pop dx
pop cx
pop bx
pop ax
ret 

endp createPixel 

proc createLine

push [x]
push ax 
push bx 
push cx 
push dx

	mov cx, [horLength]
	formX :
	call createPixel
	add [x],1
	loop formX

pop dx
pop cx
pop bx
pop ax
pop [x]
ret 

endp createLine

proc createRec

push[y]
push ax 
push bx 
push cx 
push dx

	mov cx, [verLength]
	formRec:
	call createLine
	add [y],1
	loop formRec

pop dx
pop cx
pop bx
pop ax
pop[y]
ret

endp createRec

proc printMessage

	;--------------------
	mov  dl, 5    ;Column
	mov  dh, 2    ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov dx, offset levelMessage
	mov ah,9 
	int 21h

	ret

endp printMessage

proc printScore  
 
	;--------------------
	mov  dl, 110  ;Column
	mov  dh, 87   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov dx, offset scoreMessage
	mov ah,9 
	int 21h
 
    ;displaying number of points
 
	mov ax, [points]

	mov bx, 10       ;initializes divisor
	mov dx, 0000h    ;clears dx
	mov cx, 0000h    ;clears cx
    
    ;splitting process starts here
	dloop1: 
	mov dx, 0000h    ;clears dx during jump
	div bx           ;divides ax by bx
	push dx          ;pushes dx(remainder) to stack
	inc cx           ;increments counter to track the number of digits
	cmp ax, 0        ;checks if there is still something in ax to divide
	jne dloop1       ;jumps if ax is not zero
    
	dloop2:  
	pop dx           ;pops from stack to dx
	add dx, 30h      ;converts to it's ascii equivalent
	mov ax,dx
	mov  bl, 254     ;Color is cyan
	mov  bh, 0       ;Display page
	mov  ah, 0Eh     ;Teletype
	int  10h
	loop dloop2      ;loops till cx equals zero
	
	inc [points]
	
	ret              ;returns control
	
endp printScore

;randomly generates a number from 0-3 and picking wich color will be played now according to the number
proc PickAColor

	mov ax, 40h
	mov es, ax
	mov ax, [es:6Ch]
	and al, 00000011b

	comparison1:
	cmp al, 00
	jne comparison2
	mov bx, [index]
	mov dl, 00
	mov[ColorsPlayed + bx],dl
	inc [index]
	jmp finish
	;-----------
	comparison2:
	cmp al, 01
	jne comparison3
	mov bx, [index]
	mov dl, 01
	mov[ColorsPlayed + bx],dl 
	inc [index]
	jmp finish
	;-----------
	comparison3:
	cmp al, 02
	jne comparison4
	mov bx, [index]
	mov dl, 02
	mov[ColorsPlayed + bx],dl 
	inc [index]
	jmp finish
	;-----------
	comparison4:
	cmp al, 03
	jne comparison1
	mov bx, [index]
	mov dl, 03
	mov[ColorsPlayed + bx],dl
	inc [index] 
	jmp finish

	finish:
	ret

endp PickAColor

;playing and painting all the previos buttons that are stored in the array and the new picked button
proc PlayColors

	checkColorsToPlay:
	mov bx, [checkerForPlay]
 
	compareToNull:
	cmp [ColorsPlayed + bx], 5
	je return
	;-----------
	compareToRed:
	cmp [ColorsPlayed + bx], 00
	jne compareToBlue
	call GoRed
	inc [checkerForPlay]
	jmp checkColorsToPlay
	;------------
	compareToBlue:
	cmp [ColorsPlayed + bx], 01
	jne compareToYellow
	call GoBlue
	inc [checkerForPlay]
	jmp checkColorsToPlay
	;-------------
	compareToYellow:
	cmp [ColorsPlayed + bx], 02
	jne compareToGreen
	call GoYellow
	inc [checkerForPlay]
	jmp checkColorsToPlay
	;-------------
	compareToGreen:
	cmp [ColorsPlayed + bx], 03
	jne return
	call GoGreen
	inc [checkerForPlay]
	jmp checkColorsToPlay
 
	return:
	mov [checkerForPlay], 0
	ret
 
endp PlayColors

;checking the user's left click mouse input to match all the previos buttons that need to be clicked (array) and the new picked button
proc PressColors

	checkColorsToPress:
	mov bx, [checkerForPress]
 
	compareToNulll:
	cmp [ColorsPlayed + bx], 5
	je returnn
	;-----------
	compareToRedd:
	cmp [ColorsPlayed + bx], 00
	jne compareToBluee
	call IsOnRed
	inc [checkerForPress]
	jmp checkColorsToPress
	;------------
	compareToBluee:
	cmp [ColorsPlayed + bx], 01
	jne compareToYelloww
	call IsOnBlue
	inc [checkerForPress]
	jmp checkColorsToPress
	;-------------
	compareToYelloww:
	cmp [ColorsPlayed + bx], 02
	jne compareToGreenn
	call IsOnYellow
	inc [checkerForPress]
	jmp checkColorsToPress
	;-------------
	compareToGreenn:
	cmp [ColorsPlayed + bx], 03
	jne returnn
	call IsOnGreen
	inc [checkerForPress]
	jmp checkColorsToPress
 
	returnn:
	mov [checkerForPress], 0

	mov cx, 18
	call Timer
	ret
 
endp PressColors

;red button animation && sound
proc GoRed

push [redColor]
push [redSound]
push [redButtonColor]
push bp
mov bp, sp
redColorr equ [bp + 6]
redSoundd equ [bp + 4]
redButtonColorr equ [bp + 2]

	mov ax, redColorr
	mov [x], 210
	mov [y], 40
	mov [horLength], 50
	mov [verLength], 30
	call createRec

	mov ax, redSoundd
	call PlaySound

	mov ax, redButtonColorr
	call createRec

pop bp
pop [redButtonColor]
pop [redSound]
pop [redColor]
ret 

endp GoRed

;blue button animation && sound
proc GoBlue

push [blueColor]
push [blueSound]
push [blueButtonColor]
push bp
mov bp, sp
blueColorr equ [bp + 6]
blueSoundd equ [bp + 4]
blueButtonColorr equ [bp + 2]

	mov ax, blueColorr
	mov [x], 60
	mov [y], 40
	mov [horLength], 50
	mov [verLength] ,30
	call createRec

	mov ax, blueSoundd
	call PlaySound

	mov ax, blueButtonColorr
	call createRec

pop bp
pop [blueButtonColor]
pop [blueSound]
pop [blueColor]
ret 

endp GoBlue

;yellow button animation && sound
proc GoYellow

push [yellowColor]
push [yellowSound]
push [yellowButtonColor]
push bp
mov bp, sp
yellowColorr equ [bp + 6]
yellowSoundd equ [bp + 4]
yellowButtonColorr equ [bp + 2]

	mov ax, yellowColorr
	mov [x], 57
	mov [y], 130
	mov [horLength], 50
	mov [verLength] ,30
	call createRec

	mov ax, yellowSoundd
	call PlaySound

	mov ax, yellowButtonColorr
	call createRec

pop bp
pop [yellowButtonColor]
pop [yellowSound]
pop [yellowColor]
ret 

endp GoYellow

;green button animation && sound
proc GoGreen

push [greenColor]
push [greenSound]
push [greenButtonColor]
push bp
mov bp, sp
greenColorr equ [bp + 6]
greenSoundd equ [bp + 4]
greenButtonColorr equ [bp + 2]

	mov ax, greenColorr
	mov [x], 213
	mov [y], 130
	mov [horLength], 50
	mov [verLength] ,30
	call createRec

	mov ax, greenSoundd
	call PlaySound

	mov ax, greenButtonColorr
	call createRec

pop bp
pop [greenButtonColor]
pop [greenSound]
pop [greenColor]
ret 

endp GoGreen
 
start: 

 mov ax, @data 
 mov ds, ax 
 ;Graphic mode 
 mov ax, 13h  
 int 10h 
 
 ;THE GAME!!!
 
 ;lets the user select the wanted level
 call DrawLevelMenu
 call printMessage
 call InitializeMouse
 call SelectLevel
 ;we do this so the mouse won't mess up the pcture printing
 call DisableMouse
 
 ;opens the bmp file and draws it on the screen
 call DrawBackground
 
 ;initializes the mouse
 call InitializeMouse
 
;Waits untill the user clicks on the "START" button
 call IsOnStart

 play:
 call printScore
 call PickAColor
 call PlayColors
 call PressColors
 call GoFaster
 jmp play
 
exit: 
 mov ax, 4c00h 
 int 21h 
 
END start
