import glob
import os
import shutil
import subprocess
import sys

DEVENV = r"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.com"
PYTHON2 = r"C:\Program Files\Python27\python.exe"
GIT = r"C:\Program Files (x86)\Git\bin\git.exe"

V8_ARCH = {'x86': 'ia32', 'x86_64': 'x64'}


ci_dir = os.path.abspath(os.path.dirname(sys.argv[0]))
v8_dir = os.path.join(ci_dir, "v8")

def build_hsmodules(platform, configuration):
    vala_executable = os.path.join(ci_dir, "__build__", platform, configuration, "bin", "valac-0.14.exe")
    if not os.path.exists(vala_executable):
        perform("hsbuild", "build", "-p", platform, "-c", configuration, "-v", "glib", "libgee", "json-glib", "vala")

def build_v8(platform, configuration, runtime):
    if not os.path.exists(v8_dir):
        perform(GIT, "clone", "git@github.com:frida/v8.git")
    headers = v8_headers(platform, configuration)
    base = v8_library("v8_base.%(arch)s", platform, configuration, runtime)
    snapshot = v8_library("v8_snapshot", platform, configuration, runtime)
    if not os.path.exists(snapshot[0][1]):
        perform(GIT, "clean", "-xffd", cwd=v8_dir)
        perform(PYTHON2, os.path.join(v8_dir, "build", "gyp_v8"),
            "-Dtarget_arch=%s" % V8_ARCH[platform],
            "-Dv8_enable_i18n_support=0",
            "-Dv8_msvcrt=" + runtime)
        perform(DEVENV, "/build", configuration, os.path.join(v8_dir, "build", "all.sln"))
        for src, dst in headers + base + snapshot:
            shutil.copyfile(src, dst)

def v8_headers(platform, configuration):
    files = []
    output_include_dir = os.path.join(ci_dir, "__build__", platform, configuration, "include")
    for header in glob.glob(os.path.join(v8_dir, "include", "*.h")):
        filename = os.path.basename(header)
        files.append((header, os.path.join(output_include_dir, filename)))
    return files

def v8_library(name_template, platform, configuration, runtime):
    files = []
    name = name_template % {'arch': V8_ARCH[platform]}
    if runtime == 'dynamic':
        lib_dir_name = "lib-dynamic"
    else:
        lib_dir_name = "lib"
    intermediate_lib_dir = os.path.join(v8_dir, "build", configuration, "lib")
    output_lib_dir = os.path.join(ci_dir, "__build__", platform, configuration, lib_dir_name)
    for suffix in ('lib', 'pdb'):
        filename = name + "." + suffix
        intermediate = os.path.join(intermediate_lib_dir, filename)
        output = os.path.join(output_lib_dir, filename)
        files.append((intermediate, output))
    return files

def perform(*args, **kwargs):
    print " ".join(args)
    subprocess.check_call(args, **kwargs)


if __name__ == '__main__':
    for platform in ['x86_64', 'x86']:
        for configuration in ['Debug', 'Release']:
            build_hsmodules(platform, configuration)
            for runtime in ['static', 'dynamic']:
                build_v8(platform, configuration, runtime)
