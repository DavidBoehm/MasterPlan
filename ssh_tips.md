Now that you’re comfortable with the basics, configuring your local SSH config file (`<PATH_TO_SSH_CONFIG>` on Windows or Linux) is the ultimate "quality of life" upgrade. It turns long, annoying commands into short, memorable ones.

Here are the most useful advanced tricks to add to your file:

### **1. The "Alias" Shortcut**
Instead of typing `ssh <USERNAME>@<IP_ADDRESS>`, you can define an alias so you only have to type `ssh <HOSTNAME>`.

```ssh
Host <HOSTNAME>
    HostName <IP_ADDRESS>
    User <USERNAME>
    IdentityFile <PATH_TO_PRIVATE_KEY>
```

### **2. Connection Multiplexing (Lightning Fast)**
Normally, every time you run an SSH command, your PC has to perform a "handshake" with the Pi. On an old Pi 1, this can take several seconds. Multiplexing keeps a single master connection open in the background so subsequent windows open **instantly**.

```ssh
Host *
    ControlMaster auto
    ControlPath <PATH_TO_SSH_SOCKETS>/%r@%h-%p
    ControlPersist 10m
```
*Note: You’ll need to create the folder first: `mkdir -p <PATH_TO_SSH_SOCKETS>`.*

### **3. Keep-Alive (Stop the "Timeout" Hangs)**
If you leave your terminal sitting for 10 minutes and it freezes, it's because the connection timed out. This forces the Pi and your PC to "ping" each other every 60 seconds to stay awake.

```ssh
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### **4. Using a Jump Host (The "Bastion" Trick)**
If you ever want to SSH into a device that *isn't* exposed to the internet, but your Unraid server *is*, you can use Unraid as a "Jump Host."

```ssh
Host <INTERNAL_HOSTNAME>
    HostName <IP_ADDRESS>
    User <USERNAME>
    ProxyJump <JUMP_HOST>
```
Now, typing `ssh <INTERNAL_HOSTNAME>` will automatically bounce your connection through your jump host to get to the target machine.

### **5. Conditional "Match" Blocks**
You can apply specific settings only when you are on your home Wi-Fi versus when you are out. For example, use a local IP at home, but use the Tailscale IP when you're away.

```ssh
Match exec "ping -c 1 -W 1 <LOCAL_GATEWAY_IP>"
    Host <HOSTNAME>
        HostName <LOCAL_IP_ADDRESS>

Host <HOSTNAME>
    HostName <TAILSCALE_IP>  # Your Tailscale IP
```

---

### **Where to find this file:**

* **Windows:** `<PATH_TO_SSH_CONFIG>` (You might have to create the file named `config` with no file extension).
* **Linux/Mac:** `<PATH_TO_SSH_CONFIG>`

**Pro Tip:** Always put your specific `Host` entries at the **top** and your global `Host *` settings at the **bottom**. SSH reads the file from top to bottom and stops at the first match it finds for a specific setting.

**Would you like me to help you write a specific "Jump Host" config for your Unraid and Pi setup?**