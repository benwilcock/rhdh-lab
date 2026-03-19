# Jenkins Integration

## Overview

Jenkins is integrated with RHDH Local using the unified compose stack approach. It runs as part of the RHDH compose configuration, enabling simplified management and direct network communication between containers.

## Architecture

Jenkins is defined in `compose.override.yaml` and managed alongside RHDH:

```
RHDH Network (rhdh-local_default)
├── rhdh        -> connects to http://jenkins:8080 (internal DNS)
├── jenkins     -> internal: 8080, external: 8567
├── db          -> PostgreSQL
└── ...         -> other RHDH services
```

All containers share the same Docker network and communicate using container names as DNS hostnames.

**Benefits:**
- Unified lifecycle: start/stop Jenkins with `up.sh`/`down.sh`
- Direct container-to-container communication via DNS
- No `extra_hosts` workarounds needed
- Single source of truth for all RHDH-related services

## Configuration

### compose.override.yaml

Jenkins service definition in `rhdh-customizations/compose.override.yaml`:

```yaml
services:
  rhdh:
    depends_on:
      - jenkins

  jenkins:
    container_name: jenkins
    image: jenkins/jenkins:lts-jdk21
    restart: unless-stopped
    privileged: true
    user: root
    ports:
      - 8567:8080    # Web UI
      - 50000:50000  # Agent communication
    volumes:
      - /path/to/jenkins/config:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
```

### Environment Variables

In `rhdh-customizations/.env`:

```bash
JENKINS_URL=http://jenkins:8080      # Internal container name + port
JENKINS_USERNAME=your-jenkins-user
JENKINS_TOKEN=your-jenkins-api-token
```

The URL uses the container name `jenkins` and internal port `8080` (not the external port `8567`).

### RHDH Plugin Configuration

Jenkins plugins in `rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml`:

```yaml
- package: oci://ghcr.io/.../backstage-community-plugin-jenkins-backend:...
  disabled: false
  pluginConfig:
    jenkins:
      instances:
        - name: default
          baseUrl: ${JENKINS_URL}
          username: ${JENKINS_USERNAME}
          apiKey: ${JENKINS_TOKEN}

- package: oci://ghcr.io/.../backstage-community-plugin-jenkins:...
  disabled: false
  pluginConfig:
    dynamicPlugins:
      frontend:
        backstage-community.plugin-jenkins:
          mountPoints:
            - mountPoint: entity.page.ci/cards
              importName: EntityJenkinsContent
              if:
                allOf:
                  - isJenkinsAvailable
```

Catalog entities need the annotation `jenkins.io/job-full-name: "job-name"` for the Jenkins tab to appear.

## Accessing Jenkins

- **From host browser**: <http://localhost:8567>
- **From RHDH container**: `http://jenkins:8080` (internal DNS)
- **From RHDH UI**: Navigate to any catalog entity with a Jenkins annotation and click the CI tab

## Verification

```bash
# Check containers are running
podman ps | grep -E "(jenkins|rhdh)"

# Test host access
curl -I http://localhost:8567
# Expected: HTTP/1.1 403 Forbidden (requires auth)

# Test internal connectivity
podman exec rhdh curl -I http://jenkins:8080
# Expected: HTTP/1.1 403 Forbidden (proves RHDH can reach Jenkins)

# Verify environment
podman exec rhdh env | grep JENKINS
```

## Troubleshooting

### Jenkins Not Starting

```bash
podman logs jenkins
```

Common causes: port 8567 already in use, permissions issue with data directory, Docker socket not accessible.

### RHDH Cannot Reach Jenkins

```bash
podman exec rhdh curl -v http://jenkins:8080
podman exec rhdh env | grep JENKINS
```

Verify `JENKINS_URL=http://jenkins:8080` (internal name, not external URL). If Jenkins has not fully started yet, wait and retry.

### Jenkins Plugin Not Loading

```bash
podman logs rhdh | grep jenkins
```

Check that the plugin is set to `disabled: false` and that catalog entities have the `jenkins.io/job-full-name` annotation.

### Authentication Failures

```bash
curl -u $JENKINS_USERNAME:$JENKINS_TOKEN http://localhost:8567/api/json
```

If this fails, regenerate the Jenkins API token (Jenkins > User > Configure > API Token).

## Maintenance

### Updating Jenkins

Edit the image tag in `rhdh-customizations/compose.override.yaml`, then restart:

```bash
./down.sh && ./up.sh --customized
```

### Backing Up Jenkins Data

Jenkins data is stored outside the RHDH workspace. Back it up separately:

```bash
tar -czf ~/jenkins-backup-$(date +%Y%m%d).tar.gz /path/to/jenkins/config
```

### Viewing Logs

```bash
podman logs jenkins          # Full log
podman logs -f jenkins       # Follow mode
podman logs rhdh | grep jenkins  # Jenkins plugin activity in RHDH
```
