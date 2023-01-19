#!/usr/bin/env bash

# Find all the Proxmox kernels on the system
kernels=$(dpkg --list | grep 'pve-kernel-.*-pve' | awk '{print $2}' | sort -V)
# List of kernels that will be removed (adds them as the script goes on)
kernels_to_remove=""
# Check the /boot used
printf "[*] Boot disk space used is "
# Warn user when the /boot is critically full
if [[ "${boot_info[4]}" -ge "$boot_critical_percent" ]]; then
    printf "critically full "
# Tell them if it is at an acceptable percentage
else
    printf "healthy "
fi
# Display percentage used and available space left
printf "at ${boot_info[4]}%% capacity (${boot_info[3]} free)\n"
printf "[-] Searching for old Proxmox kernels on your system...\n"
# For each kernel that was found via dpkg
for kernel in $kernels; do
    # If the kernel listed from dpkg is our current then break
    if [ "$(echo $kernel | grep $current_kernel)" ]; then
        break
    # Add kernel to the list of removal since it is old
    else
        printf "[*] \"$kernel\" has been added to the kernel remove list\n"
        kernels_to_remove+=" $kernel"
    fi
done
printf "[-] Proxmox kernel search complete!\n"
# If there are no kernels to be removed then exit
if [[ "$kernels_to_remove" != *"pve"* ]]; then
    printf "[!] It appears there are no old Proxmox kernels on your system 😊\n"
    printf "[-] Good bye!\n"
# Kernels found in removal list
else
    # Check if force removal was passed
    if [ $force_purge == true ]; then
        REPLY="y"
    # Ask the user if they want to remove the selected kernels found
    else
        read -p "[!] Would you like to remove the $(echo $kernels_to_remove | awk '{print NF}') selected Proxmox kernels listed above? [y/N]: " -n 1 -r
        printf "\n"
    fi
    # User wishes to remove the kernels
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        printf "[*] Removing $(echo $kernels_to_remove | awk '{print NF}') old Proxmox kernels..."
        # Purge the old kernels via apt and suppress output
        /usr/bin/apt purge -y $kernels_to_remove >/dev/null 2>&1
        printf "DONE!\n"
        printf "[*] Updating GRUB..."
        # Update grub after kernels are removed, suppress output
        /usr/sbin/update-grub >/dev/null 2>&1
        printf "DONE!\n"
        # Script finished successfully
        printf "[-] Cleaning finished successfully\n"
    # User wishes to not remove the kernels above, exit
    else
        printf "\nExiting...\n"
    fi
fi
