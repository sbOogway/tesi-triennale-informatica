= Manuale utente

== Compilazione da `buildroot`
Innanzitutto e necessario cloneare la repo git `git@git.amelchem.com:amel/buildroot.git`
con il comando `git clone git@git.amelchem.com:amel/buildroot.git` opppure 
`git clone https://git.amelchem.com/amel/buildroot.git` e fare checkout nel branch 
`Vulcano-papaccioli`. 
Successivamente bisogna far partire la compilazione di `buildroot` con il comando `make`,
che comprende `linux`, `barebox` e tutto cio di necessario per il sistema embedded.
La prima compilazione puo durare anche 1 ora a causa dei tanti pacchetti da scaricare 
ed installare. Sono necessari all'incirca 20GB di memoria disponibile sul disco fisso.

== Flashing scheda sdcard
Dopo aver compilato, si popolera la cartella `output` di `buildroot` con i file necessari.
Dobbiamo copiare bit per bit il file `output/images/sdcard.img` sulla memory card con il comando
`sudo dd if=output/images/sdcard.img of=/dev/mmcblk0 bs=4M status=progress conv=fsync`. 
Cambia i path e i nomi in base alla tua macchina.

== Embedded
Estrai la scheda sd dal computer ed introducila nella board `Ganador` nello slot apposito.
Aspetta 1 minuto circa per il sistema che si avvii e si installi (generazione ssh keys 30 sec circa).
A questo punto abbiamo due opzioni per connetterci: tramite porta seriale o `ssh`.

=== Porta seriale
Per connetterci tramite la porta seriale
=== `ssh`
