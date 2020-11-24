gpg_import() {
  echo "$GPG_KEY" | base64 -d | gpg --batch --import --
  export GPG_IMPORTED=true
}

gpg_sign() {
  [[ "$GPG_IMPORTED" == "true" ]] || gpg_import
  gpg --batch --yes --detach-sig --local-user "$GPG_USER" --armor "$1"
}

s3_upload() {
  aws s3 cp --acl public-read "$1" "$2"
}
