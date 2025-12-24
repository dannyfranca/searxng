# SearXNG Container Setup

A self-hosted, privacy-respecting metasearch engine configured for **completely uncensored search** with no safe search filtering.

## 📋 Overview

This repository provides multiple deployment options for SearXNG:

| Method         | Best For                        | Configuration         |
| -------------- | ------------------------------- | --------------------- |
| Docker Compose | Quick setup, development        | Environment variables |
| Podman Quadlet | Production, systemd integration | Hardcoded in files    |

Both deployments use the same `settings.yml` which is pre-configured with:
- ✅ **Safe search disabled** (`safe_search: 0`)
- ✅ **No content filtering**
- ✅ **All search categories enabled**
- ✅ **JSON API access enabled**
- ✅ **Limiter disabled** for unrestricted access

---

## 🚀 Quick Start

### Docker Compose (Recommended for most users)

```bash
# 1. Clone this repository
git clone <this-repo> && cd searxng

# 2. Copy and configure environment
cp .env.example .env

# 3. Generate a secret key (recommended)
openssl rand -hex 32
# Add the output to .env as SEARXNG_SECRET=<key>

# 4. Start the container
docker compose up -d

# 5. Access SearXNG
open http://localhost:8888
```

### Podman Quadlet (For systemd integration)

```bash
# 1. Install quadlet files + settings (user mode)
make install-user

# 2. Generate a secret key
make generate-secret

# 3. Edit the installed container file with your secret
nano ~/.config/containers/systemd/searxng.container
# Set: Environment=SEARXNG_SECRET=<your-generated-key>

# 4. Optionally customize settings
nano ~/.config/containers/systemd/searxng/settings.yml

# 5. Reload systemd and start
make reload
make start

# 6. Access SearXNG
open http://localhost:8888
```

---

## 📁 Repository Structure

```
searxng/
├── docker-compose.yml      # Docker Compose configuration
├── .env.example            # Environment variables template
├── Makefile                # Quadlet installation helper
├── searxng/
│   └── settings.yml        # SearXNG configuration (uncensored)
├── quadlet/
│   └── searxng.container   # Podman Quadlet container definition
├── mcp/
│   ├── claude-desktop.json # MCP config for Claude Desktop
│   ├── cursor-settings.json # MCP config for Cursor IDE
│   ├── vscode-settings.json # MCP config for VS Code
│   └── lmstudio-config.json # MCP config for LM Studio
└── README.md               # This file
```

---

## ⚙️ Configuration Options

### Environment Variables (Docker Compose)

| Variable           | Default                 | Description                             |
| ------------------ | ----------------------- | --------------------------------------- |
| `SEARXNG_PORT`     | `8888`                  | Port to expose SearXNG on               |
| `SEARXNG_BASE_URL` | `http://localhost:8888` | Base URL for the instance               |
| `SEARXNG_SECRET`   | (empty)                 | Secret key for cryptographic operations |

### Settings.yml Options

The `searxng/settings.yml` file controls search behavior:

```yaml
search:
  safe_search: 0          # 0=off, 1=moderate, 2=strict
  default_lang: "all"     # Language for results
  autocomplete: ""        # Disabled - would leak queries to provider

server:
  secret_key: "..."       # Overridden by SEARXNG_SECRET env var
  limiter: false          # Rate limiting (disabled)
  image_proxy: true       # Privacy-preserving image proxy
```

### Enabled Plugins

| Plugin                  | Description                     | Example                               |
| ----------------------- | ------------------------------- | ------------------------------------- |
| Hash plugin             | Generate MD5/SHA256 hashes      | Search `hash hello`                   |
| Self Information        | Show your IP, user-agent        | Search `my ip`                        |
| Tracker URL remover     | Strip tracking params from URLs | Auto-removes `?utm_source`, `?fbclid` |
| Ahmia blacklist         | Filter harmful .onion sites     | Automatic for Tor results             |
| Open Access DOI rewrite | Link to open access papers      | Automatic for academic results        |
| Hostnames plugin        | Block/prioritize domains        | Configure in settings.yml             |
| Basic Calculator        | Evaluate math expressions       | Search `sqrt(144) + 5`                |
| Unit converter          | Convert units                   | Search `10 miles in km`               |

### Hostnames Plugin Configuration

The hostnames plugin lets you control which domains appear in results. Configure in `settings.yml`:

```yaml
hostnames:
  # Block domains entirely
  remove:
    - '(.*\.)?facebook\.com$'
    - '(.*\.)?pinterest\.com$'

  # Redirect to privacy-friendly frontends
  replace:
    '(.*\.)?youtube\.com$': 'invidious.snopyta.org'
    '(.*\.)?twitter\.com$': 'nitter.net'

  # Boost these domains to top
  high_priority:
    - '(.*\.)?wikipedia\.org$'

  # Demote these domains
  low_priority:
    - '(.*\.)?w3schools\.com$'
```

**Pattern format:** Uses Python regex. `(.*\.)?example\.com$` matches `example.com` and all subdomains.

---

## 🌐 Internet Access & Authentication

### Understanding the Secret Key

The `SEARXNG_SECRET` environment variable is used **internally** for:
- Cryptographic operations (image proxy, sessions)
- Security tokens

⚠️ **It is NOT an API key for remote access authentication.**

### Securing Remote Access

SearXNG doesn't have built-in API authentication. For internet exposure, use **HTTP Basic Auth**:

#### Docker Compose with Basic Auth

You'll need a reverse proxy (nginx, Caddy, Traefik) to add authentication. Example with Caddy:

```
search.yourdomain.com {
    basicauth * {
        admin $2a$14$... # Generate with: caddy hash-password
    }
    reverse_proxy localhost:8888
}
```

#### Quadlet with Basic Auth (via Podman)

For simple setups, you can use a sidecar container or external reverse proxy.

### Using with MCP (Remote Access)

When connecting MCP clients to a protected SearXNG instance, use HTTP Basic Auth:

```json
{
  "mcpServers": {
    "searxng": {
      "command": "npx",
      "args": ["-y", "mcp-searxng"],
      "env": {
        "SEARXNG_URL": "https://search.yourdomain.com",
        "AUTH_USERNAME": "your-username",
        "AUTH_PASSWORD": "your-password"
      }
    }
  }
}
```

### Local Network (No Auth Needed)

For local-only access (localhost or trusted LAN), no authentication is required:

```json
{
  "env": {
    "SEARXNG_URL": "http://localhost:8888"
  }
}
```

### Security Checklist

| Scenario   | Secret Key    | HTTP Basic Auth | TLS/HTTPS    |
| ---------- | ------------- | --------------- | ------------ |
| Local only | Optional      | ❌ Not needed    | ❌ Not needed |
| LAN access | ✅ Recommended | Optional        | Optional     |
| Internet   | ✅ Required    | ✅ Required      | ✅ Required   |

## 🤖 MCP Server Configuration

Use SearXNG with AI assistants via the Model Context Protocol (MCP).

### Claude Desktop

1. Copy `mcp/claude-desktop.json` content
2. Add to `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "searxng": {
      "command": "npx",
      "args": ["-y", "mcp-searxng"],
      "env": {
        "SEARXNG_URL": "http://localhost:8888"
      }
    }
  }
}
```

### Cursor IDE

1. Open Cursor Settings → MCP Servers
2. Add the configuration from `mcp/cursor-settings.json`

### VS Code (GitHub Copilot)

1. Add to your VS Code `settings.json`:

```json
{
  "mcp": {
    "servers": {
      "searxng": {
        "command": "npx",
        "args": ["-y", "mcp-searxng"],
        "env": {
          "SEARXNG_URL": "http://localhost:8888"
        }
      }
    }
  }
}
```

### LM Studio

1. Navigate to MCP Servers settings
2. Add the configuration from `mcp/lmstudio-config.json`

### MCP Environment Variables

| Variable        | Description                             |
| --------------- | --------------------------------------- |
| `SEARXNG_URL`   | URL of your SearXNG instance (required) |
| `AUTH_USERNAME` | HTTP Basic Auth username (optional)     |
| `AUTH_PASSWORD` | HTTP Basic Auth password (optional)     |
| `USER_AGENT`    | Custom User-Agent header (optional)     |

**MCP Package:** [`mcp-searxng`](https://github.com/ihor-sokoliuk/mcp-searxng) - 367+ stars, actively maintained

---

## 🔧 Quadlet Makefile Commands

```bash
make help              # Show all available commands
make generate-secret   # Generate a random secret key
make install-user      # Install quadlet + settings (rootless)
make install-system    # Install quadlet + settings (root)
make reload            # Reload systemd daemon
make start             # Start SearXNG service
make stop              # Stop SearXNG service
make status            # Check service status
make logs              # View service logs
make uninstall-user    # Remove all files (rootless)
make uninstall-system  # Remove all files (root)
```

---

## 🔍 Using the Search API

SearXNG provides a JSON API for programmatic access:

```bash
# Basic search
curl "http://localhost:8888/search?q=hello+world&format=json"

# With parameters
curl "http://localhost:8888/search?q=query&format=json&categories=general&language=en"
```

### API Parameters

| Parameter    | Description       | Example                        |
| ------------ | ----------------- | ------------------------------ |
| `q`          | Search query      | `hello+world`                  |
| `format`     | Response format   | `json`, `html`                 |
| `categories` | Search categories | `general,images`               |
| `language`   | Result language   | `en`, `de`, `all`              |
| `time_range` | Time filter       | `day`, `week`, `month`, `year` |
| `pageno`     | Page number       | `1`, `2`, `3`                  |

---

## 🛡️ Security Considerations

### For Local Use
- The default configuration works out of the box
- Consider the security implications of uncensored search

### For Internet Exposure
1. **Always use a strong secret key**
   ```bash
   openssl rand -hex 32
   ```
2. **Use TLS** via reverse proxy
3. **Consider authentication** at the reverse proxy level
4. **Monitor access logs** for abuse

---

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs
docker compose logs searxng
# or
make logs
```

### Settings not applied
The settings.yml is mounted as a volume. Changes require container restart:
```bash
docker compose restart
# or
make stop && make start
```

### Permission issues (Quadlet)
```bash
# Ensure settings directory is accessible
chmod -R u+rw ~/.config/containers/systemd/searxng
```

### Port already in use
Change the port in `.env` or `quadlet/searxng.container`:
```bash
SEARXNG_PORT=9999
```

---

## 📚 Resources

- [SearXNG Documentation](https://docs.searxng.org/)
- [SearXNG GitHub](https://github.com/searxng/searxng)
- [Podman Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [MCP Protocol](https://modelcontextprotocol.io/)

---

## 📄 License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 

SearXNG itself is licensed under AGPL-3.0.
