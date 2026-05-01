#!/bin/bash

echo "Waiting for the login keyring to unlock..."

while true; do
    # Using 2>&1 to capture any potential errors in the output for debugging
    # Notice the corrected 'Secret.Collection' with a capital S
    STATUS=$(busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked 2>&1)
    
    echo "Current status: $STATUS"
    
    if [[ "$STATUS" == "b false" ]]; then
        echo "Keyring unlocked! Moving to next command."
        exit 0
    fi
    
    # Wait 2 seconds before checking again
    sleep 2
done
