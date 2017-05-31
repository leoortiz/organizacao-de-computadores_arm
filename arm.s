	.global _start      @ ligador necessita deste rótulo

@------------------------------------CONSTANTES E CONTROLES---------------------------------------------
	@ Endereco do teclado
	.set kdb_data,   	0x00090000	@ Endereco teclado
	.set kdb_status, 	0x00090001	@ Endereco status teclado
	.equ kdb_ready,		1			@ Flag teclado

	@ Constantes de tamanho de chave e da mensagem
	.equ max_chave,		16			@ Define o tamanho maximo para chave de 15 caracteres 1 espaco para o \n
	.equ max_msg,		255			@ Define o tamanho maximo para mensagem 254 caracteres 1 espaco para o \n

_start:

@------------------------------------INICIO CRIPTOGRAFIA---------------------------------------
	@Escreve a mensagem inicial pedindo para digitar a chave
	mov     r0, #1      			@ Comando de saida
	ldr     r1, =msg    			@ Endereco da mensagem
	ldr     r2, =len    			@ Tamanho mensagem a ser escrita
	mov     r7, #4
	svc     0x055

	@ Leitura inicial da chave *
leitura_inicial:
	ldr		r3, =kdb_status
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #kdb_ready			@ Compara R4 com 0x1
	bne    	leitura_inicial			@ Fica no loop se diferentes
	ldr		r3, =kdb_data
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado

	@ Comparar se precionou '*' para iniciar a chave
	cmp		r4, #10					@ Comprar se foi digitado o *
	bne		leitura_inicial			@ Se diferente de * volta para leitura_inicial
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	#0x55

@------------------------------------LEITURA CHAVE -------------------------------------------
	@ Apos digitado * leitura da chave

	mov		r5, #0					@ Controle do deslocamento da chave
leitura_kdb_chave:
	ldr		r3, =kdb_status
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #kdb_ready			@ Compara R4 com 0x1
	bne    	leitura_kdb_chave		@ Fica no loop se diferentes
	ldr		r3, =kdb_data
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado
	cmp		r4, #10					@ Compara se foi outro *
	bne		escrever				@ Se diferente de * escreve na tela e guarda
	b		leitura_kdb_chave

	@ Exibe um asterisco na tela
escrever:
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	#0x55

	@ Compara se precionou '#' para encerar a chave
	cmp		r4, #11					@ Compara se foi '#'
	bne	guardar_chave			@ Se for diferente salva e le outro valor

	#cmpge	r5, #10					@ Compara se r5 é maior que 10
	#bne	leitura_kdb_chave		@ Se menor que 10 volta para leitura da chave

	b 		leitura_mensagem		@ Se nao vai para leitura_mensagem

@------------------------------------ARMAZENANDO A CHAVE-----------------------------------------
	@ Guarda a chave na memoria
guardar_chave:
	ldr 	r10, =chave				@ coloca endereco em R10
	strb	r4, [r10, r5]			@ Armazena o valor
	add 	r5, r5, #1				@ Incrementa Deslocamento
	mov 	r4, #0					@ Limpa registrador
	b		leitura_kdb_chave		@ Retorna a leitura da chave

@------------------------------------LEITURA MENSAGEM---------------------------------------------
leitura_mensagem:

	@Escreve a mensagem pedindo para digitar a mensagem
	mov     r0, #1      			@ Comando de saida
	ldr     r1, =msg2    			@ Endereco da mensagem
	ldr     r2, =len2    			@ Tamanho mensagem a ser escrita
	mov     r7, #4
	svc     0x055

	@Faz a leitura da mensagem digitada pelo usuario
	mov     r0, #0      			@ Comando de entrada
	ldr     r1, =mensagem    		@ Endereco da mensagem
	ldr     r2, =max_msg 			@ Tamanho maxio a ser lido
	mov     r7, #3
	svc     #0x55

@------------------------------------CRIPTOGRAFIA-------------------------------------------------
	mov		r0, #0					@ Registrador vai ser usado no desolocamento da mensagem e mensagem criptografada
	mov		r1, #0					@ Registrador vai ser usado no desolocamento da chave
	ldr		r2, =mensagem			@ Define o endereco da mensagem em r2
	ldr		r3, =chave				@ Define o endereco da chave em r3
	ldr		r4, =msg_cripto			@ Define o endereco da mensagem criptografada em r4

criptografia:
	@ Inicio do processo de criptografia
	ldrb	r5, [r2, r0]			@ Em r5 define o inicio da mensagem
	cmp		r5, #0x0A				@ Se for o enter (0A em ascii) encera a criptografia
	beq		escreve_cripto			@ E vai para escreve_cripto que apresenta a mensagem criptografada
	ldrb	r6, [r3, r1]			@ Em r6 define o inicio da chave
	cmp		r6, #0					@ Se for nulo volta ao inico da chave
	moveq	r1, #0					@ Mudando o deslocamento para 0
	add		r5, r5, r6				@ Adiciona na possicao da mensagem o valor da chave na possicao do deslocamento
	strb	r5, [r4, r0]			@ Escreve na memoria o resultado da soma
	add		r0, r0, #1				@ Desloca um no controle das mensagem
	add		r1, r1, #1				@ Desloca um no controle da chave
	b		criptografia			@ retorna ao inico da criptografia

escreve_cripto:
	mov		r5, #0x0A				@ Coloca o enter em ascii no registrador 5
	strb	r5, [r4, r0]			@ para q no final da mensagem fique enter para para na descriptografia

	@Escreve a mensagem criptografada
	mov     r0, #1   				@ Comando de saida
	ldr     r1, =msg_cripto			@ Endereco da mensagem
	ldr     r2, =max_msg			@ Tamanho da mensagem
	mov     r7, #4
	svc     #0x55

@------------------------------------INICIO DESCRIPTOGRAFIA-----------------------------------------

	@Escreve a mensagem pedindo a chave de descriptografia
	mov     r0, #1      			@ Comando de saida
	ldr     r1, =msg3    			@ Endereco da mensagem
	ldr     r2, =len3	 			@ Tamanho da mensagem
	mov     r7, #4
	svc     #0x55

	@ Leitura inicial da chave *
leitura_desc:
	ldr		r3, =kdb_status
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #kdb_ready			@ Compara R4 com 0x1
	bne    	leitura_desc			@ Fica no loop se diferentes
	ldr		r3, =kdb_data
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado

	@ Comparar se precionou '*' para iniciar a chave
	cmp		r4, #10					@ Comprar se foi digitado o *
	bne		leitura_desc			@ Se diferente de * volta para leitura
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	#0x55

@------------------------------------LEITURA CHAVE DESCRIPTOGRAFIA---------------------------------
	@ Apos digitado * leitura da chave

	mov		r5, #0					@ Controle do deslocamento da chave de descriptografia
leitura_kdb_desc:
	ldr		r3, =kdb_status
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #kdb_ready			@ Compara R4 com 0x1
	bne    	leitura_kdb_desc		@ Fica no loop se diferentes
	ldr		r3, =kdb_data
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado
	cmp		r4, #10					@ Compara se foi outro *
	bne		escrever2				@ Se diferente de * escreve na tela e guarda
	b		leitura_kdb_desc

	@ Exibe um asterisco na tela
escrever2:
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	#0x55

	@ Compara se precionou '#' para encerar a chave
	cmp		r4, #11					@ Compara se foi '#'
	bne		guardar_desc			@ Se for diferente salva e le outro valor
	b 		descriptografar			@ Se nao vai para descriptografia

@------------------------------------ARMAZENANDO A CHAVE DESCRIPTOGRAFIA-------------------------
@ Guarda a chave na memoria
guardar_desc:

	ldr 	r10, =chave_desc				@ coloca endereco em R10
	strb	r4, [r10, r5]			@ Armazena o valor
	add 	r5, r5, #1				@ Deslocamento
	mov 	r4, #0					@ Limpa registrador
	b		leitura_kdb_desc		@ Retorna a leitura da chave

@------------------------------------DESCRIPTOGRAFIA-----------------------------------------------
descriptografar:
	mov		r0, #0					@ Registrador controla desolocamento das mensagens
	mov		r1, #0					@ Registrador controla desolocamento da chave
	ldr		r2, =msg_cripto			@ Define o endereco da mensagem criptografadaem r2
	ldr		r3, =chave_desc			@ Define o endereco da chave de descriptografia em r3
	ldr		r4, =msg_desc			@ Define o endereco da mensagem descriptografada em r4

descriptografia:
	@ Inicio do processo de descriptografia
	ldrb	r5, [r2, r0]			@ Em r5 define o inicio da mensagem criptografada
	cmp		r5, #0x0A				@ Se for o enter (0A em ascii) encera a descriptografia
	beq		escreve_desc			@ E vai para escreve_desc que apresenta a mensagem descriptografada
	ldrb	r6, [r3, r1]			@ Em r6 define o inicio da chave descriptografia
	cmp		r6, #0					@ Se for nulo volta ao inico da chave
	moveq	r1, #0					@ Mudando o deslocamento para 0
	sub		r5, r5, r6				@ Subtrai na possicao da mensagem o valor da chave na possicao do deslocamento
	strb	r5, [r4, r0]			@ Escreve na memoria o resultado da subtracao
	add		r0, r0, #1				@ Desloca um no controle das mensagem
	add		r1, r1, #1				@ Desloca um no controle da chave
	b		descriptografia			@ retorna ao inico da descriptografia

escreve_desc:

	@Escreve a mensagem criptografada
	mov     r0, #1   				@ Comando de saida
	ldr     r1, =msg_desc			@ Endereco da mensagem
	ldr     r2, =max_msg			@ Tamanho da mensagem
	mov     r7, #4
	svc     #0x55

final:
	mov     r0, #0
	mov     r7, #1
	svc     #0x55

@------------------------------------VARIAVEIS E MENSAGENS-----------------------------------------
@onde serao armazenados os caracteres lidos
chave:
	.skip max_chave			@ Chave criptografia
chave_desc:
	.skip max_chave			@ Chave descriptografia
mensagem:
	.skip max_msg			@ Mensagem digitada
msg_cripto:
	.skip max_msg			@ Mensagem criptografada
msg_desc:
	.skip max_msg			@ Mensagem descriptografada

@Mensagem que serao apresentadas ao usuario
msg:		.ascii   "Digite a chave para criar a criptografia \n-no teclado numerico\n"
len = . - msg
msg2:		.ascii   "\nDigite a mensagem a ser criptografada\n\n"
len2 = . - msg2
msg3:		.ascii   "\nDigite a chave para descriptografar \n-no teclado numerico\n"
len3 = . - msg3
