import os.path
import subprocess
import sys

ci_dir = os.path.abspath(os.path.dirname(sys.argv[0]))

def build_hsmodules(platform, configuration):
    output_dir = os.path.join(ci_dir, "__build__", platform, configuration)
    if not os.path.exists(output_dir):
        perform("hsbuild", "build", "-p", platform, "-c", configuration, "-v", "glib", "libgee", "json-glib", "vala")

def perform(*args):
    print " ".join(args)
    subprocess.check_call(args)


if __name__ == '__main__':
    build_hsmodules('x86_64', 'Debug')
    build_hsmodules('x86_64', 'Release')
    build_hsmodules('x86', 'Debug')
    build_hsmodules('x86', 'Release')
