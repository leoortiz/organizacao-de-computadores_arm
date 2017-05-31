OS: Linux

1. Execute o montador:
./arm-none-eabi-linux-as -o montador.out arm.s

2. Execute o ligador:
./arm-none-eabi-linux-ld -T mapa.lds -o ligador.out montador.out

3. Execute o simulador:
./armsim -c -l ligador.out -d devices.txt

No simulador, "g _start" para iniciar a simulação.
