#!/usr/bin/env python3
"""Serve the phone-browser build to devices on your Wi-Fi."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket


def local_addresses() -> list[str]:
    addresses = set()
    try:
        for entry in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            addresses.add(entry[4][0])
    except OSError:
        pass

    # Select the default network interface without sending any packets.
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as connection:
            connection.connect(("192.0.2.1", 9))
            addresses.add(connection.getsockname()[0])
    except OSError:
        pass

    return sorted(address for address in addresses if not address.startswith("127."))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path(__file__).parent / "web")
    parser.add_argument("--port", type=int, default=8000)
    options = parser.parse_args()

    if not (options.directory / "index.html").is_file():
        parser.error(f"index.html is missing from {options.directory}")

    request_handler = partial(SimpleHTTPRequestHandler, directory=options.directory)
    with ThreadingHTTPServer(("0.0.0.0", options.port), request_handler) as server:
        print(f"On this computer, open http://127.0.0.1:{server.server_port}/")
        for address in local_addresses():
            print(f"On your phone, open http://{address}:{server.server_port}/")
        print("Use the same Wi-Fi on both devices. Press Ctrl+C to stop.", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
