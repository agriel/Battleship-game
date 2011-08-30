#--------------------------- #
# Facundo Agriel	#
# Project 4		#
# CS 366		#
#--------------------------- #
.data
EnterGuess:		.asciiz			"\nPlease enter your guess: \n"
Miss:			.asciiz			"\nMiss\n"
Hit:			.asciiz			"\nHit\n"
RowLabel:		.asciiz			"\n  A B C D E F G H\n"
Welcome:		.asciiz			"Welcome to the game of battleship, please give me a moment while I place the ships on the grid for you to locate.\n"
incrrctInptMsg: 	.asciiz			"\nSorry, you entered an incorrect input sequence. Please Try again.\n"
battleSunk:		.asciiz			"You've sunk my battle ship!\n"
cruiserSunk:		.asciiz			"You've sunk my cruiser ship!\n"
submarineSunk:	.asciiz			"You've sunk my submarine!\n"
mineSunk:		.asciiz			"You've sunk my minesweeper!\n"
endOfGame:		.asciiz "\nGame Over!\n"
#Variables to keep track if a ship has been sunk
# For example, for the battleship, 
# it is address -> bbbbxp
# the first 4 b's are the current positions
# the x is the offset to which index to go to in the array
# p is the parity bit. Which means that it keeps track if we already printed the message
# out.
arrayDisplay:		.space	64 				#allocate for 64 char array
input:			.space 8				#7 bytes for showall + 1b for null char 
cruiserMark:		.space 7		
battleMark:		.space 6
sub1Mark:		.space 5 
sub2Mark: 		.space 5 
mineMark:		.space 4
subD1:			.data	3				#to choose which sub to use
subD2:			.data 	3			
.text
main:
jal __initialize
jal __placeShips
la $a0, Welcome
li $v0, 115 
jal PrintDriver
jal __printBoard
li $s1, 5
gameLoop:
	la $a0, EnterGuess
	li $v0, 29
	jal PrintDriver
	jal __getInputAndConvert
	jal __checkIfSunk
	jal __printBoard
	jal __checkEndOfGame
	addi $s1, $s1, 1
	bgt $s1, 4, gameLoop
b end

#---------------------------------------------------------------------	#
# This function initializes the board with dashes in the   	#
# array. Does not place ships. __placeShips does that     	#
#---------------------------------------------------------------------	#
__initialize:
	li $t2, 45						#initialize char array with dashes
	la $t0, arrayDisplay
	addi $t1, $t0, 64 					#$t1 will point to value after array
initLoop: 				
	sb $t2, 0($t0) 						#store value read
	addi $t0, $t0, 1 					#change to 1 for char
	blt $t0, $t1, initLoop 					#know end of array is when $t0 is at array + 64
	jr $ra							#return

#---------------------------------------------------------			#
# This function randomly places the ships in the board.   	#
# Ships are done in this order:					#	
# cruiser - size: 5 and qty: 1                            		#
# battleship - size: 4 and qty: 1                        		#
# submarine - size: 3 and qty: 2                          		#
# Some facts that will make the algorithm run more		#
# efficiently and help eliminate some error checking      	#
# code:							#	
# -cruisers can only start at 1-4 if placed vertically  		#
#		-start at A through D if horizontally		#
# -battleship can only start at 1-5 if placed vertically	  	#
#  		-start at A through E if placed horizontally     	#
# -submarines can only start at 1-6 if placed vertically  	#
#		-start at A through F if placed horizontally     	#
# -minesweeper can only start at 1-7 if placed vertically  	#
#		-start at A through G if placed horizontally     	#
# So there will be a total of of 6 functions to place the 	#
#  ships on the board.  	     				#
# I used a sort of brute force approach to place the ships	#
# For example, we generate a random number with an upper	#
# bound of 4 for the battleship and initially check if   		#
# there is a dash there and proceed as long as there are  	#
# dashes. The process repeats untill the ship has been    	#
# placed (this is the "brute force approach"              		#
#---------------------------------------------------------			#
__placeShips:							
#---cruiser placement is first.------------------------		#
  #--------------------------------------------------			#
	#---cruiser placement horizontal or vertical---#
	randomVertorHorCruiser:
	li $a1, 2						#upperbound is at 2 so 0-1 will be generated
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4

	beq $a0, 1, vertCruisrPlacement			#if equal to 1 then it's vertical
	
	#---horizontal placement of cruiser---#
	horiCruisrPlacement:
	li $a1, 4						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 8						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	li $t2, 99						#ascii code for 'c' 
	li, $t3, 0						#load var index for loop
	
	storeHorCruiserLoop:
	sb $t2, 0($t1)						#store 'c'
	addi $t1, $t1, 1						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 5, storeHorCruiserLoop			#stop after 5 iterations
	b placeBattleships
	
  #---vertical placement of cruiser---#
	vertCruisrPlacement:
	li $a1, 8						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 4						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	li $t2, 99						#ascii code for 'c' 
	li, $t3, 0						#load var index for loop
	
	storeVerCruiserLoop:
	sb $t2, 0($t1)						#store 'c'
	addi $t1, $t1, 8						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 5, storeVerCruiserLoop			#stop after 5 iterations	
	
#---battleship placement is second.---#
	placeBattleships:
	
 #---randomize vertical or horizontal placement---#
   	 li $a1, 2							#upperbound is at 2 so 0-1 will be generated
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	beq $a0, 1, vertBattlPlacement			#if equal to 1 then it's vertical

 #---horizontal placement of battleship---#
	horiBattlePlacement:
	li $a1, 4						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 8						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	li $t2, 98						#ascii code for 'b' 
	li  $t3, 0						#load var index for loop
	
  #check all positions that will placed aren't taken
    checkHorBattleLoop:
	lb $t4, 0($t1)
    bne $t4, 45 horiBattlePlacement
	addi $t3, $t3, 1
	addi $t1, $t1, 1
    blt $t3, 4, checkHorBattleLoop
	
	addiu $t1, $t1, -4					#reset address+offset
	li, $t3, 0						#reset
	
	storeHorBattlLoop:
	sb $t2, 0($t1)						#store 'b'
	addi $t1, $t1, 1						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 4, storeHorBattlLoop				#stop after 4 iterations
	b placeSubmarines
	
 #---vertical placement of battleships---#	
	vertBattlPlacement:
	li $a1, 8						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 5						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space

	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	li $t2, 98						#ascii code for 'b' 
	li, $t3, 0						#load var index for loop
	
checkVerBattleLoop:
	lb $t4, 0($t1)
    	bne $t4, 45, vertBattlPlacement
	addi $t3, $t3, 1
	addi $t1, $t1, 8
   	blt $t3, 4, checkVerBattleLoop
	addiu $t1, $t1, -32					#reset address+offset
	li, $t3, 0						#reset
	storeVerBattleLoop:
	sb $t2, 0($t1)						#store 'b'
	addi $t1, $t1, 8						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 4, storeVerBattleLoop	#stop after 4 iterations

#-------------------------------------------------------------------------------#
#---Placement of 2 submarines---#
	li $t7, 0							#index for loop to place two ships
	placeSubmarines:					#$t7 might contain a diff value
 #---randomize vertical or horizontal placement---#
  	li $a1, 2						#upperbound is at 2 so 0-1 will be generated
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	beq $a0, 1, vertSubPlacement			#if equal to 1 then it's vertical
  #---Store horizontal submarines---#
	horiSubPlacement:
	li $a1, 6						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 8						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	
	li 	$t2, 115					#ascii code for 's' 
	li 	$t3, 0						#load var index for loop
	
	checkHorSubLoop:
	lb $t4, 0($t1)
    	bne $t4, 45, horiSubPlacement
	addi $t3, $t3, 1
	addi $t1, $t1, 1
    	blt $t3, 3, checkHorSubLoop
	
	addiu 	$t1, $t1, -3					#reset address+offset
	li 	$t3, 0						#reset
		
	storeHorSubLoop:
		sb 	$t2, 0($t1)						#store 's' $t1, array disp
		addi 	$t1, $t1, 1						#increment
		addi 	$t3, $t3, 1						#increment
		#li	$t3, 0
	
	blt $t3, 3, storeHorSubLoop				#stop after 3 iterations
	b subLoop
	
  #--Vertical placement of Subs--#
	vertSubPlacement:	
	li $a1, 8						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 6						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	
	li $t2, 115						#ascii code for 's' 
	li, $t3, 0						#load var index for loop
	
	checkVerSubLoop:
	lb $t4, 0($t1)
    	bne $t4, 45, vertSubPlacement
	addi $t3, $t3, 1
	addi $t1, $t1, 8
    	blt $t3, 3, checkVerSubLoop
	
	addiu 	 $t1, $t1, -24					#reset address+offset
	li	 $t3, 0						#reset
		
	storeVerSubLoop:
	sb $t2, 0($t1)						#store 's'
	addi $t1, $t1, 8						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 3, storeVerSubLoop				#stop after 3 iterations

	subLoop:
	addiu $t7, $t7, 1
	blt $t7, 2, placeSubmarines

#---Placement of minesweeper---#
	placeMinesweeper:					

 #---randomize vertical or horizontal placement---#
  	li 	$a1, 2						#upperbound is at 2 so 0-1 will be generated
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	beq $a0, 1, vertMinPlacement				#if equal to 1 then it's vertical
	
  #---Store horizontal minesweeper---#
	horiMinPlacement:
	li $a1, 7						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 7						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add 	$a0, $t0, $a0					#get offset of array index
	la 	$t1, arrayDisplay				#load address of array
	addu 	$t1, $t1, $a0					#add offset to address
	
	li 	$t2, 109					#ascii code for 'm' 
	li 	$t3, 0						#load var index for loop	
	checkHorMinLoop:
	lb 	$t4, 0($t1)
    	bne 	$t4, 45, horiMinPlacement
	addi 	$t3, $t3, 1
	addi 	$t1, $t1, 1
    	blt 	$t3, 2, checkHorMinLoop
	
	addiu 	$t1, $t1, -2					#reset address+offset
	li 	$t3, 0						#reset
		
	storeHorMinLoop:
	sb $t2, 0($t1)						#store 'm'
	addi $t1, $t1, 1						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 2, storeHorMinLoop				#stop after 2 iterations
	b finishPlacingShips
	
  #--Vertical placement of Minesweeper--#
	vertMinPlacement:	
	li $a1, 7						#set upper bound
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	move $t0, $a0						#move out to make room for next random
	li $a1, 7						#now we choose row
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	GenerateRandom
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	addiu $sp, $sp, -12					#allocate space
	sw $a0, 0($sp)						#save last row random
	sw $t0, 4($sp)						#save column
	sw $ra, 8($sp)						#save return address
	jal __convertNumber					#need to convert row to array index
	lw $ra, 8($sp)						#load return address
	lw $t0, 4($sp)						#load column 
	lw $a0, 0($sp)						#get value from function
	addiu $sp, $sp, 12					#deallocate space
	
	add $a0, $t0, $a0					#get offset of array index
	la $t1, arrayDisplay					#load address of array
	addu $t1, $t1, $a0					#add offset to address
	
	li $t2, 109						#ascii code for 'm' 
	li  $t3, 0						#load var index for loop
	
	checkVerMinLoop:
	lb $t4, 0($t1)
    	bne $t4, 45, vertMinPlacement
	addi $t3, $t3, 1
	addi $t1, $t1, 8
    	blt $t3, 2, checkVerMinLoop
	
	addiu $t1, $t1, -24					#reset address+offset
	li, $t3, 0						#reset
		
	storeVerMinLoop:
	sb $t2, 0($t1)						#store 'm'
	addi $t1, $t1, 8						#increment
	addi $t3, $t3, 1						#increment
	blt $t3, 2, storeVerMinLoop				#stop after 2 iterations
	
	finishPlacingShips:
	jr $ra						
#-----------------------------------------------------------   #
# This function checks if the game has ended     #
#-----------------------------------------------------------   #
__checkEndOfGame:
	la $t0, arrayDisplay
	li $t3, 0
	eofGameLoop:
		lb $t1, 0($t0)
		beq $t1, 98, finishChecking			# check if 'b' is seen
		beq $t1, 99, finishChecking			# check if 'c' is seen
		beq $t1, 115, finishChecking			# check if 's' is seen
		beq $t1, 109, finishChecking			# check if 'm' is seen
		addiu $t0, $t0, 1
		addiu $t3, $t3, 1
		blt $t3, 64, eofGameLoop
		la $a0, endOfGame
		li $v0, 15
		addiu	$sp, $sp, -4
		sw	$ra, 0($sp)
		jal	PrintDriver
		lw	$ra, 0($sp)
		addiu	$sp, $sp, 4
		b end
		finishChecking:
		jr $ra

	
#-----------------------------------------------------------		#
# This function is called to read input from user and to    	#
# convert input into a sequential number to work with the  	#
# array. For example. A1 -> 0, B1 -> 1, H8 -> 63            	#
# decimal number is then stored in $a1		   	#
# 							   	#
# Registers used:						#		
# $a1 holds first part of input i.e. A,B,C and is converted 	#
# $t1 is out parameter.				 	#
# to a decimal number. A->0, B->1, C->2, etc...		#
#-----------------------------------------------------------		#
__getInputAndConvert:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, input
	la $a0, input
	jal GetKeyDriver					# send to GetKDriver which gets input
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	
	checkForShowall:
	# check showall: 115, 104, 111, 119, 97, 108,108, 0
	# rather crude, but it works.
	lb $a1, 0($a0)
	bne $a1, 115, checkIfBoardInput
	lb $a1, 1($a0)
	bne $a1, 104, checkIfBoardInput	
	lb $a1, 2($a0)
	bne $a1, 111, checkIfBoardInput
	lb $a1, 3($a0)
	bne $a1, 119, checkIfBoardInput
	lb $a1, 4($a0)
	bne $a1, 97, checkIfBoardInput
	lb $a1, 5($a0)
	bne $a1, 108, checkIfBoardInput
	lb $a1, 6($a0)
	bne $a1, 108, checkIfBoardInput
	lb $a1, 7($a0)
	bne $a1, 0x0a, checkIfBoardInput
	
	beq $s0, 1, turnOffCheat
	li $s0, 1
	b endGettingInput
	turnOffCheat:
	li $s0, 0 						#enable showall
	b endGettingInput
	
	checkIfBoardInput:
	lb $a1, 0($a0)						#load letter. example A1 - get the A
	addi $a1, $a1, -65					#convert letter to integer. A=0, B=1, C=2...
	li $a2, 8						#check if value is in range
	bgt $a1, $a2, incorrectInputLabel
	li $a2, 0						#check input
	blt $a1, $a2, incorrectInputLabel
	lb $a0, 1($a0)						#load integer example A1 - get the 1

	#--------------------------------------------------------		#
	# The following is essentially the same as a 		#
	# switch case 						#
	# in a higher level language.		        		#
	#--------------------------------------------------------		#

	bne $a0, 49, second					#if not equal to one add 0 for row
	li $a0, 0						#load zero to register
	b last							#done. Branch to compute value
	second:						#Same as above...
		bne $a0, 50, third		
		li $a0, 8
		b last
	third:							#Same as above...
		bne $a0, 51, fourth
		li $a0, 16
		b last
	fourth:							#Same as above...
		bne $a0, 52, fifth
		li $a0, 24
		b last
	fifth:							#Same as above...
		bne $a0, 53, sixth
		li $a0, 32
		b last
	sixth:							#Same as above...
		bne $a0, 54, seventh
		li $a0, 40
		b last
	seventh:						#Same as above...
		bne $a0, 55, eight
		li $a0, 48
		b last
	eight:	
		bne $a0, 56, incorrectInputLabel
		li $a0, 56
		b last
		
	incorrectInputLabel:
	
	la $a0, incrrctInptMsg
	li $v0, 68
	
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PrintDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 
	b __getInputAndConvert
	
	last:							#last label
	add $t0, $a0, $a1					#add value of letter to number
	la $t1, arrayDisplay
	addu $t1, $t0, $t1
	lb $t2 0($t1)
	beq $t2, 98, changeB
	beq $t2, 99, changeC
	beq $t2, 115, changeS
	beq $t2, 109, changeM
	beq $t2, 66, shipNoHitMiss
	beq $t2, 67, shipNoHitMiss
	beq $t2, 83, shipNoHitMiss
	beq $t2, 77, shipNoHitMiss
	beq $t2, 120, shipNoHitMiss
	b shipNoHit
	changeB:
		la	$t2, battleMark					#load address
		lb	$t3, 4($t2)					# get offset to add to addr
		move	$t4, $t2
		add	$t2, $t3, $t2					# add offset to addr
		addiu	$t3, $t3, 1					# increment offset
		sb	$t3, 4($t4) 					# store offset back - before incr
		li 	$t3, 66
		sb	$t3, 0($t2)
		sb 	$t3, 0($t1)
		b shipHit
	changeC:
		la	$t2, cruiserMark				#load address
		lb	$t3, 5($t2)					# get offset to add to addr
		move	$t4, $t2
		add	$t2, $t3, $t2					# add offset to addr
		addiu	$t3, $t3, 1					# increment offset
		sb	$t3, 5($t4) 					# store offset back - before incr
		li 	$t3, 67						# get char
		sb	$t3, 0($t2)					# write new char
		sb 	$t3, 0($t1)					# write to board
		b shipHit
	changeS:
		li 	$t3, 83
		sb 	$t3, 0($t1)
		b shipHit
	changeM:
		la	$t2, mineMark					#load address
		lb	$t3, 2($t2)					# get offset to add to addr
		move	$t4, $t2
		add	$t2, $t3, $t2					# add offset to addr
		addiu	$t3, $t3, 1					# increment offset
		sb	$t3, 2($t4) 					# store offset back - before incr
		li 	$t3, 77
		sb	$t3, 0($t2)
		sb 	$t3, 0($t1)
		b shipHit
	shipHit:
		la 	$a0, Hit
		li 	$v0, 7
		addiu	$sp, $sp, -4
		sw	$ra, 0($sp)
		jal PrintDriver
		lw	$ra, 0($sp)
		addiu	$sp, $sp, 4
	b endGettingInput

	shipNoHit:
		li $t3, 120
		sb $t3, 0($t1)
	shipNoHitMiss:
		la $a0, Miss
		li $v0, 8
		addiu	$sp, $sp, -4
		sw	$ra, 0($sp)
		jal PrintDriver
		lw	$ra, 0($sp)
		addiu	$sp, $sp, 4 
	endGettingInput:
		jr $ra

#-----------------------------------------------------------------------------		#
# This function assists the __placeShips function               		#
# we are given an integer and find the value in the board  		#
# for the horizontal position.				       		#
# For example. The value 1 is row 1 so it is converted to  		# 
# a zero. After that, we just add the value of the column       		#
# and we esentially have the index of the array. Another       		#
# example is the number 8. This is converted to 56              		#
# and so to get the array index, we just add the                     		# 
# corresponding value from the column. A = 1, B = 2, etc.. 	 	#
# The code is pretty simple: it is basically a switch case         		#
# in a higher level language.                                                       	#
# value should be placed in 0($sp)	and returned at same  		#
# stack offset								#
#----------------------------------------------------------			#
__convertNumber:
	lw $t0, 0($sp)
	one:
		bne $t0, 0, two
		li $t0, 0
		b finishConvNum
	two:
		bne $t0, 1, three
		li $t0, 8
		b finishConvNum
	three:	
		bne $t0, 2, four
		li $t0, 16
		b finishConvNum
	four:	
		bne $t0, 3, five
		li $t0, 24
		b finishConvNum
	five:
		bne $t0, 4, six
		li $t0, 32
		b finishConvNum
	six:	
		bne $t0, 5, seven
		li $t0, 40
		b finishConvNum
	seven:
		bne $t0, 6, eightt
		li $t0, 48
		b finishConvNum
	eightt:
		li $t0, 56
	finishConvNum:
	sw $t0, 0($sp)
	jr $ra

#--------------------------------------------------------- 	#
# This function prints the board out              	    	#
#--------------------------------------------------------- 	#
__printBoard:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)				#save return address

	la $t0, arrayDisplay				#Load address of array
	la $t1, arrayDisplay
	addiu $t1, $t1, 64

	li $v0, 19					# length of string to print
	la $a0, RowLabel				#print "  A B C D E F G H"
	jal PrintDriver

	li $t4, 49					#for printing number 1 through 8
	li $t5, 1						#move number 1 for comparison
	li $t6, 9						#move the number 4 for comparison

	move $a0, $t4  				#print out the number 1
	addiu	$sp, $sp, -4
	jal PrintCharDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 				#print

	li $a0, 32					#print out a space. $v0, 11 from previous
	addiu	$sp, $sp, -4
	jal PrintCharDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 				#call function
	addiu $t4, $t4, 1				#add 1 to $t4

PrintLoop:
	bne $t6, $t5, PrintNum				#print if not at end of column
	li $a0, 10					#
	jal PrintCharDriver				#
	move $a0, $t4  				#print out the next number
	jal PrintCharDriver				#print

	li $a0, 32					#print out a space.
	addiu	$sp, $sp, -4
	jal PrintCharDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 				#print
	li $t5, 1						#
	addiu $t4, $t4, 1				#increase by one each iteration
	
PrintNum:

	beq $s0, 1, cheatCodeOn
	lb $a0, 0($t0)					#load
	beq $a0, 99, replaceDash
	beq $a0, 98, replaceDash
	beq $a0, 115, replaceDash
	beq $a0, 109, replaceDash
	b cheatCodeOn
	replaceDash:
	addiu $t5, $t5, 1

	li 	$a0, 45
	addiu	$sp, $sp, -4
	jal PrintCharDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 
	b nextFormat
	
	cheatCodeOn:
	lb $a0, 0($t0)					#load
	addiu $t5, $t5, 1				#
	addiu	$sp, $sp, -4
	jal PrintCharDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 
	
	nextFormat:				
	li 	$a0, 32					#load space char
	addiu	$sp, $sp, -4
	jal PrintCharDriver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4 				#print	

	addi 	$t0, $t0, 1 				#increase count by one
	blt 	$t0, $t1, PrintLoop			#know end of array is when $t0 is at array + 64
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr $ra						#jump back to return address


# NEW FUNCTION						#
#----------------------------------------------------------------------	#
# This function takes the address of a string and      		#
# the length of the string and prints it out using        		#
# the display driver                                                         	#
# $a0 = address of string                                             	#
# $v0 = length of address			           		#
# uses $a1 for address of driver                                 	#
# uses $t2 for byte to print                                          	#
# uses $t1 for 	checking if driver is ready                   		# 
#--------------------------------------------------------------------	#

PrintDriver:
#save registers that we are going to use
	addiu	$sp, $sp, -12
	sw	$a1, 0($sp)
	sw	$t1, 4($sp)
	sw	$t2, 8($sp)
	li	$a1, 0xffff0000
PDLoop:
	lb	$t2, 0($a0)	
	PDReady:						#Poll the Display		
		lw	$t1, 8($a1)
		andi	$t1, $t1, 1
		beqz	$t1, PDReady
		sw	$t2, 12($a1)			
	addi	$a0, $a0, 1	
	addi	$v0, $v0 , -1
	bne	$v0, $0,  PDLoop

	lw	$a1, 0($sp)
	lw	$t1, 4($sp)
	lw	$t2, 8($sp)
	addiu	$sp, $sp, 12
	jr 	$ra
# NEW FUNCTION						#
#----------------------------------------------------------------------	#
# This function takes the address of a string and      		#
# the length of the string and prints it out using        		#
# the display driver                                                         	#
# $a0 = character to print                                             	#
# uses $t1 for address of driver                                   	#
# Uses $a1 for address of driver                                  	#
#-------------------------------------------------------------------- 	#
PrintCharDriver:
	addiu	$sp, $sp, -8
	sw	$a1, 0($sp)
	sw	$t1, 4($sp)

	li	$a1, 0xffff0000
	PCDReady:						#Poll the display	
		lw	$t1, 8($a1)
		andi	$t1, $t1, 1
		beqz	$t1, PCDReady
		sw	$a0, 12($a1)
	
	lw	$t1, 4($sp)
	lw	$a1, 0($sp)
	addiu	$sp, $sp, 8
	jr 	$ra

# 		NEW FUNCTION				#
#----------------------------------------------------------------------	#
# This function reads from the keyboard	          		#
# Only needs the following:                                                   	#
# $a0 = address of input                        			#
# uses $t1 for address of driver                                    	#
# Uses $a1 for address of driver                                   	#
# -----------							#
# Functions:							#
# We first clear the input data variable	 of any left over	#
# input, then							#
# We get 8 characters, and store them in the address	#
# of the input variable						#
# We stop input if we find an enter value in the input		#
#								#
#--------------------------------------------------------------------  	#
GetKeyDriver:
	addiu	$sp, $sp, -24			# allocate space on the stack
	sw	$a0, 0($sp)			# save register we will be using
	sw	$a1, 4($sp)			 
	sw	$t1, 8($sp)
	sw	$t2, 12($sp)
	sw	$t3, 16($sp)
	sw	$a2, 20($sp)
	li	$a1, 0xffff0000
	li	$t2, 8		
	li	$t3, 0x0a					
clearinputloop:
	sb	$0, 0($a0)
	addi	$a0, $a0, 1
	addi	$t2, $t2, -1
	bne	$t2, $0, clearinputloop

	li	$t2, 8
	la	$a0, input
getkloop:							# loop to get input 8 times.

	KReady:						#Poll the keyboard		
		lw	$t1, 0($a1)				#
		andi	$t1, $t1, 1				#
		beqz	$t1, KReady				#
		lb	$a2, 4($a1)				# use $a2 to get word 
	
	sb 	$a2, 0($a0) 					#
	
	beq	$a2, $t3, getkreturn				#
	addi	$t2, $t2, -1
	addi	$a0, $a0, 1					#
	bne	$t2, $0, getkloop				#
	
getkreturn:							#
	lw	$a0, 0($sp)					# save register we will be using
	lw	$a1, 4($sp)					# 
	lw	$t1, 8($sp)
	lw	$t2, 12($sp)
	lw	$t3, 16($sp)
	lw	$a2, 20($sp)
	addiu	$sp, $sp, 24					#
	jr 	$ra						#

# 		NEW FUNCTION				#
#----------------------------------------------------------------------	#
# This function generates random integers	          		#
# with the use of the time syscall				#
# Only needs the following:                                                   	#
# $a1 = upper bound of number 
# $a0 = 0 - upper bound
#								#
#--------------------------------------------------------------------  	#
GenerateRandom:
	#don't save a1 and v0
	addiu	$sp, $sp, -4
	sw	$a2, 0($sp)
	move 	$a2, $a1					# save $a1( will get overwritten)
	li	$v0, 30						# get the low 32 bits of time in $a0
	syscall							# used to get the time

	div	$a0, $a2					# divide by upper bound			
	mfhi	$a0						# get remainder from hi register
	lw	$a2, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

__checkIfSunk:
	#First check cruiser
	la	$t0, cruiserMark
	lb	$t1, 6($t0)					# get parity bit - tells us if msg printed already
	andi	$t1, $t1, 1					# and parity bit with a one
	bgtz	$t1, checkifsunkbattle				# message already printed, skip
	li	$t2, 5 						# check 5 chars
	cruisersunkloop: 
		lb	$t1, 0($t0)				# load first char
		beq	$t1, 0, checkifsunkbattle		# if char is 'c' then skip
		addi	$t0, $t0, 1
		addi	$t2, $t2, -1
		bne	$t2, $0, cruisersunkloop
	la	$t0, cruiserMark
	li	$a0, 1				#load parity bit
	sb	$a0, 6($t0)			# write parity bit		
	la	$a0, cruiserSunk		#print message you've sunk my ship
	li	$v0, 30
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	PrintDriver	
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	b checksunkend
#----------------------Check if battleship is sunk---------------------------#
checkifsunkbattle:
	#Now check battle
	la	$t0, battleMark
	lb	$t1, 5($t0)					# get parity bit - tells us if msg printed already
	andi	$t1, $t1, 1					# and parity bit with a one
	bgtz	$t1, checkifsunkmine				# message already printed, skip
	li	$t2, 4 						# check 4 chars
	battlesunkloop: 
		lb	$t1, 0($t0)				# load first char
		beq	$t1, 0, checkifsunkmine		# if char is '0' if so, then skip
		addi	$t0, $t0, 1
		addi	$t2, $t2, -1
		bne	$t2, $0, battlesunkloop
	la	$t0, battleMark
	li	$a0, 1				#load parity bit
	sb	$a0, 5($t0)			# write parity bit
		
	la	$a0, battleSunk		#print message you've sunk my ship
	li	$v0, 29
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	PrintDriver	
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	b checksunkend
#----------------------Check if minesweeper is sunk---------------------------#
checkifsunkmine:
	#Now check minesweeper
	la	$t0, mineMark
	lb	$t1, 3($t0)					# get parity bit - tells us if msg printed already
	andi	$t1, $t1, 1					# and parity bit with a one
	bgtz	$t1, checksunkend				# message already printed, skip
	li	$t2, 2 						# check 2 chars
	minesunkloop: 
		lb	$t1, 0($t0)				# load first char
		beq	$t1, 0, checksunkend			# if char is '0' if so, then skip
		addi	$t0, $t0, 1
		addi	$t2, $t2, -1
		bne	$t2, $0, minesunkloop
	la	$t0, mineMark			#reload base address
	li	$a0, 1				#load parity bit
	sb	$a0, 3($t0)			# write parity bit
		
	la	$a0, mineSunk			#print message you've sunk my ship
	li	$v0, 31
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	PrintDriver	
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
checksunkend:
	jr $ra
end:
	li $v0, 10					
	syscall
