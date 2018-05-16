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
* Repositorio de github con el proyecto de tic-tac-toe modificado para correr en ci: https://github.com/jlojosnegros/tic-tac-toe-ci
* Comando maven para leer la version de un projecto
```
mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec
```
* Comando maven para setear la version de un projecto
```
mvn versions:set -DnewVersion=1.0.3-SNAPSHOT
```
* Expresion regular para capturar los elementos de una version de java
```
^([0-9]*)\.([0-9]*)\.([0-9]*)-(.*)$
```
* Comando para obtener la fecha del sistema en el formato que queremos:
```
date +%Y%m%d
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
  - [x] Solucionado el tema de los permisos.
  - [x] No funcionan los wait, de modo que no podemos encontrar las ventanas emergentes.
  - [?] Test Cucumber: No pasan porque siempre me dan NullPointerException, parece que los getDriver no funcionan correctamente y no tengo ni puta idea de por que.
  
* ARCHIVA:
  - [?] Me da un timeout ... NAda, sigue dando timeout
   He creado un nuevo usuario en archiva (jenkins/jenkins01) dandonle los permisos necesarios en todos los repositorios y tambien he configurado las credenciales en el fichero ~/.m2/settings.xml, que se comparte con el docker, pero no parece que nada haya cambiado ... PERMISOS?

* SONARQUBE
  - [ ] El SonarQube es que ni lo he intentado ...


## Creación de un Job de Nightly

El scheduler para el trabajo sigue el mismo patron que el de un cron.
menuda puta pesadilla hasta que he conseguido pasar datos desde un stage hasta el siguiente.
Estoy repitiendo codigo como un cabron.

[] TODO 

- [x] Ejecutar test unitarios y de sistema
- [x] Crear una imagen Docker 
- [x] Publicar imagen Docker con el tag:X.Y.Z.nightly.YYYYMMDD
- [?] Ejecutar el software de la imagen y ejecutar contra el los test de sistema
- [x] Si los test pasan subir la imagen con un nuevo tag: nightly


## Creacin de un Job de Release

[TODO]

- [x] Recibir como parametro la nueva version
- [x] Modificar el pom.xml quitando el SNAPSHOT de la version ( mas o menos lo tengo.)
- [ ] Ejecutar test unitarios y de sistema
- [?] Publicar artefacto en Archiva -> Esto no se porque pero no me funciona.
- [x] Generar una imagen docker y publicarla con el tag igual a la version del pom.xml ( supongo que una vez quitado el SNAPSHOT del final.)
- [x] Volver a publicarla con el tag 'latest'
- [ ] Crear un tag en el repositorio de git en Gerrit con el nombre de la version del pom.xml
- [x] Actualizar la version del pom.xml con el parametro que nos pasaron como version, si no termina en "-SNAPSHOT" tendremos que ponerlo nosotros.
