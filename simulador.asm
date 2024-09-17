.data
    ##### DADOS DOS ARQUIVOS DE LEITURA #####
    nomeArquivo: .asciiz "bin.bin"
    bufferArquivo: .space 1024
    resultado: .word 0		# Variável para armazenar o resultado do fatorial;

    data: .space 1024
    nomeArquivoData: .asciiz "dat.dat"

    ##### VETORES #####
    stack: .space 1024		# Definindo a pilha virtual;
    registers: .space 128		# Definindo a memoria virtual para os 32 registradores;
     
.text
.globl main
main:
	la $t0, stack
    	la $t1, registers
    	addi $t1, $t1, 116
    	sw $t0, 0($t1)			# Guarda o endereço da pilha no índice 29 do array registers;
    
    	la $a0, nomeArquivoData
    	jal abrirArquivo
    	
    	move $s0, $v0			# Salva o descritor do arquivo data em $s0;
	
	lerArquivoData:
        		li $v0, 14				# Código da syscall para ler o arquivo;
		move $a0, $s0		# Descritor do arquivo;
		la $a1, data		# Buffer para armazenar os bytes lidos;
		li $a2, 512               
		syscall

        la $a0, nomeArquivo		
        jal abrirArquivo		
        
        move $s0, $v0				# Salva o descritor do arquivo bin em $s0;
	
	lerArquivo:
        		li $v0, 14			# Código da syscall para ler o arquivo;		
		move $a0, $s0		# Descritor do arquivo;
		la $a1, bufferArquivo		# Buffer para armazenar os bytes lidos;
		li $a2, 1024               
		syscall

		li $s6, 0
		move $s5, $v0		# Salva o número de bytes lidos;
		
pegaUmaInstrucao:
	la $s7, bufferArquivo			# Carrega o endere?o do buffer no registrador $s7 tornando-o o Program Counter do arquivo;
	
	loopPegaUmaInstrucao:	
		bge $s6, $s5, encerraPrograma

        		jal pegaTipoInstrucao

	       	addi $s7, $s7, 4		# PC + 4;
	        	addi $s6, $s6, 2		# Incrementa o contador de bytes processados;

        		j loopPegaUmaInstrucao

encerraPrograma:
	li $v0, 10			# Código da syscall para sair do programa;
	syscall

abrirArquivo:
        li $v0, 13			# Código da syscall para abrir arquivo;
        li $a1, 0			# Modo de abertura (0 para leitura);
        syscall
        jr $ra

pegaTipoInstrucao:
	lw $t0, 0($s7)			# Carrega o valor contido no endereço de PC ($s7) em $t0;
        li $t1, 0xFC000000		# Máscara para isolar os primeiros 6 bits do opcode e carregar em $t1;
        and $t0, $t0, $t1		# Isola os primeiros 6 bits do opcode e armazena em $t0;
        srl $t0, $t0, 26		# Desloca para a direita para obter o valor do opcode;
        
        addi $t8, $t0, 0
        # Verifica o tipo da instrução com base no opcode;
        beq $t0, 0, tipoR          # Se opcode == 0, instrução do tipo R;
        beq $t0, 2, tipoJ          # Se opcode == 2, instrução do tipo J;
        beq $t0, 3, tipoJ          # Se opcode == 3, instrução do tipo J;
        beq $t0, 28, tipoR         # Se opcode == 2, instrução do tipo J;
        j tipoI                    # Caso contrário, instrução do tipo I;
       
########## RS -> $ t5 ################### 
########## RT -> $ t6 ################### 
########## RD/IMEDIATO -> $ t7 ##########
########## SHAM -> $ t8 ################# 
########## FUNCT -> $ t9 ################ 

tipoR:
	subi $sp, $sp, 4
	sw $ra, 0($sp)

	jal pegaRS		# Pega qual registrador é o RS na instrução do arquivo em binário e armazena em $t5;
	jal pegaRT		# Pega qual registrador é o RT na instrução do arquivo em binário e armazena em $t6;
	jal pegaRD		# Pega qual registrador é o RD na instrução do arquivo em binário e armazena em $t7;
	jal pegaSHAM		# Pega qual é o valor de SHAM na instrução do arquivo em binário e armazena em $t8;
	jal pegaFUNCT		# Pega qual é o valor do FUNCT na instrução do arquivo em binário e armazena em $t9;

	move $t4, $t5
	jal pegaRegistradorVirtual	# Pega o valor guardado em RS, move-o para $t4, calcula o endereço do registrador do RS na
	move $t5, $t4			# memória virtual, e retorna-o em $t4;

	move $t4, $t6
	jal pegaRegistradorVirtual	# Pega o valor guardado em RT, move-o para $t4, calcula o endereço do registrador do RT na
	move $t6, $t4			# memória virtual, e retorna-o em $t4;

	# Compara o valor de funct, armazenado em $t9, com $s4 para descobrir a operação a ser realizada;
	addi $s4, $zero, 2
	beq  $s4,$t9, processaMUL
	addi $s4, $zero, 8
	beq  $s4,$t9, processaJR
	addi $s4, $zero, 12
	beq $s4, $t9, processaSYSCALL
	addi $s4, $zero, 32
	beq  $s4,$t9, processaADD
	addi $s4, $zero, 33
	beq $s4, $t9, processaADDU

	retornaTipoR:
        
        lw $ra, 0($sp)
	addi $sp, $sp, 4
   	jr $ra
        
tipoJ:
	subi $sp,$sp,4
	sw $ra, 0($sp)
        
        jal pegaJump		# Calcula o endereço de salto do jump;
        
        # Verifica qual operação do tipo J será realizada;
        addi $s4, $zero, 2
	beq  $t8, $s4, processaJUMP
        addi $s4, $zero, 3
	beq  $t8, $s4, processaJAL
        
        retornaTipoJ:
        
      	lw $ra, 0($sp)
	addi $sp, $sp, 4
   	jr $ra
   	
tipoI:
	subi $sp,$sp,4
	sw $ra, 0($sp)
	
	jal pegaRS			# Pega qual registrador é o RS na instrução do arquivo em binário e armazena em $t5;
	jal pegaRT			# Pega qual registrador é o RT na instrução do arquivo em binário e armazena em $t6;
	jal pegaImediato		# Pega qual registrador é o IMEDIATO na instrução do arquivo em binário e armazena em $t7;
	
	move $t4, $t5
	jal pegaRegistradorVirtual	# Pega o valor guardado em RS, move-o para $t4, calcula o endereço do registrador do RS na
	move $t5, $t4			# memória virtual, e retorna-o em $t4;
	
	addi $t9, $zero, 35	     	#Coloquei aqui pq eu preciso do numero do RT nao de seu valor	
	beq  $t8, $t9, processaLW
	
	move $t4, $t6
	jal pegaRegistradorVirtual	# Pega o valor guardado em RS, move-o para $t4, calcula o endereço do registrador do RS na
	move $t6, $t4			# memória virtual, e retorna-o em $t4;
	
	# Compara $s4 com o valor do OPCODE para selecionar qual operação deve ser realizada;
	addi $s4, $zero, 5
	beq  $t8,$s4, processaBNE
	addi $s4, $zero, 8
	beq  $t8,$s4, processaADDI
	addi $s4, $zero, 9
	beq  $t8,$s4, processaADDIU
	addi $s4, $zero, 13
	beq $t8, $s4, processaORI
	addi $s4, $zero, 15
	beq $t8, $s4, processaLUI
	addi $s4, $zero, 43
	beq  $t8, $s4, processaSW
	
	retornaTipoI:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
   	jr $ra
   	
pegaRS:
   	lw $t0, 0($s7)		# Carrega o valor contido no endereço de PC ($s7) em $t0;
        li  $t1, 0x03E00000		# Máscara para isolar os 5 bits do RS, carrega em $t1;
        and $t0, $t0, $t1		# Isola os bits de RS e armazena em $t0;
        srl $t0, $t0, 21		# Shifta 21 bits à direita, para deixar os 5 bits de RS nos bits menos significativos de $t0;
        move $t5, $t0			# Coloca o valor de RS em $t5;
        
        jr $ra

pegaRT:
   	lw $t0, 0($s7)		# Carrega o valor contido no endereço de PC ($s7) em $t0;
   	li  $t1, 0x001F0000        	# Máscara para isolar os 5 bits do RT, carrega em $t1;
   	and $t0, $t0, $t1          	# Isola os bits de RT e armazena em $t0;
        srl $t0, $t0, 16 	   	# Shifta 16 bits à direita, para deixar os 5 bits de RS nos bits menos significativos de $t0;
        move $t6, $t0			# Coloca o valor de RT em $t6;
        
        jr $ra 
   
pegaRD:
   	lw $t0, 0($s7)			# Carrega o valor contido no endereço de PC ($s7) em $t0;
   	li  $t1, 0x0000F800        	# Máscara para isolar os 5 bits do RD, carrega em $t1;
   	and $t0, $t0, $t1         	# Isola os bits de RD e armazena em $t0;
        srl $t0, $t0, 11 	   	# Shifta 11 bits à direita, para deixar os 5 bits de RD nos bits menos significativos de $t0;
        move $t7, $t0			# Coloca o valor de RD em $t7;
        
        jr $ra
      
pegaSHAM:
	lw $t0, 0($s7)  		# Carrega o valor contido no endereço de PC ($s7) em $t0;
	li $t1, 0x000007C0		# Máscara para isolar os 5 bits de SHAM, carrega em $t1;
	and $t0, $t0, $t1		# Isola os bits de SHAM e armazena em $t0;
        srl $t0, $t0, 6	   	# Shifta 6 bits à direita, para deixar os 5 bits de RD nos bits menos significativos de $t0;
        move $t8, $t0			# Coloca o valor de SHAM em $t8;
        
        jr $ra   
      
pegaFUNCT:     
        lw $t0, 0($s7)		# Carrega o valor contido no endereço de PC ($s7) em $t0;
        li  $t1, 0x0000003F        	# Máscara para isolar os 6 bits do FUNCT, carrega em $t1;
        and $t0, $t0, $t1          	# Isola os bits de FUNCT e armazena em $t0;
        move $t9, $t0			# Coloca o valor de FUNCT em $t9;
        
        jr $ra

pegaImediato:
        lw $t0, 0($s7)			# Carrega o valor contido no endereço de PC ($s7) em $t0;
        li  $t1, 0x0000FFFF		# Máscara para isolar os 16 bits do IMEDIATO, carrega em $t1;
        li  $t3  0x0000000F		# Isola os 4 bits menos significativos do IMEDIATO, carrega em $t3
        and $t0, $t0, $t1          	# Armazena os 16 bits do imediato em $t0;
   	
        srl $t2,$t0, 12			# Coloca em $t2 os 4 bits mais significativos do IMEDIATO;
        beq $t2, $t3, extenderSinal	# Se os 4 bits mais significativos forem iguais a "1111", salta para extenderSinal;
   	
        move $t7, $t0			# Coloca o valor do IMEDIATO em $t7;
        jr $ra      

pegaJump:
	lw $t0, 0($s7)			# Carrega o valor contido no endereço de PC ($s7) em $t0;
        li  $t1, 0x03FFFFFF       	# Máscara para isolar os 26 bits do endereço de salto, carrega em $t1;
        and $t0, $t0, $t1         	# Isola os bits do endereço de salto e armazena em $t0;
        
        sll $t0, $t0, 2           	# Restaura os 2 bits menos significativos para formar um endereço de 32 bits;
	move $t7, $t0			# Coloca o endereço de salto em $t7;
        jr $ra                    

pegaRegistradorVirtual:
	mul $t4, $t4, 4			# Verifica o índice correto do registrador;			
	la $t3, registers		# Carrega o endereço dos registradores virtuais;
	
	add $t3, $t4, $t3		# Calcula o endereço do registrador virtual solicitado;
	lw $t4, 0($t3)			# Carrega o endereço em $t4;
	
	jr $ra
 
processaBNE:
	bne $t5, $t6, aceitouBNE	
	j retornaTipoI
	
aceitouBNE:
	mul   $t7, $t7, 4		# Calcula o deslocamento para o endereço de salto que o branch deve dar;
	add $s7, $s7, $t7		# Soma o deslocamento ao PC, para pular para a instrução correta;
	j retornaTipoI	 
	            
processaADDIU:
	add $t6,$t5,$t7			# Soma RS com o IMEDIATO, salvando no RT;
	sw $t6, 0($t3)			# Guarda o valor da soma no endereço correto na memória virtual;
	j retornaTipoI
	
processaADDI:
	add $t5,$t6,$t7			# Soma RS com o IMEDIATO, salvando no RT;
	sw $t5, 0($t3)			# Guarda o valor da soma no endereço correto na memória virtual;
	j retornaTipoI

processaLW:
	add $t7,$t5,$t7			# Soma o RS com o IMEDIATO para obter o endereço a ser  carregado;
	lw $t8, 0($t7)			# Carrega o valor do endereço em $t8;
	
	mul $t6, $t6, 4     		# Verifica o índice correto do registrador RT;		
	la $t3, registers  		# Carrega o endereço dos registradores virtuais;
	add $t6, $t3, $t6   		# Calcula o endereço do registrador virtual correspondente ao RT;
	sw $t8, 0($t6)			# Salva o valor carregado em $t8 no endereço correto na memória virtual;
	
	j retornaTipoI
	
processaSW:
	add $t7,$t5,$t7			# Soma o RS com o IMEDIATO para obter o endereço a ser  carregado;
	sw $t6, 0($t7)			# Salva o valor de $t6 no endereço correto na memória virtual;
	
	j retornaTipoI
	
processaLUI:
	sll $t6, $t7, 16		# Shifta 16 bits à esquerda o IMEDIATO, salvando o valor nos 16 bits mais significativos de $t6;
	sw $t6, 0($t3)		# Salva o valor de $t6 no endereço correto na memória virtual;
	
	j retornaTipoI

processaORI:
	add $t6, $t5, $t7		# Soma os 16 bits menos significativos, contidos no IMEDIATO, com os 16 mais significativos calculados anteriormente em LUI;
	li $t7, 0x040C		# Adiciona o valor imediato para deslocar o endereço até a região de memória onde está a Data virtual;
	add $t6, $t6, $t7		# Soma o endereço correto com $t6;
	sw $t6, 0($t3)		# Retorna o registrador RT para a memória virtual;
	
	j retornaTipoI

processaADD:
	mul $t7, $t7, 4		# Verifica o índice correto do registrador RD;
	la $t3, registers		# Carrega o endereço dos registradores virtuais;
	add $t7, $t3, $t7		# Calcula o endereço do registrador virtual correspondente ao RD;

	add $t5, $t5, $t6		# Faz a soma dos valores;
	sw $t5, 0($t7)		# Retorna o registrador RD para a memória virtual;
	
	j retornaTipoR	
	
processaMUL:
	mul $t7, $t7, 4		# Verifica o índice correto do registrador RD;
	la $t3, registers		# Carrega o endereço dos registradores virtuais;
	add $t7, $t3, $t7		# Calcula o endereço do registrador virtual correspondente ao RD;

	mul $t5, $t5, $t6		# Faz a soma dos valores;
	sw $t5, 0($t7)		# Retorna o registrador RD para a memória virtual;
	j retornaTipoR	
	
processaJR:
	move $s7, $t5
	j retornaTipoR	

processaSYSCALL:
	li $t4, 2			#
    	mul $t4, $t4, 4		#
    	la $t3, registers		# Carrega o valor contido no registrador virtual $v0  para o $v0 real;
    	add $t4, $t4, $t3		#
    	lw $v0, 0($t4)		#

    	li $t4, 4			#
    	mul $t4, $t4, 4		#
    	la $t3, registers		# Carrega o valor contido no registrador virtual $a0  para o $a0 real;
    	add $t4, $t4, $t3		#
   	lw $a0, 0($t4)		#

    	syscall
    	j retornaTipoR
    	
processaADDU:
	mul $t7, $t7, 4		# Verifica o índice correto do registrador RD;
	la $t3, registers		# Carrega o endereço dos registradores virtuais;
	add $t7, $t3, $t7		# Calcula o endereço do registrador virtual correspondente ao RD;

	addu $t5, $t5, $t6		# Faz a soma dos valores;
	sw $t5, 0($t7)		# Retorna o registrador RD para a memória virtual;
	
	j retornaTipoR	

processaJUMP:
	la $t6, bufferArquivo		#
	li $t1, 0x00400000		#
	sub $t7, $t7, $t1		# Calcula o endereço de salto do jump;
	add $s7, $t7, $t6		#
	subi $s7, $s7, 4		#
	
	j retornaTipoJ	
			
processaJAL:
	la $t6,registers
	addi $t6,$t6, 124		# Calcula o endereço do $ra virtual;
	sw $s7, 0($t6)		# Salva o PC do arquivo no $ra;
	
	#tenho que somar o valor do jump no pc
	la $t6, bufferArquivo
	li $t1, 0x00400000
	sub $t7, $t7, $t1
	add $s7, $t7, $t6
	subi $s7, $s7, 4
	
	j retornaTipoJ
	
extenderSinal:
	li $t1, 0xFFFF0000
	or $t7, $t0, $1
	
	jr $ra
	
fim:
        sw $v0, resultado          # Salva o resultado do processamento em resultado
        jr $ra                     # Retorna ao procedimento chamador


