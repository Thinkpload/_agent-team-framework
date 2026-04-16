# Remote Terminal — Control Claude Code from Android via Tailscale

Access your home PC's Claude Code terminal from Android using your existing tailnet.
No port forwarding, no TLS config, no extra tunnels — Tailscale handles everything.

---

## How It Works

```
Android (Tailscale app)  ──WireGuard──►  ttyd bound to TS IP
                                                │
                                          tmux session
                                                │
                                        claude (Claude Code CLI)
```

**ttyd** turns the terminal into a browser web app (xterm.js).  
**tmux** keeps the Claude Code session alive when you close the browser.  
**Tailscale** encrypts all traffic — plain HTTP over WireGuard is safe.

---

## Quick Start

### 1. Install dependencies (PC)

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

Minimum settings to change:

| Variable | What to set |
|---|---|
| `RT_PASS` | Strong password |
| `RT_WORKDIR` | Your project directory |
| `RT_BIND_TAILSCALE` | `1` (default — binds to TS IP only) |

### 3. Start

```bash
./start-server.sh
```

Output will show your access URLs:

```
 Tailscale (from Android — open in Chrome):
   http://100.x.x.x:7681
   http://your-pc.tail12345.ts.net:7681   (MagicDNS)
```

### 4. Connect from Android

1. Open Tailscale app on Android → make sure it's connected
2. Open Chrome → navigate to `http://100.x.x.x:7681` (or MagicDNS hostname)
3. Enter username/password → Claude Code terminal opens

---

## Android Tips

- **Add to home screen**: Chrome menu → "Add to Home Screen" for one-tap access
- **Bookmark the IP**: Save `http://100.x.x.x:7681` in Chrome for quick access
- **Landscape mode**: Rotate phone for more terminal space
- **Bluetooth keyboard**: Works natively, makes long sessions comfortable
- **Session persistence**: Close browser any time — Claude keeps running in tmux, reconnect to resume

---

## tmux Quick Reference

| Keys | Action |
|---|---|
| `Ctrl+B, D` | Detach (session stays running) |
| `Ctrl+B, [` | Scroll mode |
| `q` | Exit scroll mode |
| `Ctrl+B, ?` | All shortcuts |

---

## Managing the Server

```bash
./start-server.sh       # start
./stop-server.sh        # stop ttyd (tmux stays alive)
tmux attach -t claude-remote   # attach locally
tmux kill-session -t claude-remote   # kill session too
tail -f ttyd.log        # view ttyd logs
```

---

## Why No TLS?

Tailscale uses WireGuard — all traffic between your Android and PC is
end-to-end encrypted at the network layer. Adding HTTPS on top is redundant
when bound to the Tailscale interface. If you ever switch to `RT_BIND_TAILSCALE=0`
(LAN or public exposure), add TLS or use a reverse proxy with HTTPS.
