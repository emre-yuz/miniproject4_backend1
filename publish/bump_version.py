import argparse
from pathlib import Path

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Write semantic-release version to VERSION file.")
    parser.add_argument("version", help="The new version string from semantic-release")
    args = parser.parse_args()

    version_file = Path(__file__).resolve().parents[1] / "VERSION"
    version_file.write_text(args.version)
