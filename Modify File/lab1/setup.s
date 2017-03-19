!
!	setup.s		(C) 1991 Linus Torvalds
!
! setup.s is responsible for getting the system data from the BIOS,
! and putting them into the appropriate places in system memory.
! both setup.s and system has been loaded by the bootblock.
!
! This code asks the bios for memory/disk/other parameters, and
! puts them in a "safe" place: 0x90000-0x901FF, ie where the
! boot-block used to be. It is then up to the protected mode
! system to read them from there before the area is overwritten
! for buffer-blocks.
!

! NOTE! These had better be the same as in bootsect.s!

INITSEG  = 0x9000	! we move boot here - out of the way
SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).
SETUPSEG = 0x9020	! this is the current segment

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

entry start
start:

!-----------------------------------------------------------------------
! Print some inane message setup.s
	
	mov ax,#SETUPSEG  !�ε�ַ 0x9020
	mov es,ax
	
	mov ah,#0x03
	xor bh,bh
	int 0x10   ! read cursor pos
	
	mov cx,#25
	mov bx,#0x00010
	mov bp,#msg2
	mov ax,#0x1301
	int 0x10
!-----------------------------------------------------------------------


! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax
	mov	ah,#0x03	! read cursor pos
	xor	bh,bh
	int	0x10		! save it in known place, con_init fetches
	mov	[0],dx		! it from 0x90000.
! Get memory size (extended mem, kB)

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! Get video-card data:

	mov	ah,#0x0f
	int	0x10
	mov	[4],bx		! bh = display page
	mov	[6],ax		! al = video mode, ah = window width

! check for EGA/VGA and some config parameters

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax
	mov	[10],bx
	mov	[12],cx

! Get hd0 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x41]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080
	mov	cx,#0x10
	rep
	movsb

! Get hd1 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x46]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	rep
	movsb

! Check that there IS a hd1 :-)

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1
	cmp	ah,#3
	je	is_disk1
no_disk1:
	mov	ax,#INITSEG
	mov	es,ax			
	mov	di,#0x0090		
	mov	cx,#0x10
	mov	ax,#0x00
	rep
	stosb
is_disk1:
    
!��16���Ʒ�ʽ��ӡ��������
!�ȴ�ӡ���λ��
print_cur:
  mov ah,#0x03
  xor bh,bh
  int 0x10        !�ȶ����λ�ã�����ֵ��dx��
  mov ax,#SETUPSEG
  mov es,ax
  mov cx,#11
  mov bx,#0x0007
  mov bp,#msg3
  mov ax,#0x1301
  int 0x10
  
  xor di,di
  mov ax,#INITSEG
  mov ds,ax
  mov bx,(di)
  call print_bx
  
!��ӡ��չ�ڴ���
print_mem:
  mov ah,#0x03
  xor bh,bh
  int 0x10        !�ȶ����λ�ã�����ֵ��dx��
  mov cx,#12
  mov bx,#0x0007
  mov bp,#msg4
  mov ax,#0x1301
  int 0x10
  
  mov di,#0x02
  mov bx,(di)
  call print_bx
  
!��ӡӲ�̲���
print_hd:
  mov ah,#0x03
  xor bh,bh
  int 0x10        !�ȶ����λ�ã�����ֵ��dx��
  mov cx,#5
  mov bx,#0x0007
  mov bp,#msg5
  mov ax,#0x1301
  int 0x10 
  mov di,#0x80
  mov bx,(di)
  call print_bx
  
  mov ah,#0x03
  xor bh,bh
  int 0x10        !�ȶ����λ�ã�����ֵ��dx��
  mov cx,#6
  mov bx,#0x0007
  mov bp,#msg6
  mov ax,#0x1301
  int 0x10 
  mov di,#0x82
  mov bx,(di)
  xor bh,bh
  call print_bx
  
  mov ah,#0x03
  xor bh,bh
  int 0x10        !�ȶ����λ�ã�����ֵ��dx��
  mov cx,#8
  mov bx,#0x0007
  mov bp,#msg7
  mov ax,#0x1301
  int 0x10 
  mov di,#0x8e
  mov bx,(di)
  xor bh,bh
  call print_bx
  

death:
	jmp death  !��ѭ��
!-----------------------------------------------------------------------


! now we want to move to protected mode ...

	cli			! no interrupts allowed !

! first we move the system to it's rightful place

	mov	ax,#0x0000
	cld			! 'direction'=0, movs moves forward
do_move:
	mov	es,ax		! destination segment
	add	ax,#0x1000
	cmp	ax,#0x9000
	jz	end_move
	mov	ds,ax		! source segment
	sub	di,di
	sub	si,si
	mov 	cx,#0x8000
	rep
	movsw
	jmp	do_move

! then we load the segment descriptors

end_move:
	mov	ax,#SETUPSEG	! right, forgot this at first. didn't work :-)
	mov	ds,ax
	lidt	idt_48		! load idt with 0,0
	lgdt	gdt_48		! load gdt with whatever appropriate

! that was painless, now we enable A20

	call	empty_8042
	mov	al,#0xD1		! command write
	out	#0x64,al
	call	empty_8042
	mov	al,#0xDF		! A20 on
	out	#0x60,al
	call	empty_8042


	mov	al,#0x11		! initialization sequence
	out	#0x20,al		! send it to 8259A-1
	.word	0x00eb,0x00eb		! jmp $+2, jmp $+2
	out	#0xA0,al		! and to 8259A-2
	.word	0x00eb,0x00eb
	mov	al,#0x20		! start of hardware int's (0x20)
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x28		! start of hardware int's 2 (0x28)
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x04		! 8259-1 is master
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x02		! 8259-2 is slave
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x01		! 8086 mode for both
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0xFF		! mask off all interrupts for now
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al

	mov	ax,#0x0001	! protected mode (PE) bit
	lmsw	ax		! This is it!
	jmpi	0,8		! jmp offset 0 of segment 8 (cs)


empty_8042:
	.word	0x00eb,0x00eb
	in	al,#0x64	! 8042 status port
	test	al,#2		! is input buffer full?
	jnz	empty_8042	! yes - loop
	ret

!��ӡbx�еĲ���	
print_bx:
   mov cx,#4
   mov dx,bx
print_digit:
   rol dx,#4
   mov ax,#0x0e0f
   and al,dl
   add al,#0x30
   cmp al,#0x3a
   jb outp
   add al,#0x07
outp:
   int 0x10
   loop print_digit
!��ӡ�س�
print_nl:
   mov ax,#0x0e0d
   int 0x10
   mov al,#0x0a
   int 0x10
   ret

gdt:
	.word	0,0,0,0		! dummy

	.word	0x07FF		! 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9A00		! code read/exec
	.word	0x00C0		! granularity=4096, 386

	.word	0x07FF		! 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		! base address=0
	.word	0x9200		! data read/write
	.word	0x00C0		! granularity=4096, 386

idt_48:
	.word	0			! idt limit=0
	.word	0,0			! idt base=0L

gdt_48:
	.word	0x800		! gdt limit=2048, 256 GDT entries
	.word	512+gdt,0x9	! gdt base = 0X9xxxx

msg2:
    .byte 13,10
	.ascii "Now we are in SETUP"
	.byte 13,10,13,10
	 
msg3:
    .ascii "Cursor POS:"
	 
msg4:
    .ascii "Memory SIZE:"
	 
msg5:
    .ascii "Cyls:"	 
msg6:
    .ascii "Heads:"
msg7:
    .ascii "Sectors:"
                                                                                                                                                                                                                 
.text
endtext:
.data
enddata:
.bss
endbss:
