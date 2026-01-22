# Windows Cleanup Utility

A comprehensive Windows cleanup batch script similar to Windows PC Manager that removes unnecessary files and optimizes system performance.

## 🚀 Features

This utility cleans the following system areas:

- **Windows Temp Files** - Removes temporary system files
- **User Temp Files** - Cleans user-specific temporary data
- **Prefetch Data** - Clears application prefetch cache
- **Windows Update Cache** - Removes downloaded update files
- **DNS Cache** - Flushes DNS resolver cache
- **Thumbnail Cache** - Clears thumbnail database
- **Error Reports** - Removes Windows Error Reporting files
- **Recent Files** - Clears recent documents history
- **Recycle Bin** - Empties the recycle bin completely
- **Delivery Optimization** - Cleans Windows Update delivery cache
- **Log Files** - Removes old system log files
- **Browser Cache** - Clears Internet Explorer/Edge cache

## 📋 Requirements

- Windows 7/8/10/11
- Administrator privileges (required)

## 🔧 How to Use

1. **Download** the `WindowsCleanup.bat` file
2. **Right-click** on the file
3. Select **"Run as administrator"**
4. Wait for the cleanup process to complete
5. Press any key to close the window

## ⚠️ Important Notes

- **Administrator rights are mandatory** - The script will not run without elevated privileges
- **Safe to use** - Only removes temporary and cache files, not personal data or system files
- **Disk space display** - Shows before/after free space on C: drive
- **Progress tracking** - Displays real-time progress for each cleanup step

## 📊 What You'll See

```
============================================
    Windows Cleanup Utility
    Optimizing System Performance
============================================

Starting cleanup process...

[INFO] Checking disk space before cleanup...
Before: XXXXXXXXX bytes free on C:

[1/12] Cleaning Windows Temp folder...
      Done!
[2/12] Cleaning User Temp folder...
      Done!
...
```

## 🛡️ Safety

This script is **safe** and only removes:
- Temporary files that Windows can regenerate
- Cache files that improve load times but aren't essential
- Files that are safe to delete according to Microsoft guidelines

It does **NOT** delete:
- Personal files or documents
- Installed programs
- System files required for Windows operation
- User settings or configurations

## 💡 When to Use

Run this utility when:
- Your system feels sluggish
- You're running low on disk space
- You want to perform routine maintenance
- After major Windows updates
- Before installing new software

## 🤝 Contributing

Feel free to suggest improvements or report issues!

## 📝 License

Free to use and modify for personal and commercial purposes.

---

**Created with ❤️ for Windows optimization**
