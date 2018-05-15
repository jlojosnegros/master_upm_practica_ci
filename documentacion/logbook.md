# Practica final Integracion Continua

## Setup inicial

### Lanzar la forja
 He tenido que lanzar una forja anterior porque la ultima que hay en el repo no parece funcionar correctamente el ldap porque el usuario developer no me deja entrar, supongo que por algun problema de comunicacion con el contenedor de ldap.
 
 Pasos a realizar:
 
- Configurar las credenciales del usuario developer para ssh: A;adiendo la clave ssh en gerrit.
- Crear un nuevo proyecto en Gerrit con el nombre de tic-tac-toe
- Subir el codigo del proyecto de pruebas.
    - He tenido que darle permisos de Verify al usuario admin en refs/heads/* Label: Verify


## Creacion de un Job de commit.

Primero creacion de un nuevo job en Jenkins siguiendo las instrucciones dadas en las transparencias del "Tema 7- Jenkins Avanzado" para la creacion de un job de commit.

El problema en la creación del job radicó en que al ejecutar el job no reconocía la url del repo de git que estaba dentro del contenedor de Gerrit, de manera que tuve que buscar la ip del contenedor mediante el comando "docker inspect" y ponerla directamente en la url del repo de git.
Una vez hecho esto el job funcionó sin problemas. 

Fichero del job:

```
node {
    
   stage ('Checkout') {
        
      git url: 'http://172.18.0.6:8080/tic-tac-toe'
   }

   stage ('Build Java') {

      docker.image('maven').inside('-v $HOME/.m2:/root/.m2') {

        sh 'mvn -Dtest=BoardTest,TicTacToeGameTest,TicTacToeGamePlayTest test'
      }
   }
  always {
      step([$class: 'JUnitResultArchiver', 
         testResults: '**/target/surefire-reports/TEST-*.xml'])
  }
}
```

NOTA: tengo un problema con esta configuracion ... por algun motivo siempre coje el commit anterior al que ha lanzado el trigger y no encuentro ninguna opcion para poder limpiar el workspace que no pase por instalar un plugin, cosa que no quiero hacer dada la fragilidad de la forja.
