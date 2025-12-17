= Front e Back End

== Comunicazione tra GUI e PID
Per fare in modo che l'interfaccia grafica e il processo di controllo pid comunichino e stato necessario comunicare attraverso dei file.

Quando un operatore cambia la temperatura target dall'interfaccia sul display LCD essa viene scritta sul file `/opt/amel/target-temperature`.

Analogamente, il processo pid quando rileva una temperatura tramite il sensore DS18B20, scrive quest'ultima sul file `/opt/amel/current-temperature`. 