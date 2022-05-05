- Dockerfile
  Used to create container image for Gollum with opinioned modifications
  - Build the image:
```
$ podman build . -t 'patrickdung/gollum:1.2'
```

- docker-compose with Podman
  Used to startup a container created in previous step
  - Users have to init or provide a Git repository on the directory that shared with the container (/wiki)
  - Update the docker-compose.yaml file if you are not using 'main' as the GIT branch name
  - The setting is not accepting a bare git repo
  - Start up the container
```
$ PODMAN_USERNS=keep-id podman-compose up -d
```
  'PODMAN_USERNS=keep-id' is used because the host share the directory to the container and
  I want to use use the same user that run the container to be able to edit shared files on the host
