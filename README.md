# Laravel K8s

## Container Registry

### Authentication

```bash
docker login ghcr.io -u [username] -p [token]
```

### Building

```bash
docker build . -t ghcr.io/caiokawasaki/k8s-laravel-octane/cli:v0.0.1 --target cli
docker build . -t ghcr.io/caiokawasaki/k8s-laravel-octane/fpm_server:v0.0.1 --target fpm_server
docker build . -t ghcr.io/caiokawasaki/k8s-laravel-octane/web_server:v0.0.1 --target web_server
docker build . -t ghcr.io/caiokawasaki/k8s-laravel-octane/cron:v0.0.1 --target cron
```

### Publishing

```bash
docker push ghcr.io/caiokawasaki/k8s-laravel-octane/cli:v0.0.1
docker push ghcr.io/caiokawasaki/k8s-laravel-octane/fpm_server:v0.0.1
docker push ghcr.io/caiokawasaki/k8s-laravel-octane/web_server:v0.0.1
docker push ghcr.io/caiokawasaki/k8s-laravel-octane/cron:v0.0.1
```

### Makefile

```bash
make docker VERSION=v?.?.?

# If you only want to run the builds
make docker-build VERSION=v?.?.?

# If you only want to push the images
make docker-push VERSION=v?.?.?
```
