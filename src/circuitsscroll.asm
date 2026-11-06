; C64 CIRCUITS trailer scroller: fine-scrolling text on screen row 0, raster split
!cpu 6502
* = $9700
        jmp start        ; $9700 start
        jmp stop         ; $9703 stop
chain   !word 0
fine    !byte 7
st      !byte 0
ct      !byte 0
ph      !byte 0
mus     !byte 0

start   sei
        lda $0315
        cmp #>irq
        beq +
        lda $0314
        sta chain
        lda $0315
        sta chain+1
        ldx #0
        cmp #$90          ; music irq installed? then we call its play
        bne ++
        inx
++      stx mus
        lda #<irq
        sta $0314
        lda #>irq
        sta $0315
        lda #7
        sta fine
        lda #<text
        sta tx+1
        lda #>text
        sta tx+2
        lda #0
        sta st
        sta ct
        sta ph
        ldx #39
-       lda #32
        sta $0400,x
        lda #1
        sta $d800,x
        dex
        bpl -
        lda $d011
        and #$7f
        sta $d011
        lda #47
        sta $d012
        lda #$ff
        sta $d019
        lda #1
        sta $d01a
+       cli
        rts

stop    sei
        lda $0315
        cmp #>irq
        bne +
        lda chain
        sta $0314
        lda chain+1
        sta $0315
+       lda #0
        sta $d01a
        lda #$ff
        sta $d019
        lda #$c8
        sta $d016
        cli
        rts

irq     lda $d019
        and #1
        bne rast
        jmp $ea31
rast    sta $d019
        lda st
        bne s2
        lda fine          ; split 1: fine scroll for row 0, 38 columns
        ora #$c0
        sta $d016
        lda #1
        sta st
        lda #60
        sta $d012
        jmp $ea81
s2      lda #$c8          ; split 2: back to normal
        sta $d016
        lda #0
        sta st
        lda #47
        sta $d012
        lda mus
        beq +
        jsr $900c         ; music play, once per frame
+       dec fine
        bpl nc
        lda #7
        sta fine
        ldx #0
-       lda $0401,x
        sta $0400,x
        inx
        cpx #39
        bne -
tx      lda text
        bne +
        lda #<text
        sta tx+1
        lda #>text
        sta tx+2
        lda text
+       sta $0427
        inc tx+1
        bne nc
        inc tx+2
nc      inc ct
        lda ct
        and #3
        bne done
        inc ph
        ldx #39
-       txa
        clc
        adc ph
        and #7
        tay
        lda ctab,y
        sta $d800,x
        dex
        bpl -
done    jmp $ea81

ctab    !byte 1,14,3,13,7,13,3,14
* = $9900
text
!byte 3,54,52,32,3,9,18,3,21,9,20,19,32,46,46,46
!byte 32,20,8,5,32,7,18,9,4,32,9,19,32,4,5,1
!byte 4,46,32,5,22,5,18,25,32,2,15,1,18,4,32,9
!byte 19,32,19,9,12,5,14,20,46,32,15,14,5,32,23,9
!byte 18,5,32,1,20,32,1,32,20,9,13,5,44,32,2,18
!byte 9,14,7,32,9,20,32,2,1,3,11,46,32,46,46,46
!byte 32,18,5,22,5,1,12,32,20,8,5,32,8,9,4,4
!byte 5,14,32,23,9,18,5,32,6,18,15,13,32,16,1,4
!byte 32,20,15,32,16,1,4,32,21,19,9,14,7,32,20,8
!byte 5,32,18,15,23,32,1,14,4,32,3,15,12,21,13,14
!byte 32,3,12,21,5,19,32,46,46,46,32,20,8,9,19,32
!byte 14,5,23,32,22,5,18,19,9,15,14,32,8,1,19,32
!byte 13,21,12,20,9,16,12,5,32,2,15,1,18,4,19,32
!byte 15,14,32,19,3,18,5,5,14,32,1,20,32,15,14,3
!byte 5,44,32,5,1,3,8,32,12,5,1,4,9,14,7,32
!byte 20,15,32,20,8,5,32,14,5,24,20,32,46,46,46,32
!byte 51,55,32,12,5,22,5,12,19,32,6,18,15,13,32,53
!byte 24,53,32,21,16,32,20,15,32,20,8,5,32,49,55,24
!byte 51,54,32,13,1,9,14,32,7,18,9,4,32,46,46,46
!byte 32,16,21,18,5,32,2,1,19,9,3,32,22,50,32,15
!byte 14,32,1,32,19,20,15,3,11,32,3,54,52,32,46,46
!byte 46,32,13,21,19,9,3,58,32,16,1,4,32,20,15,32
!byte 16,1,4,44,32,19,15,12,4,5,18,9,14,7,32,15
!byte 14,32,19,9,4,32,3,8,1,14,14,5,12,32,50,32
!byte 46,46,46,32,19,15,12,22,5,32,20,8,5,32,12,1
!byte 19,20,32,2,15,1,18,4,32,1,14,4,32,20,8,5
!byte 32,13,1,9,14,32,7,18,9,4,32,3,15,13,5,19
!byte 32,15,14,12,9,14,5,32,46,46,46,32,7,5,20,32
!byte 9,20,32,1,20,32,8,20,20,16,19,58,47,47,13,48
!byte 14,4,5,46,9,20,3,8,46,9,15,47,3,54,52,3
!byte 9,18,3,21,9,20,19,32,46,46,46,32,3,15,4,5
!byte 32,1,14,4,32,13,21,19,9,3,32,2,25,32,13,48
!byte 14,4,5,32,46,46,46,32,16,18,5,19,19,32,17,32
!byte 6,15,18,32,20,8,5,32,13,5,14,21,32,46,46,46
!byte 32,32,32,32,32,32
!byte 0
