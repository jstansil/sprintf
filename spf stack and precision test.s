######################################################################
# spf-main.s
# 
# This is the main function that tests the sprintf function

# The "data" segment is a static memory area where we can 
# allocate and initialize memory for our program to use.
# This is separate from the stack or the heap, and the allocation
# cannot be changed once the program starts. The program can
# write data to this area, though.
	.data
	
# Note that the directives in this section will not be 
# translated into machine language. They are instructions 
# to the assembler, linker, and loader to set aside (and 
# initialize) space in the static memory area of the program. 
# The labels work like pointers-- by the time the code is 
# run, they will be replaced with appropriate addresses.

# For this program, we will allocate a buffer to hold the
# result of your sprintf function. The asciiz blocks will
# be initialized with null-terminated ASCII strings.

buffer:	.space	2000			# 2000 bytes of empty space 
					# starting at address 'buffer'
	
format:	.asciiz "string: %5.5s\n%5.5s\n%.3s\n%4.6s\n"
					#EXPECTED OUTPUT:
					#30 characters:
					#string: abcde
					#abc  
					#hij
					#mnopqr
str1:	.asciiz "abcdefg"		# null-terminated string at
					# address 'str1'
str2:   .asciiz "abc" 			# null-terminated string at
                                        # address 'str2'
str3:	.asciiz "hijkl"

str4:	.asciiz "mnopqrst"
chrs:	.asciiz " characters:\n"	# null-terminated string at 
					# address 'chrs'

# The "text" of the program is the assembly code that will
# be run. This directive marks the beginning of our program's
# text segment.

	.text
	
# The sprintf procedure (really just a block that starts with the
# label 'sprintf') will be declared later.  This is like a function
# prototype in C.


		
# The special label called "__start" marks the start point
# of execution. Later, the "done" pseudo-instruction will make
# the program terminate properly.	

main:
	addi	$sp,$sp,-28	# reserve stack space

	# $v0 = sprintf(buffer, format, str1, str2)
	
	la	$a0,buffer	# arg 0 <- buffer
	la	$a1,format	# arg 1 <- format
	la	$a2,str1	# arg 2 <- str1
	la 	$a3,str2        # arg 3 <- str2
	
	la	$t0,str3
	sw	$t0, 16($sp)	#testing one argument on the stack
	la	$t0,str4
	sw	$t0, 20($sp)	#testing two arguments on the stack
		
	
	sw	$ra,24($sp)	# save return address
	
	jal	sprintf		# $v0 = sprintf(...)

	# print the return value from sprintf using
	# putint()

	add	$a0,$v0,$0	# $a0 <- $v0
	jal	putint		# putint($a0)

	## output the string 'chrs' then 'buffer' (which
	## holds the output of sprintf)

 	li 	$v0, 4	
	la     	$a0, chrs
	syscall
	#puts	chrs		# output string chrs
	
	li	$v0, 4
	la	$a0, buffer
	syscall
	#puts	buffer		# output string buffer
	
	addi	$sp,$sp,28	# restore stack
	li 	$v0, 10		# terminate program
	syscall

# putint writes the number in $a0 to the console
# in decimal. It uses the special command
# putc to do the output.
	
# Note that putint, which is recursive, uses an abbreviated
# stack. putint was written very carefully to make sure it
# did not disturb the stack of any other functions. Fortunately,
# putint only calls itself and putc, so it is easy to prove
# that the optimization is safe. Still, we do not recommend 
# taking shortcuts like the ones used here.

# HINT:	You should read and understand the body of putint,
# because you will be doing some similar conversions
# in your own code.
	
putint:	addi	$sp,$sp,-8	# get 2 words of stack
	sw	$ra,0($sp)	# store return address
	
	# The number is printed as follows:
	# It is successively divided by the base (10) and the 
	# reminders are printed in the reverse order they were found
	# using recursion.

	remu	$t0,$a0,10	# $t0 <- $a0 % 10
	addi	$t0,$t0,'0'	# $t0 += '0' ($t0 is now a digit character)
	divu	$a0,$a0,10	# $a0 /= 10
	beqz	$a0,onedig	# if( $a0 != 0 ) { 
	sw	$t0,4($sp)	#   save $t0 on our stack
	jal	putint		#   putint() (putint will deliberately use and modify $a0)
	lw	$t0,4($sp)	#   restore $t0
	                        # } 
onedig:	move	$a0, $t0
	li 	$v0, 11
	syscall			# putc #$t0
	#putc	$t0		# output the digit character $t0
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return
#-------------------------------------------------------------------------------
sprintf:
	addi	$s0, $sp, 16	#copy sp's position to t9. skip a0, a1, a2 and a3
	li	$v0, 0		#initialize character count to 0 
	li	$s1, 1		#s1 holds ammount of args. initialize it to 1 (assuming a2 is filled)
	beq	$a3, 0, arg1	#if a3 is empty, assume that there's only 1 arg (a2) and just write it
argcount:			#determine ammt of args. only come here if a3 has an arg
	addi	$s1, $s1, 1	#increment count of args
	lw	$t0, 0($s0)	#get first arg on stack
	beq	$t0, 0, arg1	#once we reach an empty address, begin writing arguments
	addi	$s0, $s0, 4	#look at next stack element
	j 	argcount
sarg:				#loads arguments on stack
	addi	$s1, $s1, -1	#decrement count of arguments
	lw	$t6, 0($s0)
	addi	$s0, $s0, 4	#look at next stack argument
	j	write1
arg2:				#loads argument in a3 into t6. this should run only once
	bne	$s1, $t8, sarg	#move up to the stack arguments if t7 != (max args) -1
	addi	$s0, $sp, 16	#reload stack pointer + 12 just in case we need it later
	addi	$t6, $a3, 0	#t6 holds argument in a3
	addi	$s1, $s1, -1	#decrement count of arguments
	j 	write1
	
arg1:				#loads argument in a2 into t6. this will always run 1st, and only once
	addi	$t6, $a2, 0
	addi	$s1, $s1, -1	#decrement count of arguments
	addi	$t8, $s1, 0	#store the value of (max args) -1. this is when we'll write a3 (ex: if there are 2 args, write it 
				#when t7 = 1)	
write1:				#writes non format characters, passes to appropriate function if otherwise
				#NOTE: t6 holds current argument to write
	lb	$t0, 0($a1)	#load a do character of format
	beq	$t0, '\0', end	#if null is reached, string is finished
	beq	$t0, '%', dformat	#enter formatting functions if % found
	sb	$t0, 0($a0)	#write character to outbuff
	addi	$a1, $a1, 1	#point to next character of format
	addi	$a0, $a0, 1	#point to next character of outbuff
	addi	$v0, $v0, 1	#increment character count up 
	j	write1
dformat:
	addi	$a1, $a1, 1	#point to next character of format. we don't care about the %
	lb	$t0, 0($a1)	#load next character of format
	beq	$t0, 'u', u	#write arg as unsigned int. just treat it as +d with no bounds
	#beq	$t0, 'x', hex	#translate char to hex given x tag
	beq	$t0, 'o', octal	#translate char to octal given o tag
	beq	$t0, '+', ignore	#if there's a negative sign in the arg, we move past it 
	#beq	$t0, '-', ldigit	#set flag for left justification  
	beq	$t0, 'd', digit 	#write arg as signed decimal
	beq	$t0, 's', string	#write arg normally
	beq	$t0, '.', precision	#if a . is found, it means a number follows that denotes precision
width:				#if none of these tags are found, it means a width tag was found. translate it and store it
	addi	$t1, $t0, -48	#convert from ascii to number. $t1 = width
	li	$t5, 1		#flag denoting that there's width
	j	dformat 	#we return to format if a # is found. we know that the last format tag will always not be a #
precision:			#translate and store precision
	addi	$a1, $a1, 1	#move past the '.'
	lb	$t0, 0($a1)
	addi	$t2, $t0, -48	#$t2 = precision
	li	$t3, 1		#flag denoting that there's precision
	j	dformat
ignore:				#check if arg is negative. if so, flip it and add 1. by default we write a '+'
	li	$t0, '+'
	sb	$t0, 0($a0)
	addi	$a0, $a0, 1	#increment outbuff pointer
	addi	$v0, $v0, 1	#increment global character count
	sgt	$t0, $t6, 0
	bnez	$t0, dformat 	#if there isn't a negative we don't care, write normally
	not	$t6, $t6	#flip bits and add 1
	addi	$t6, $t6, 1
	j 	dformat
u:				#check if arg is negative. if its positive we leave it alone, if its negative convert
	sgt	$t0, $t6, 0
	bnez	$t0, digit 	#if there isn't a negative we don't care, write normally
	not	$t6, $t6	#flip bits and add 1
	addi	$t6, $t6, 1
	j 	digit
	
digit:				#determines how to write argument contents given a signed decimal tag
	addi	$a1, $a1, 1	#move past the 'd' or 'u'
	slti	$t0, $t6, 0	#check if argument isn't already converted from negative/ is negative
	bne	$t0, 1, posi	#if t0 is 0, skip following instructions
	not	$t6, $t6	#flip bits and add 1 to get positive equivalent
	addi	$t6, $t6, 1
	li	$t0, '-'	#write a negative sign
	sb	$t0, 0($a0)	
	addi	$a0, $a0, 1
	addi	$t7, $t7, 1
	addi	$v0, $v0, 1
posi:	and	$t4, $t3, $t5	#check if both precision and width are assigned
	beq	$t4, 1, dboth	#if precision and width specified, check if we need to write blanks (with respect to precision)
	or	$t4, $t3, $t5	#check if either precision or width are assigned
	beqz	$t4, sdigit	#if there is no precision/width we do a simple write
	beq	$t3, 1, pdigit	#if there is only precision specified
	beq	$t5, 1, wdigit	#if there is only width specified
string:				#determines how to write argument contents given a string tag
	addi	$a1, $a1, 1	#move past the 's'
	and	$t4, $t3, $t5	#check if both precision and width are assigned
	beq	$t4, 1, both	#if precision and width specified, check if we need to write blanks (with respect to precision)
	or	$t4, $t3, $t5	#check if either precision or width are assigned
	beqz	$t4, swrite	#if there is no precision/width we do a simple write
	beq	$t3, 1, pwrite	#if there is only precision specified
	beq	$t5, 1, wwrite	#if there is only width specified
#-------
octal:
	li	$t4, 8		#load 10 for division
	div	$t6, $t4	#divide arg by 10
	mflo	$t6		#store quotient in t0
	mfhi	$t4		#store remainder in t4
	beqz	$t6, oclast	#if quotient is zero, we've reached the last (or only) digit. write the remainder instead
	bgt	$t6, 7, ocmore	#if quotient is more than one digit, we need to divide it more
ocr:	addi	$t6, $t6, 48	#convert digit to ascii character
	sb	$t6, 0($a0)	#write character to outbuff
	addi	$t6, $t6, -48
	addi	$a0, $a0, 1	#increment pointer to outbuff
	addi	$v0, $v0, 1	#increment global count of characters written
	addi	$t6, $t4, 0	#move quotient to arg
	j	octal
ocmore:	divu	$t6, $t6, 8	#divide quotient by 10 until it's one digit (less than 10)
	blt	$t6, 8, ocr	#write single digit to outbuff
	j	ocmore
oclast:	addi	$t4, $t4, 48	#convert digit to ascii character
	sb	$t4, 0($a0)	#write the quotient to outbuff. since this is the last digit, and there is no width, just end
	addi	$a0, $a0, 1	#increment outbuff pointer
	addi	$v0, $v0, 1	#increment global count of characters written
	j	end
	
#-------
pwrite:				#loop to write characters from argument given only precision	
	lb	$t0, 0($t6)	#load a character from current argument
	beq	$t0, '\0', end	#don't need to keep writing chars if terminator is reached
	sb	$t0, 0($a0)	#write character to outbuff
	addi	$t6, $t6, 1	#increment pointers to argument and outbuff
	addi	$a0, $a0, 1
	addi	$t7, $t7, 1	#increment count of characters written using t7
	addi	$v0, $v0, 1	#increment global count of characters written
	beq	$t7, $t2, end	#stop writing characters once precision is reached
	j	pwrite
#-------
pdigit:				#write digits given only precision. note that we dont need to worry about left-justification
	li	$t4, 10		#load 10 for division
	div	$t6, $t4	#divide arg by 10
	mflo	$t6		#store quotient in t0
	mfhi	$t4		#store remainder in t4
	beqz	$t6, plast	#if quotient is zero, we've reached the last (or only) digit. write the remainder instead
	bgt	$t6, 9, pmore	#if quotient is more than one digit, we need to divide it more
pr:	addi	$t6, $t6, 48	#convert digit to ascii character
	sb	$t6, 0($a0)	#write character to outbuff
	addi	$t6, $t6, -48
	addi	$a0, $a0, 1	#increment pointer to outbuff
	addi	$t7, $t7, 1	#increment count of characters written using t7
	addi	$v0, $v0, 1	#increment global count of characters written
	addi	$t6, $t4, 0	#move quotient to arg
	beq	$t7, $t2, end	#stop writing characters once precision is reached
	j	pdigit
pmore:	divu	$t6, $t6, 10	#divide quotient by 10 until it's one digit (less than 10)
	blt	$t6, 10, pr	#write single digit to outbuff
	j	pmore
plast:	addi	$t4, $t4, 48	#convert digit to ascii character
	sb	$t4, 0($a0)	#write the quotient to outbuff. since this is the last digit, and there is no width, just end
	addi	$a0, $a0, 1	#increment outbuff pointer
	addi	$v0, $v0, 1	#increment global count of characters written
	j	end
#-------
wwrite:				#loop to write characters given only width
	lb	$t0, 0($t6)	#load a character from current argument
	beq	$t0, '\0', blnk	#if null is reached, check if characters still need to be written
	sb	$t0, 0($a0)	#write character to outbuff
	addi	$t6, $t6, 1	#increment pointers to argument and outbuff
	addi	$a0, $a0, 1
	addi	$t7, $t7, 1	#increment count of characters written. we keep writing chars until null is reached
	addi	$v0, $v0, 1	#increment global count of characters written
	j	wwrite
#-------
wdigit:				#write digits given only precision. note that we dont need to worry about left-justification
	li	$t4, 10		#load 10 for division
	div	$t6, $t4	#divide arg by 10
	mflo	$t6		#store quotient in t0
	mfhi	$t4		#store remainder in t4
	beqz	$t6, wlast	#if quotient is zero, we've reached the last (or only) digit. write the remainder instead
	bgt	$t6, 9, wmore	#if quotient is more than one digit, we need to divide it more
wr:	addi	$t6, $t6, 48	#convert digit to ascii character
	sb	$t6, 0($a0)	#write character to outbuff
	addi	$t6, $t6, -48
	addi	$a0, $a0, 1	#increment pointer to outbuff
	addi	$t7, $t7, 1	#increment count of characters written using t7
	addi	$v0, $v0, 1	#increment global count of characters written
	addi	$t6, $t4, 0	#move quotient to arg
	beq	$t7, $t2, end	#stop writing characters once precision is reached
	j	wdigit
wmore:	divu	$t6, $t6, 10	#divide quotient by 10 until it's one digit (less than 10)
	blt	$t6, 10, pr	#write single digit to outbuff
	j	wmore
wlast:	addi	$t4, $t4, 48	#convert digit to ascii character
	sb	$t4, 0($a0)	#write the quotient to outbuff. since this is the last digit, and there is no width, just end
	addi	$a0, $a0, 1	#increment outbuff pointer
	addi	$t7, $t7, 1
	addi	$v0, $v0, 1	#increment global count of characters written
	j	blnk
#-------
blnk:
	bge	$t7, $t1, end	#if we've written enough characters to satisfy width, end
	li	$t0, 32		#load space (32 in ascii)
	sb	$t0, 0($a0)	#write it to outbuff
	addi	$a0, $a0, 1	#increment pointer to outbuff
	addi	$t7, $t7, 1	#increment count of characters written
	addi	$v0, $v0, 1	#increment global count of characters written
	j	blnk
#-------
swrite:
	lb	$t0, 0($t6)	#load a character from current argument
	beq	$t0, '\0', end	#stop writing once terminator is reached
	sb	$t0, 0($a0)	#write character to outbuff
	addi	$t6, $t6, 1	#increment pointers to argument and outbuff
	addi	$a0, $a0, 1
	addi	$v0, $v0, 1	#increment global count of characters written
	j	swrite
#-------
sdigit:				#write digits given only precision. note that we dont need to worry about left-justification
	li	$t4, 10		#load 10 for division
	div	$t6, $t4	#divide arg by 10
	mflo	$t6		#store quotient in t0
	mfhi	$t4		#store remainder in t4
	beqz	$t6, slast	#if quotient is zero, we've reached the last (or only) digit. write the remainder instead
	bgt	$t6, 9, smore	#if quotient is more than one digit, we need to divide it more
sr:	addi	$t6, $t6, 48	#convert digit to ascii character
	sb	$t6, 0($a0)	#write character to outbuff
	addi	$t6, $t6, -48
	addi	$a0, $a0, 1	#increment pointer to outbuff
	addi	$v0, $v0, 1	#increment global count of characters written
	addi	$t6, $t4, 0	#move quotient to arg
	j	sdigit
smore:	divu	$t6, $t6, 10	#divide quotient by 10 until it's one digit (less than 10)
	blt	$t6, 10, sr	#write single digit to outbuff
	j	smore
slast:	addi	$t4, $t4, 48	#convert digit to ascii character
	sb	$t4, 0($a0)	#write the quotient to outbuff. since this is the last digit, and there is no width, just end
	addi	$a0, $a0, 1	#increment outbuff pointer
	addi	$v0, $v0, 1	#increment global count of characters written
	j	end
#-------	
both:
	lb	$t0, 0($t6)	#load a character from current argument
	beq	$t0, '\0', blnk	#if null is reached, check if characters still need to be written
	sb	$t0, 0($a0)	#write character to outbuff
	addi	$t6, $t6, 1	#increment pointers to argument and outbuff
	addi	$a0, $a0, 1
	addi	$t7, $t7, 1	#increment count of characters written
	addi	$v0, $v0, 1	#increment global count of characters written
	beq	$t7, $t2, end	#stop writing characters once precision is reached
	j	both
#-------
dboth:				#write digits given only precision. note that we dont need to worry about left-justification
	li	$t4, 10		#load 10 for division
	div	$t6, $t4	#divide arg by 10
	mflo	$t6		#store quotient in t0
	mfhi	$t4		#store remainder in t4
	beqz	$t6, dlast	#if quotient is zero, we've reached the last (or only) digit. write the remainder instead
	bgt	$t6, 9, dmore	#if quotient is more than one digit, we need to divide it more
dr:	addi	$t6, $t6, 48	#convert digit to ascii character
	sb	$t6, 0($a0)	#write character to outbuff
	addi	$t6, $t6, -48
	addi	$a0, $a0, 1	#increment pointer to outbuff
	addi	$t7, $t7, 1	#increment count of characters written using t7
	addi	$v0, $v0, 1	#increment global count of characters written
	addi	$t6, $t4, 0	#move quotient to arg
	beq	$t7, $t2, end	#stop writing characters once precision is reached
	j	dboth
dmore:	divu	$t6, $t6, 10	#divide quotient by 10 until it's one digit (less than 10)
	blt	$t6, 10, dr	#write single digit to outbuff
	j	dmore
dlast:	addi	$t4, $t4, 48	#convert digit to ascii character
	sb	$t4, 0($a0)	#write the quotient to outbuff. since this is the last digit, and there is no width, just end
	addi	$a0, $a0, 1	#increment outbuff pointer
	addi	$t7, $t7, 1
	addi	$v0, $v0, 1	#increment global count of characters written
	j	blnk

#-------
end:				#check if all args are written
	li	$t3, 0		#reset width + precision flags to 0
	li	$t5, 0		
	li	$t7, 0		#reset increment
	li	$t9, 0		#reset digit holder 
	bnez	$s1, arg2	#once s1 is zero it means all args are written	
	jr	$ra		#this sprintf implementation rocks!
#------------------------------------------------------------------------