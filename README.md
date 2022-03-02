# Packer VM Redes

Este repo contiene lo necesario para la construcción de la VM usada en la cátedra Redes y Comunicaciones. Requiere tener instalada la herramienta HashiCorp Packer. (https://www.packer.io/downloads)


## Estructura

**catedra-redes.pkr.hcl**

Contiene especificaciones de hardware y la definición de cómo se irá ejecutando el building.

**preseed.pkrtpl**

Es un template de packer pero a su vez el contenido corresponde a las indicaciones del proceso de instalación de Debian. Ver https://wiki.debian.org/DebianInstaller/Preseed


**ansible/redes.yml**

Escritas en Ansible, contiene las tareas que se ejecutarán luego de la instalación. Entre ellas instalación del proyecto CORE (https://www.nrl.navy.mil/Our-Work/Areas-of-Research/Information-Technology/NCS/CORE/)


## Build

```
$ packer build catedra-redes.pkr.hcl
```
#### Importante

La construcción de catedra-redes depende de la construcción de catedra-base, por lo tanto primero hay que ejecutar:

```
$ packer build catedra-base.pkr.hcl
```

## Output

Generará dentro del directorio ./output-catedra-redes/ el ovf y su vmdk para importar en VBox.

- Redes y Comunicaciones v22.2.ovf
- Redes y Comunicaciones v22.2-disk001.vmdk
