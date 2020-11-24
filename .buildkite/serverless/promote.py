import os
import subprocess

from base64 import b64decode
from tempfile import mkdtemp

import boto3

from gnupg import GPG

S3 = boto3.client("s3")
SM = boto3.client("secretsmanager")
os.environ["GNUPGHOME"] = mkdtemp()
gpg = GPG(use_agent=False)


def handler(event, context):
    import_gpg_key()
    for record in event["Records"]:
        source = {
            "Bucket": record["s3"]["bucket"]["name"],
            "Key": record["s3"]["object"]["key"],
        }
        if source["Key"].split("/")[0] not in ["bin", "src"]:
            continue
        resp = S3.get_object(**source)
        sig = sign(resp["Body"])
        for path in destination_paths(resp["Metadata"]):
            put_file_and_sig(source, sig, path)


def import_gpg_key():
    # I don't really know why I need to run this, but it breaks otherwise.
    proc = subprocess.run(["gpg-agent", "--daemon"])
    if proc.returncode:
        # If the host is warm, the key is already imported.
        return
    resp = SM.get_secret_value(SecretId="buildkite.gpg_key")
    key = b64decode(resp["SecretString"])
    result = gpg.import_keys(key)
    assert result.sec_imported == 1


def sign(body):
    return gpg.sign_file(body, clearsign=True, detach=True).data


def destination_paths(metadata):
    f = src_paths if metadata.get("srcdist") else bin_paths
    return f(metadata)


def src_paths(metadata):
    srcdist = metadata["srcdist"]
    if srcdist == "light":
        srcdist = ""
    else:
        srcdist = f"-{srcdist}"
    version = metadata["version"]
    commit = metadata["commit"]
    return [
        f"src/{version}/julia-{version}-{commit}{srcdist}.tar.gz",
        f"src/{version}/julia-latest{srcdist}.tar.gz",
        f"src/julia-latest{srcdist}.tar.gz",
    ]


def bin_paths(metadata):
    os = metadata["os"]
    arch = metadata["arch"]
    version = metadata["version"]
    filename = metadata["filename"]
    name, ext = filename.split(".", 1)
    commit, osarch = name.split("-")[1:3]
    if arch == "x86_64":
        arch = "x64"
    elif arch == "i636":
        arch = "x86"
    return [
        f"bin/{os}/{arch}/{version}/julia-{commit}-{osarch}.{ext}",
        f"bin/{os}/{arch}/{version}/julia-latest-{osarch}.{ext}",
        f"bin/{os}/{arch}/julia-latest-{osarch}.{ext}",
    ]


def put_file_and_sig(source, sig, path):
    kwargs = {"ACL": "public-read", "Bucket": os.environ["NIGHTLY_BUCKET"]}
    S3.copy_object(Key=path, CopySource=source, **kwargs)
    S3.put_object(Key=f"{path}.asc", Body=sig, **kwargs)
