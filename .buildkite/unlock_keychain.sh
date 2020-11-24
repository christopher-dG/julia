#!/usr/bin/env bash

KEYCHAIN="$HOME/xcode.keychain"
echo "Unlocking $DIR/xcode.keychain:"
security lock-keychain "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN" && echo "Unlocked!"
echo "Keychains on search path:"
security show-keychain-info "$KEYCHAIN"
KEYCHAIN_SEARCH_LIST="$(security list-keychains -d user | tr -d '\"' | uniq)"
if [[ "$KEYCHAIN_SEARCH_LIST" != *$KEYCHAIN* ]]; then
  echo "Adding $KEYCHAIN onto search list"
  security list-keychains -d user -s "$KEYCHAIN_SEARCH_LIST" "$KEYCHAIN"
fi
KEYCHAIN_SEARCH_LIST="$(security list-keychains -d system | tr -d '\"' | uniq)"
if [[ "$KEYCHAIN_SEARCH_LIST" != *$KEYCHAIN* ]]; then
  echo "Also adding it onto system search list to work around security bug"
  sudo security list-keychains -d system -s "$KEYCHAIN_SEARCH_LIST" "$KEYCHAIN"
fi
security list-keychains
echo "Searching for identities in $KEYCHAIN:"
security find-identity "$KEYCHAIN"
echo "Searching for identities in full search path:"
security find-identity
