# Quick Start - No Mac Required

## ⚡ Fastest Method: GitHub Actions (5 minutes)

### Step 1: Upload to GitHub
1. Go to https://github.com/new
2. Create repository named `TetherUnlock` (Public)
3. Upload ALL files from the TetherUnlock folder

### Step 2: Build
1. Click "Actions" tab
2. Click "Build TetherUnlock"
3. Click "Run workflow" → "Run workflow"
4. Wait ~5 minutes

### Step 3: Download
1. Click the completed run
2. Download "TetherUnlock-deb" artifact
3. Extract to get your .deb file

---

## 📱 Install on iPad (Using Filza)

### Transfer .deb to iPad:
- **AirDrop** from PC
- **iCloud Drive** 
- **Email** yourself the file
- **Files app** from any cloud storage

### Install:
1. Open **Filza**
2. Navigate to where .deb is saved
3. **Tap** the .deb file
4. Tap **"Install"**
5. Wait for completion
6. **Respring** when prompted

### Configure:
1. Open **Settings**
2. Scroll to **TetherUnlock**
3. Enable and configure options
4. Toggle **"Enable TetherUnlock"** ON

---

## 🔧 VPN Sharing

After installing:

1. Connect to your VPN on iPad
2. Open Settings → TetherUnlock
3. Enable **"Share VPN Connection"**
4. All tethered devices now use your VPN!

Supported: IKEv2, IPSec, OpenVPN

---

## ❓ Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't find .deb in Filza | Check Downloads folder or use Filza search |
| Install fails | Respring first, try again |
| Tweak not showing in Settings | Respring device |
| VPN not sharing | Connect VPN first, then enable sharing |
| No internet on tethered device | Enable Carrier Unlock in settings |

---

## 📋 What You Get

**TetherUnlock Features:**
- ✅ Wi-Fi Hotspot (WPA2/WPA3)
- ✅ USB Tethering  
- ✅ Bluetooth DUN
- ✅ Carrier Unlock
- ✅ VPN Sharing (NEW!)

**Requirements:**
- iPadOS 15.0-15.4.1 ✓ (you have this)
- Xina15 Jailbreak ✓ (you have this)
- Filza ✓ (you have this)

---

## 🆘 Need Help?

**GitHub Actions not working?**
- Make sure all files uploaded
- Check Actions tab for errors
- Try again (sometimes GitHub is slow)

**Installation issues?**
- Ensure Xina15 is active (not just bootloop)
- Check storage space (need ~10MB)
- Try Sileo/Zebra instead of Filza

**Tethering not working?**
- Enable Carrier Unlock
- Check cellular data is active
- Try different tethering method (Wi-Fi/USB/BT)
- Respring and try again

---

## 📁 Files Summary

| File | Purpose |
|------|---------|
| `TetherUnlock.deb` | Main tweak package (build this first) |
| `install_tetherunlock.sh` | Optional: Terminal installer for Filza |
| `BUILD_WITHOUT_MAC.md` | Detailed build instructions |
| `README.md` | Full documentation |

---

## ✅ Checklist

- [ ] Upload to GitHub
- [ ] Run GitHub Actions workflow
- [ ] Download .deb artifact
- [ ] Transfer .deb to iPad
- [ ] Install via Filza
- [ ] Respring device
- [ ] Configure in Settings
- [ ] Enable TetherUnlock
- [ ] Test tethering!
