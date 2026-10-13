# Build Without Mac - Complete Guide

Since you don't have a Mac, here are **3 working solutions** to build TetherUnlock:

---

## Solution 1: GitHub Actions (FREE - Recommended)

This builds the .deb in the cloud using GitHub's free servers.

### Steps:

1. **Create GitHub Account** (if you don't have one)
   - Go to https://github.com
   - Sign up (free)

2. **Create New Repository**
   - Click "+" → "New repository"
   - Name: `TetherUnlock`
   - Select "Public"
   - Click "Create repository"

3. **Upload Project Files**
   
   **Option A: Using GitHub Web (easiest)**
   ```
   1. Click "uploading an existing file"
   2. Drag ALL files from TetherUnlock folder
   3. Click "Commit changes"
   ```

   **Option B: Using Git (if installed)**
   ```bash
   cd TetherUnlock
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/TetherUnlock.git
   git push -u origin main
   ```

4. **Trigger Build**
   ```
   1. Go to "Actions" tab
   2. Click "Build TetherUnlock"
   3. Click "Run workflow"
   4. Wait 5-10 minutes
   ```

5. **Download Your .deb**
   ```
   1. Click on the completed workflow run
   2. Scroll to "Artifacts"
   3. Click "TetherUnlock-deb" to download
   ```

### Result:
You'll get a `.deb` file ready to install on your iPad!

---

## Solution 2: WSL2 on Windows (Local Build)

Windows Subsystem for Linux allows running Linux tools on Windows.

### Setup (One-time):

1. **Enable WSL**
   ```powershell
   # Open PowerShell as Administrator
   wsl --install
   # Restart computer
   ```

2. **Install Ubuntu**
   ```powershell
   wsl --install -d Ubuntu
   # Set up username/password when prompted
   ```

3. **Install Theos in WSL**
   ```bash
   # Open Ubuntu terminal
   sudo apt update
   sudo apt install -y build-essential clang perl fakeroot git curl
   
   # Install Theos
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
   ```

### Build:

```bash
# Copy project to WSL
cp -r /mnt/c/Users/AmgadFahmy/Documents/Default\ Project/TetherUnlock ~/TetherUnlock

# Build
cd ~/TetherUnlock
make package FINALPACKAGE=1

# Copy .deb back to Windows
cp packages/*.deb /mnt/c/Users/AmgadFahmy/Documents/Default\ Project/
```

---

## Solution 3: Free Cloud Linux Server

Use a free VPS to build remotely.

### Free Options:
- [Oracle Cloud Always Free](https://cloud.oracle.com/free) - Always free tier
- [Google Cloud Free Tier](https://cloud.google.com/free) - e2-micro instance
- [AWS Free Tier](https://aws.amazon.com/free/) - t2.micro for 12 months

### Build on Oracle Cloud (Example):

1. **Create Free Account** and launch Ubuntu instance

2. **SSH into server**
   ```bash
   ssh ubuntu@YOUR_SERVER_IP
   ```

3. **Install build tools**
   ```bash
   sudo apt update
   sudo apt install -y build-essential clang perl fakeroot git curl
   ```

4. **Upload project** (from Windows PowerShell)
   ```powershell
   scp -r "C:\Users\AmgadFahmy\Documents\Default Project\TetherUnlock" ubuntu@YOUR_SERVER_IP:~/
   ```

5. **Build on server**
   ```bash
   ssh ubuntu@YOUR_SERVER_IP
   cd TetherUnlock
   
   # Install Theos
   git clone --recursive https://github.com/theos/theos.git ~/theos
   export THEOS=~/theos
   
   # Get SDK
   mkdir -p $THEOS/sdks
   wget -q https://github.com/theos/sdks/archive/master.tar.gz -O /tmp/sdks.tar.gz
   tar -xzf /tmp/sdks.tar.gz -C /tmp
   cp -r /tmp/sdks-master/iPhoneOS15.5.sdk $THEOS/sdks/
   
   # Build
   make package FINALPACKAGE=1
   ```

6. **Download .deb** (from Windows)
   ```powershell
   scp ubuntu@YOUR_SERVER_IP:~/TetherUnlock/packages/*.deb "C:\Users\AmgadFahmy\Documents\Default Project\"
   ```

---

## Installing on iPad (No Mac Needed)

### Method A: Using Filza (Already Installed!)

1. **Transfer .deb to iPad**
   - AirDrop from PC
   - iCloud Drive
   - Email attachment
   - Files app (from any cloud)

2. **Install with Filza**
   ```
   1. Open Filza
   2. Navigate to where .deb is saved
   3. Tap the .deb file
   4. Tap "Install"
   5. Wait for completion
   6. Respring device
   ```

3. **Configure TetherUnlock**
   ```
   1. Open Settings
   2. Scroll to "TetherUnlock"
   3. Configure your preferences
   4. Toggle "Enable TetherUnlock"
   ```

### Method B: Using Sileo/Zebra (If Installed)

1. Transfer .deb to iPad
2. Open in Sileo or Zebra
3. Tap "Install"
4. Respring

### Method C: SSH (If OpenSSH Installed)

```bash
# From PC, copy to iPad
scp packages/*.deb root@YOUR_IPAD_IP:/tmp/

# SSH into iPad
ssh root@YOUR_IPAD_IP

# Install
dpkg -i /tmp/com.tetherunlock.tweak_*.deb

# Respring
sbreload
```

---

## Quick Summary

| Method | Difficulty | Time | Cost |
|--------|-----------|------|------|
| **GitHub Actions** | Easy | 10 min | Free |
| **WSL2** | Medium | 30 min setup | Free |
| **Cloud VPS** | Medium | 20 min | Free |

**Recommended:** Use GitHub Actions - it's the easiest and completely free!

---

## What Filza CAN Do

✓ Install pre-built .deb files
✓ Browse/edit tweak files
✓ Edit preference plists
✓ Run basic commands (with terminal)
✓ Install from Sileo/Zebra repos

## What Filza CANNOT Do

✗ Compile Objective-C code
✗ Run Theos build system
✗ Create .deb packages from source

---

## Still Need Help?

If you get stuck:

1. **GitHub Actions fails?**
   - Check the "Actions" tab for error logs
   - Make sure all files uploaded correctly

2. **Can't install .deb?**
   - Make sure Xina15 jailbreak is active
   - Try different package manager
   - Check Filza has full disk access

3. **Tweak not working?**
   - Respring after install
   - Check Settings → TetherUnlock
   - Enable carrier unlock option
