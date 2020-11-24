import subprocess
import tarfile

from io import BytesIO
from tempfile import mkdtemp

import requests

JULIA_VERSION = "1.5.3"


def handler(event, context):
    julia = install_julia()
    subprocess.run([julia, "-e", "using Pkg; Pkg.add(\"Documenter\")"])


def install_julia():
    majmin = ".".join(JULIA_VERSION.split(".")[:2])
    url = f"https://julialang-s3.julialang.org/bin/linux/x64/{majmin}/julia-{JULIA_VERSION}-linux-x86_64.tar.gz"
    resp = requests.get(url)
    resp.raise_for_status()
    root = mkdtemp()
    with tarfile.open(fileobj=BytesIO(resp.content), mode="r:gz") as f:
        f.extractall(root)
        return f"{root}/julia-{JULIA_VERSION}/bin/julia"
