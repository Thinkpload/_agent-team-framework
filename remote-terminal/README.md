# Remote Terminal — Control Claude Code from Android

Access your home PC's Claude Code terminal from any Android device via a browser.
No special app needed — just open a URL.

---

## How It Works

```
Android browser  ──HTTPS──►  ttyd (web terminal)
                                    │
                              tmux session
                                    │
                            claude (Claude Code CLI)
```

**ttyd** turns any terminal into a browser-accessible web app using xterm.js.
**tmux** keeps the Claude Code session alive even if the browser disconnects.

---

## Quick Start (Home PC)

### 1. Install dependencies

```bash
cd remote-terminal/
chmod +x *.sh
./setup.sh
```

### 2. Configure

```bash
cp config.env.example config.env
nano config.env
```

Key settings:
| Variable | Description | Default |
|---|---|---|
| `RT_PORT` | Web terminal port | `7681` |
| `RT_USER` | Login username | `admin` |
| `RT_PASS` | Login password | `changeme123` |
| `RT_WORKDIR` | Directory where Claude opens | `~/projects` |
| `RT_TLS` | Enable HTTPS (set `1` for external access) | `0` |

> **Always change `RT_PASS` before exposing outside LAN.**

### 3. Start the server

```bash
./start-server.sh
```

You'll see output like:
```
 Local network (same WiFi):
   http://192.168.1.42:7681

 Login:
   User: admin
   Pass: yourpassword
```

### 4. Connect from Android

Open Chrome/Firefox on your Android phone and go to:
```
http://YOUR_PC_LOCAL_IP:7681
```

Enter your username and password → Claude Code terminal opens.

---

## Access from Outside Home Network

You need one of these to reach your PC from mobile data or another network.

### Option A: Tailscale (Recommended — free, encrypted VPN)

1. Install Tailscale on PC: https://tailscale.com/download/linux
2. Install Tailscale on Android: Play Store → "Tailscale"
3. Sign in to the same account on both devices
4. Your PC gets a stable private IP like `100.x.x.x`
5. Connect from Android: `http://100.x.x.x:7681`

For a public URL (accessible without Tailscale app):
```bash
./tunnel-tailscale.sh
```

### Option B: ngrok (free tier, temporary URL)

1. Register at https://ngrok.com, get your authtoken
2. `ngrok config add-authtoken YOUR_TOKEN`
3. Start the server, then in a second terminal: `./tunnel-ngrok.sh`
4. ngrok prints a URL like `https://abc123.ngrok.io` — open it on Android

### Option C: Direct port forward (advanced)

Forward port 7681 in your router to your PC. Set `RT_TLS=1` in config.env
for HTTPS. Access via your home's public IP.

---

## Android Tips

- **Add to home screen**: In Chrome, tap menu → "Add to Home Screen" for an app-like shortcut
- **Landscape mode**: Rotate phone for more screen space
- **External keyboard**: Bluetooth keyboard works great for long sessions
- **Font size**: ttyd supports Ctrl+scroll to resize font (or pinch on Android)
- **Session persistence**: If you close the browser, Claude keeps running in tmux. Reconnect to resume.

---

## tmux Quick Reference (useful from Android)

| Command | Action |
|---|---|
| `Ctrl+B, D` | Detach session (keeps running) |
| `Ctrl+B, [` | Scroll mode (swipe-friendly) |
| `Ctrl+B, ?` | Show all shortcuts |
| `q` | Exit scroll mode |

---

## Managing the Server

```bash
# Start
./start-server.sh

# Stop ttyd (tmux session stays alive)
./stop-server.sh

# Kill the tmux session too
tmux kill-session -t claude-remote

# View ttyd logs
tail -f ttyd.log

# Attach to the session locally
tmux attach -t claude-remote
```

---

## Security Notes

- Use a strong password in `RT_PASS`
- Enable `RT_TLS=1` if accessible from the internet (not just LAN)
- Tailscale is the safest option — traffic never leaves your encrypted tunnel
- On LAN-only setups, plain HTTP is fine
