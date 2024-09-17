# Simulador Assembly MIPS

Este código em assembly MIPS tem como objetivo simular um programa que lê instruções de dois arquivos binários (`bin.bin` e `dat.dat`), processa essas instruções e executa operações com base no formato de instrução MIPS.

## Resumo da Funcionalidade

### Seção de Dados:

- **`nomeArquivo`**: Armazena o nome do primeiro arquivo binário (`bin.bin`).
- **`bufferArquivo`**: Um buffer de 1024 bytes para leitura de `bin.bin`.
- **`resultado`**: Armazena o resultado de um cálculo de fatorial (embora não seja utilizado diretamente aqui).
- **`data`**: Um buffer de 1024 bytes para leitura de `dat.dat`.
- **`stack`**: Um espaço virtual de pilha de 1024 bytes.
- **`registers`**: Um espaço de memória virtual de 128 bytes para simular os 32 registradores MIPS.

### Programa Principal:

1. Inicializa o ponteiro da pilha e armazena o endereço da pilha no registrador `$t1`.
2. Abre os dois arquivos (`dat.dat` e `bin.bin`) e salva os descritores dos arquivos.
3. Lê até 512 bytes de `dat.dat` no buffer `data`.
4. Lê até 1024 bytes de `bin.bin` no buffer `bufferArquivo`.

### Processamento de Instruções:

- O loop `loopPegaUmaInstrucao` simula a captura de instruções de `bin.bin` e determina o tipo de instrução (R, I ou J) com base no opcode.
- A função `pegaTipoInstrucao` isola e identifica o opcode aplicando uma máscara de bits e deslocando a palavra da instrução.
- Dependendo do opcode, o controle é desviado para o manipulador correspondente de instruções do tipo R, I ou J (`tipoR`, `tipoI`, `tipoJ`).

### Instruções Tipo R:

- Para instruções do tipo R, o código extrai os campos: **RS**, **RT**, **RD**, **SHAM** e **FUNCT**.
- Processa instruções específicas do tipo R, como `MUL`, `JR`, `SYSCALL`, `ADD` e `ADDU`.

### Instruções Tipo J:

- Manipula as operações de salto e link (`J`, `JAL`).

### Instruções Tipo I:

- Para instruções do tipo I, processa: `BNE`, `ADDI`, `ADDIU`, `ORI`, `LUI`, `SW` e `LW`.

### Manipulação de Registradores:

- Para cada instrução, os valores dos registradores relevantes (**RS**, **RT**, **RD**) são buscados na memória de registradores virtual usando a função auxiliar `pegaRegistradorVirtual`.

## Funções Auxiliares:

- **`pegaRS`**, **`pegaRT`**, **`pegaRD`**: Extraem campos de registradores específicos da instrução.
- **`pegaSHAM`**: Extrai a quantidade de deslocamento.
- **`pegaFUNCT`**: Extrai o código de função para instruções do tipo R.

## Próximos Passos:

Se você planeja expandir este código, assegure-se de que todas as operações (como operações da ALU, saltos, acessos à memória) estejam implementadas corretamente. Considere também o tratamento de exceções ou erros, como problemas de leitura de arquivos ou opcodes inválidos.

Ferramentas de depuração ou simuladores como [MARS](http://courses.missouristate.edu/KenVollmar/mars/) ou [SPIM](http://spimsimulator.sourceforge.net/) podem ajudar a testar e validar este código.
