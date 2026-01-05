#!/usr/bin/env python3
"""
Chat Application Build and Push Script (Python Version)
Alternative to bash - better error handling and cross-platform support

Usage:
    python build_and_push.py [--version v1.0.0] [--no-push]
    ./build_and_push.py v1.2.0
"""

import argparse
import subprocess
import sys
import os
from pathlib import Path
import shutil

class ChatAppBuilder:
    def __init__(self):
        self.registry = "localhost:5001"
        self.image_name = "chat-app"
        self.project_root = Path(__file__).parent.parent.parent
        self.app_dir = self.project_root / "Flask-SocketIO-Chat"

    def run_command(self, cmd, cwd=None, check=True):
        """Run shell command with proper error handling"""
        try:
            print(f"🔧 Running: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                cwd=cwd or self.project_root,
                capture_output=True,
                text=True,
                check=check
            )
            if result.stdout:
                print(result.stdout)
            return result
        except subprocess.CalledProcessError as e:
            print(f"❌ Command failed: {' '.join(cmd)}")
            print(f"Error: {e.stderr}")
            if check:
                sys.exit(1)
            return e

    def check_prerequisites(self):
        """Check if Docker is available"""
        print("🔍 Checking prerequisites...")
        try:
            self.run_command(["docker", "--version"])
            print("✅ Docker is available")
        except:
            print("❌ Docker is not installed or not running")
            sys.exit(1)

    def build_image(self, version):
        """Build Docker image"""
        full_image = f"{self.registry}/{self.image_name}:{version}"
        print(f"🔨 Building image: {full_image}")

        dockerfile = self.app_dir / "Dockerfile"
        if not dockerfile.exists():
            print(f"❌ Dockerfile not found: {dockerfile}")
            sys.exit(1)

        self.run_command([
            "docker", "build",
            "-t", full_image,
            "-f", str(dockerfile),
            str(self.app_dir)
        ])

        print(f"✅ Build complete: {full_image}")
        return full_image

    def push_image(self, image):
        """Push image to registry"""
        print(f"📤 Pushing image: {image}")
        self.run_command(["docker", "push", image])
        print(f"✅ Push complete: {image}")

    def tag_latest(self, versioned_image):
        """Tag as latest if not already"""
        if ":latest" in versioned_image:
            return

        latest_image = versioned_image.replace(f":{versioned_image.split(':')[-1]}", ":latest")
        print(f"🏷️  Tagging as latest: {latest_image}")

        self.run_command(["docker", "tag", versioned_image, latest_image])
        self.run_command(["docker", "push", latest_image])
        print(f"✅ Latest tag pushed: {latest_image}")

    def main(self):
        parser = argparse.ArgumentParser(description="Build and push chat application")
        parser.add_argument("version", nargs="?", default="latest",
                          help="Version tag for the image")
        parser.add_argument("--no-push", action="store_true",
                          help="Build only, don't push")
        parser.add_argument("--registry", default=self.registry,
                          help="Container registry URL")

        args = parser.parse_args()
        self.registry = args.registry

        print("🚀 Chat Application Builder (Python)")
        print(f"Version: {args.version}")
        print(f"Registry: {self.registry}")
        print("-" * 40)

        self.check_prerequisites()

        image = self.build_image(args.version)

        if not args.no_push:
            self.push_image(image)
            if args.version != "latest":
                self.tag_latest(image)

        print("🎉 Build process complete!")
        print(f"Image: {image}")

if __name__ == "__main__":
    builder = ChatAppBuilder()
    builder.main()
