# Using Podman Instead of Docker

This project has been configured to use Podman as the container runtime instead of Docker.

## What Changed

All documentation and scripts have been updated to use `podman` commands:

- ✅ `README.md` - Updated prerequisites and commands
- ✅ `DEPLOYMENT.md` - Updated deployment steps
- ✅ `k8s/README.md` - Updated Kubernetes deployment guide
- ✅ `app/README.md` - Updated local development instructions
- ✅ `scripts/build-and-push.sh` - Updated build script to use Podman

## Podman vs Docker

Podman is a drop-in replacement for Docker with some advantages:

### Advantages
- ✅ **Daemonless**: No background daemon required
- ✅ **Rootless**: Runs containers without root privileges
- ✅ **Secure**: Better security model
- ✅ **Compatible**: Uses the same container images and registries
- ✅ **Open Source**: Fully open source (no licensing concerns)

### Command Compatibility

Podman commands are nearly identical to Docker:

| Docker | Podman |
|--------|--------|
| `docker build` | `podman build` |
| `docker run` | `podman run` |
| `docker push` | `podman push` |
| `docker pull` | `podman pull` |
| `docker login` | `podman login` |
| `docker ps` | `podman ps` |
| `docker images` | `podman images` |

## Installation

### macOS
```bash
brew install podman
podman machine init
podman machine start
```

### Linux
```bash
# Fedora/RHEL/CentOS
sudo dnf install podman

# Ubuntu/Debian
sudo apt-get install podman
```

### Windows (WSL2)
```bash
# In WSL2
sudo apt-get install podman
```

## Verify Installation

```bash
# Check version
podman --version

# Test with hello-world
podman run hello-world

# Check machine status (macOS only)
podman machine list
```

## Building for ARM64

The build script uses `--platform linux/arm64` to build images for your EKS cluster's ARM-based t4g.medium instances:

```bash
podman build --platform linux/arm64 -t myimage .
```

### Important Notes

1. **macOS/Windows**: Podman uses a VM (podman machine) to run containers
2. **Multi-arch builds**: Podman supports `--platform` flag natively
3. **No buildx needed**: Unlike Docker, no special multi-arch plugin needed

## Troubleshooting

### Issue: "Cannot connect to Podman"

**macOS users:**
```bash
# Start the podman machine
podman machine start

# Check status
podman machine list
```

### Issue: "Platform mismatch" warnings

This is normal when building ARM64 images on x86_64 machines. QEMU emulation is used automatically.

### Issue: "Permission denied" on Linux

```bash
# Run podman in rootless mode (recommended)
podman run --rm -it alpine

# Or add user to podman group
sudo usermod -aG podman $USER
newgrp podman
```

### Issue: Build is slow on macOS/Windows

Cross-platform builds (ARM64 on x86_64) use emulation and are slower. This is expected.

**Speed tips:**
- Close other applications during build
- Allocate more resources to podman machine:
  ```bash
  podman machine stop
  podman machine set --cpus 4 --memory 8192
  podman machine start
  ```

## Using Docker Compatibility

If you need Docker command compatibility, you can create an alias:

```bash
# Add to your ~/.bashrc or ~/.zshrc
alias docker=podman

# Or use podman-docker package (Linux)
sudo apt-get install podman-docker  # Ubuntu/Debian
sudo dnf install podman-docker      # Fedora/RHEL
```

## ECR Authentication

ECR authentication works the same with Podman:

```bash
aws ecr get-login-password --region us-west-2 --profile dd-ese | \
  podman login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com
```

## Development Workflow

```bash
# 1. Build locally for testing
podman build -t football-viewer:test app/

# 2. Run locally
podman run -p 5000:5000 football-viewer:test

# 3. When ready, build for ARM64 and push to ECR
./scripts/build-and-push.sh

# 4. Deploy to Kubernetes
./scripts/deploy.sh
```

## Additional Resources

- [Podman Documentation](https://docs.podman.io/)
- [Podman vs Docker](https://podman.io/whatis.html)
- [Podman Desktop](https://podman-desktop.io/) - GUI alternative to Docker Desktop
- [Migration Guide](https://podman.io/getting-started/migration)

## Known Differences

1. **Networking**: Podman uses CNI plugins instead of Docker networks
2. **Compose**: Use `podman-compose` instead of `docker-compose`
3. **Desktop UI**: Use Podman Desktop instead of Docker Desktop
4. **Socket**: Podman socket location differs from Docker socket

For this project, these differences don't matter since we're only building and pushing images.

## Quick Reference

```bash
# Check Podman is working
podman version
podman info

# Build image for ARM64
podman build --platform linux/arm64 -t myimage .

# Login to ECR
aws ecr get-login-password --region us-west-2 | \
  podman login --username AWS --password-stdin <ecr-registry>

# Push to ECR
podman push <ecr-registry>/myimage:latest

# List local images
podman images

# Remove unused images
podman image prune
```

---

**You're all set! Podman works seamlessly with this project.** 🚀

