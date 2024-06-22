#!/bin/bash

# Check if required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <public_key_file> <private_key_file>"
    exit 1
fi

PUBLIC_KEY_FILE=$1
PRIVATE_KEY_FILE=$2

# Import the public key
gpg --import "$PUBLIC_KEY_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to import public key from $PUBLIC_KEY_FILE"
    exit 1
fi

# Import the private key
gpg --import "$PRIVATE_KEY_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to import private key from $PRIVATE_KEY_FILE"
    exit 1
fi

# Get the key ID (use the first found key ID)
GPG_KEY=$(gpg --list-secret-keys --keyid-format LONG | grep '^sec' | awk '{print $2}' | cut -d'/' -f2 | head -n 1)

if [ -z "$GPG_KEY" ]; then
    echo "No GPG key found after import"
    exit 1
fi

# Configure Git with the GPG key
git config --global --unset gpg.format
git config --global user.signingkey "$GPG_KEY"
git config --global gpg.program $(which gpg)

# Ensure GPG_TTY is set in shell profile
if ! grep -q 'export GPG_TTY=$(tty)' ~/.bash_profile; then
    echo 'export GPG_TTY=$(tty)' >> ~/.bash_profile
fi

# Source the shell profile to apply changes
source ~/.bash_profile

# Test GPG configuration
echo "test" | gpg --clearsign
if [ $? -eq 0 ]; then
    echo "if you got a thing above, it works!"
else
    echo "GPG signing test failed"
    exit 1
fi

# Output the GPG key ID
echo "GPG key ID configured for Git: $GPG_KEY"