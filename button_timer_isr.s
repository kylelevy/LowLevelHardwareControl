              .text 
              .global  _start

# Memory mapped definitions

## JTAG_UART registers

              .equ      JTAG_UART_BASE,	0x10001000
              .equ      DATA_OFFSET,    0
              .equ      STATUS_OFFSET, 	4
              .equ      WSPACE_MASK, 	0xFFFF

## data/edge/mask registers for pushbutton parallel port

              .equ      BUTTON_MASK, 	0x10000058
              .equ      BUTTON_EDGE, 	0x1000005C 
              .equ      BUTTON1, 		0x10000050

## data register for LED parallel port

              .equ      LEDS, 			0x10000010 
			  
## timer address declarations

			  .equ 		TIMER_STATUS, 		0x10002000
			  .equ 		TIMER_CTL, 			0x10002004
			  .equ		TIMER_START_LOW, 	0x10002008
			  .equ		TIMER_START_HIGH, 	0x1000200C

# Program addresses for main routine and ISR routines

	.org       0x0000 								# this is the _reset_ address
_start:
              br          main     					# branch to actual start of main() routine
	.org       0x0020 								# this is the _exception/interrupt_ address
              br          isr          				# branch to start of interrupt service routine

# main() routine

main:
              movia   sp, 0x7FFFFC                  # initialize stack pointer
              movia   r2, Lab2
              call        PrintString				# print header text
              call        Init                      # call hw/sw initialization subroutine
 
main_loop:
              movia   r3, COUNT(r0)
              ldw     r3, 0(r3)
              addi    r3, r3, 1
              stw     r3, COUNT(r0)					# load, incriment, and store the COUNT value in mem
              br main_loop
end:
              break

# Init() - h/w and s/w initialization

Init:
              subi      sp,sp,12
			  stw		r4, 8(sp)
              stw       r3, 4(sp)
              stw       r2, 0(sp)					# store all values in used registers to the stack
              movia   	r2, BUTTON1
              movia   	r3, 0xE
              stwio     r3, 8(r2)					# asserting the mask signal to BUTTON1
              movia   	r3, 0xFFFF
              stwio     r3, 12(r2) 					# asserting the edge signal to BUTTON1
			  movia 	r3, 0x2
			  movia 	r4, TIMER_STATUS			# asserting the status signal to TIMER
			  stwio		r3, 0(r4)
			  movia 	r4, TIMER_START_LOW
			  movia 	r3, 0xBC20
			  stwio		r3, 0(r4)					# loading the lower bits of the timer value
			  movia		r3, 0x00BE
			  movia 	r4, TIMER_START_HIGH
			  stwio		r3, 0(r4)					# loading the upper bits of the timer value
			  movia 	r3, 0x7
			  movia		r4, TIMER_CTL
			  stwio		r3, 0(r4)					# asserting the control signal to TIMER
              movi      r3,0x3
              wrctl     ienable,r3
              movi      r3,1						# asserting the global interupt enable for the DE0
              wrctl     status, r3					# asserting the global status as high
			  ldw 					   r4, 8(sp)	# load all previous values from the stack
              ldw                      r3, 4(sp)
              ldw                      r2, 0(sp)
              addi      sp, sp, 12
              ret

# ISR() routine - flash leds with timer and toggle led with push button
isr:
              subi      sp, sp,20
              stw       r5, 16(sp)
              stw       r4, 12(sp)
              stw       ra, 8(sp)
              stw       r2, 4(sp)
              stw       r3, 0(sp)					# store register values to stack
              subi      ea, ea, 4              		# ea adjustment required for h/w interrupts - DE0 requires you manually rollback 
													# the ea to account for the missed instruction when the interrupt is first asserted

              rdctl     r2, ipending				# Checking if BUTTON1 has a request
              andi      r3, r2, 0x2
              bne       r3, r0, BUTTON_ISR
			  
		POST_BTN:
			  andi 		r3, r2, 0x1					# Checking if TIMER has a request
			  bne 		r3, r0, TISR
			  br EOSR
			  
# BUTTON1 Service Routine
		BUTTON_ISR:
              movia   	r3, LEDS(r0)
              ldwio    	r5, 0(r3)
              xori      r4, r5,1
              stwio     r4, (r3)					# check current LED status and invert it
             
              movia   	r2, BUTTON_EDGE
              movi     	r3, 0xFF
              stwio     r3, 0(r2)					# acknowledging button interupt
			  br POST_BTN

# TIMER Service routine
        TISR: 
			  movia 	r2, TIMER_STATUS			# Clear interrupt
			  movi 		r3, 0x3
			  stwio 	r3, 0(r2)
			  call TULEDs							# toggle upper 5 leds
			  
        EOSR:
              ldw                      r5, 16(sp)
              ldw                      r4, 12(sp)
              ldw                      ra, 8(sp)
              ldw                      r2, 4(sp)
              ldw                      r3, 0(sp)	# restore register values from stack
              addi      sp,sp,20
isr_end:
              eret
 

# Toggle upper 5 LEDs
TULEDs: 
	
	subi 	sp, sp, 8
	stw		r2, 4(sp)
	stw		r3, 0(sp)								# store registers on the stack
	
	movia	r2, LEDS
	ldw		r3, 0(r2)
	xori	r3, r3, 0x3E0							# load current status of upper 5 leds and invert it
	stw		r3, 0(r2)
	
	ldw		r3, 0(sp)								# load registers from the stack
	ldw		r2, 4(sp)
	addi 	sp, sp, 8
	
	ret



# PrintString() 
PrintString:
 
              subi       sp,sp, 16
              stw        ra, 12(sp)
              stw        r2, 8(sp)
              stw        r3, 4(sp)
              stw        r4, 0(sp)
              mov        r3, r2
             
ps_loop:
 
              ldb 		 r4, 0(r3)
             
ps_if:    
              bgt        r4, r0, ps_else
 
ps_then:
              br         ps_end_if
             
ps_else:
              mov        r2, r4
              call       PrintChar
              addi       r3, r3, 1
              br         ps_loop
             
ps_end_if:
              ldw        ra, 12(sp)
              ldw        r2, 8(sp)
              ldw        r3, 4(sp)
              ldw        r4, 0(sp)
              addi       sp,sp,16
              ret
 
# PrintChar()
PrintChar:
              subi       sp, sp, 8                  # adust stack pointer down to reserve space
              stw        r3, 4(sp)                  # save value of r3 so it can be a temp
              stw        r4, 0(sp)                  # save value of r4 so it can be a temp
              movia   	 r3, JTAG_UART_BASE     	# point to first memory-mapped I/O register
pc_loop:
              ldwio    	 r4, STATUS_OFFSET(r3)  	#read bits from status register
              andhi    	 r4, r4, WSPACE_MASK    	# mask off lower vits to isolate upper bits
              beq        r4, r0, pc_loop            # if upper bits are zero, loop again
              stwio      r2, DATA_OFFSET(r3)      	# otherwise, write character to data register
              ldw        r3, 4(sp)                  # restore value of r3 from stack
              ldw        r4, 0(sp)                  # restore value of r4 from stack
              addi       sp, sp, 8                  # readust stack pointer up to deallocate space
              ret                                   # return to calling routine
 
# Declarations of constant files
 
              .org       0x1000
 
COUNT: 		  .word    	 0                          			 # keep the main loop COUNT in memory  

              .skip      8
			  
Lab2:     	  .asciz     "The program has started."
 
              .end