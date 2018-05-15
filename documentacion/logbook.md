# Practica final Integracion Continua

## Setup inicial

### Lanzar la forja
 He tenido que lanzar una forja anterior porque la ultima que hay en el repo no parece funcionar correctamente el ldap porque el usuario developer no me deja entrar, supongo que por algun problema de comunicacion con el contenedor de ldap.
 
 Pasos a realizar:
 
- Configurar las credenciales del usuario developer para ssh: A;adiendo la clave ssh en gerrit.
- Crear un nuevo proyecto en Gerrit con el nombre de tic-tac-toe
- Subir el codigo del proyecto de pruebas.
    - He tenido que darle permisos de Verify al usuario admin en refs/heads/* Label: Verify

NOTA: Instrucciones para la forja en el Tema 6
## Creación de un Job de commit.

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


## Creación de un Job de Merge

Primero creamos un nuevo job en jenkins tomando como referencia el job de commit pero cambiando el trigger de gerrit a "Ref Updated" tal y como se indica en la documentación.
Ademas hay que cambiar el campo Pattern dentro de Branches porque si ponemos "Path: **" este job tambien se lanza con los commits. Tenemos que poner "Plain: master" en su lugar para que solo sea lanzado cuando se produce un merge con la rama master

Consigo que se lance, pero no hay manera de que ejecute los test... me dice que no hay un Docker Environment valido ... 
Este es el JenkinsFile que estoy utilizando

```
node 
{
    stage ('Checkout')
    {
        git url: 'http://172.18.0.6:8080/tic-tac-toe'
    }
    stage ('Build and test') 
    {
        docker.image('maven').inside('-p 12345:8080 -v $HOME/.m2:/root/.m2 ' + '-v /var/run/docker.sock:/var/run/docker.sock') 
        {
            sh 'mvn -Dtest=SeleniumSytemTest test'
        }
        step([$class: 'JUnitResultArchiver',
        testResults: '**/target/surefire-reports/TEST-*.xml'])
    }
}
```


NOTA: Fichero build-image.sh con el commit del repo en la imagen

```sh
#!/bin/bash
docker build --build-arg GIT_COMMIT=$(git rev-parse HEAD) --build-arg COMMIT_DATE=$(git log -1 --format=%cd --date=format:%Y-%m-%dT%H:%M:%S) -t micaelgallego/curso-ci-ejem2:latest .

```

Dockerfile para construir la imagen con el comit

```
FROM openjdk:8-jre
ARG GIT_COMMIT=unspecified
LABEL git_commit=$GIT_COMMIT
ARG COMMIT_DATE=unspecified
LABEL commit_date=$COMMIT_DATE
COPY target/*.jar /usr/app/app.jar
WORKDIR /usr/app
CMD [ "java", "-jar", "app.jar" ]
```




## Informacion 
* Credenciales de docker hub para la practica : practicacimasterupm/12341234
* Estado de los permisos de /var/run/docker.sock antes de que los tocase.
```
srw-rw---- 1 root docker 0 may 15 10:04 docker.sock
```

## Nuevos detalles del correo.
* Uno de ellos esta utilizando el nombre de los contenedores como nombres de maquina y no tengo claro si se lo resuelve.
* Juan parece que ha tenido que hacer un chmod 777 al docker.sock para poder ejecutar cosas.


## System TEst y var/run/docker.sock
Estoy intentandolo poniendo permisos para que todos puedan leer esto ( sudo chmod o+r /var/run/docker.sock)
srw-rw-r-- 1 root docker 0 may 15 10:04 docker.sock

Parece que no funciona ...  asi que permisos de escritura al canto ... 
y con permisos de escritura si que funciona ... en fin ... 


# TODO

* TEST DE SISTEMA:
  * Solucionado el tema de los permisos.
  * Ahora los problemas SON:
	* No funcionan los wait, de modo que no podemos encontrar las ventanas emergentes.
	* No se que le pasa a los test de cucumber que dan muchos errores.
  * Resumiendo, SIGUEN SIN PASAR UNA SOLA VEZ LOS TEST DE SISTEMA
  
* ARCHIVA:
  * Me da un timeout ... NAda, sigue dando timeout
  * He creado un nuevo usuario en archiva (jenkins/jenkins01) dandonle los permisos necesarios en todos los repositorios y tambien he configurado las credenciales en el fichero ~/.m2/settings.xml, que se comparte con el docker, pero no parece que nada haya cambiado ... PERMISOS?
  * No puede meter el jar en el archiva porque dice que no le contesta en la ip dada ... la verdad es que a mi tampoco me contesta en esa ip desde el host, pero se supone que eso es normal porque desde el host tiene que contestar en localhost, pero al estar ejecutandose desde un contenedor de docker ... deberia de necesitar otra cosa, porque estoy haciendo lo mismo para el git que esta en el contenedor de gerrit y funciona sin problemas.

* SONARQUBE
  * El SonarQube es que ni lo he intentado ...
