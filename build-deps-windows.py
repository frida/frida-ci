from __future__ import print_function
import datetime
import glob
import os
import shutil
import subprocess
import sys
import tempfile

HSBUILD = r"C:\Program Files (x86)\HSBuild\bin\hsbuild.exe"
DEVENV = r"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.com"
PYTHON2 = r"C:\Program Files\Python27\python.exe"
GIT = r"C:\Program Files (x86)\Git\bin\git.exe"
SZIP = r"C:\Program Files\7-Zip\7z.exe"

V8_ARCH = {
    "x86": "ia32",
    "x86_64": "x64"
}
V8_BASE_SHARDS = 4

SDK_BLACKLISTED_EXTENSIONS = (
    "exe",
    "idb",
    "ilk",
    "pl",
    "pc",
)

SDK_BLACKLISTED_FILES = (
    "vala-0.28.lib",
    "vala-0.28.pdb",
    "valac-0.28.pdb",
    "glib-genmarshal.pdb",
    "gobject-query.pdb"
)


ci_dir = os.path.abspath(os.path.dirname(sys.argv[0]))
v8_dir = os.path.join(ci_dir, "v8")
output_dir = os.path.join(ci_dir, "__build__")

def check_environment():
    for tool in [HSBUILD, DEVENV, PYTHON2, GIT, SZIP]:
        if not os.path.exists(tool):
            print("ERROR: %s not found" % tool, file=sys.stderr)
            sys.exit(1)


#
# Building
#

def build_hsmodules(platform, configuration):
    vala_executable = os.path.join(ci_dir, "__build__", platform, configuration, "bin", "valac-0.28.exe")
    if not os.path.exists(vala_executable):
        perform(HSBUILD, "build", "-p", platform, "-c", configuration, "-v", "glib", "libgee", "json-glib", "vala")

def build_v8(platform, configuration, runtime):
    if not os.path.exists(v8_dir):
        perform(GIT, "clone", "git://github.com/frida/v8.git")
    headers = v8_headers(platform, configuration)
    base = []
    for i in range(V8_BASE_SHARDS):
        base.extend(v8_library("v8_base_%d" % i, platform, configuration, runtime))
    libbase = v8_library("v8_libbase", platform, configuration, runtime)
    libplatform = v8_library("v8_libplatform", platform, configuration, runtime)
    snapshot = v8_library("v8_snapshot", platform, configuration, runtime)
    if not os.path.exists(snapshot[0][1]):
        perform(GIT, "clean", "-xffd", cwd=v8_dir)
        perform(PYTHON2, os.path.join(v8_dir, "build", "gyp_v8"),
            "-Dtarget_arch=%s" % V8_ARCH[platform],
            "-Dv8_use_external_startup_data=0",
            "-Dv8_enable_i18n_support=0",
            "-Dv8_msvcrt=" + runtime)
        perform(DEVENV, os.path.join(v8_dir, "build", "all.sln"),
            "/build", configuration,
            "/project", "v8_snapshot",
            "/projectconfig", configuration)
        for src, dst in headers + base + libbase + libplatform + snapshot:
            copy(src, dst)

def v8_headers(platform, configuration):
    files = []
    output_include_dir = os.path.join(ci_dir, "__build__", platform, configuration, "include", "v8", "include")
    for header in glob.glob(os.path.join(v8_dir, "include", "*.h")):
        filename = os.path.basename(header)
        files.append((header, os.path.join(output_include_dir, filename)))
    for header in glob.glob(os.path.join(v8_dir, "include", "libplatform", "*.h")):
        filename = os.path.basename(header)
        files.append((header, os.path.join(output_include_dir, "libplatform", filename)))
    return files

def v8_library(name, platform, configuration, runtime):
    files = []
    if runtime == 'dynamic':
        lib_dir_name = "lib-dynamic"
    else:
        lib_dir_name = "lib"
    intermediate_lib_dir = os.path.join(v8_dir, "build", configuration)
    output_lib_dir = os.path.join(ci_dir, "__build__", platform, configuration, lib_dir_name)
    for suffix in ('lib', 'pdb'):
        filename = name + "." + suffix
        intermediate = os.path.join(intermediate_lib_dir, filename)
        output = os.path.join(output_lib_dir, filename)
        files.append((intermediate, output))
    return files


#
# Packaging
#

def package():
    now = datetime.datetime.now()

    toolchain_filename = now.strftime("toolchain-%Y%m%d-windows-i386.exe")
    toolchain_path = os.path.join(ci_dir, toolchain_filename)

    sdk_filename = now.strftime("sdk-%Y%m%d-windows-any.exe")
    sdk_path = os.path.join(ci_dir, sdk_filename)

    if os.path.exists(toolchain_path) and os.path.exists(sdk_path):
        return

    print("About to assemble:")
    print("\t* " + toolchain_filename)
    print("\t* " + sdk_filename)
    print()
    print("Determining what to include...")

    sdk_built_files = []
    for root, dirs, files in os.walk(output_dir):
        relpath = root[len(output_dir) + 1:]
        included_files = map(lambda name: os.path.join(relpath, name),
            filter(lambda filename: file_is_sdk_related(root, filename), files))
        sdk_built_files.extend(included_files)

    toolchain_files = []
    for root, dirs, files in os.walk(os.path.join(output_dir, 'x86', 'Release')):
        relpath = root[len(output_dir) + 1:]
        included_files = map(lambda name: os.path.join(relpath, name),
            filter(lambda filename: file_is_vala_toolchain_related(root, filename), files))
        toolchain_files.extend(included_files)

    sdk_built_files.sort()
    toolchain_files.sort()

    print("Copying files...")
    tempdir = tempfile.mkdtemp(prefix="frida-package")
    copy_files(output_dir, sdk_built_files, os.path.join(tempdir, "sdk-windows"), transform_sdk_dest)
    copy_files(output_dir, toolchain_files, os.path.join(tempdir, "toolchain-windows"), transform_toolchain_dest)

    print("Compressing...")
    prevdir = os.getcwd()
    os.chdir(tempdir)

    perform(SZIP, "a", "-mx9", "-sfx7zCon.sfx", "-r", toolchain_path, "toolchain-windows")

    perform(SZIP, "a", "-mx9", "-sfx7zCon.sfx", "-r", sdk_path, "sdk-windows")

    os.chdir(prevdir)
    shutil.rmtree(tempdir)

    print("All done.")

def file_is_sdk_related(directory, filename):
    base, ext = os.path.splitext(filename)
    ext = ext[1:]
    if ext in SDK_BLACKLISTED_EXTENSIONS:
        return False
    elif ext == "h" and base.startswith("vala"):
        return False
    elif ext in ("vapi", "deps"):
        if base == "libvala-0.28":
            return False
        return not directory.endswith("share\\vala-0.28\\vapi")
    return filename not in SDK_BLACKLISTED_FILES

def file_is_vala_toolchain_related(directory, filename):
    base, ext = os.path.splitext(filename)
    ext = ext[1:]
    if ext in ('vapi', 'deps'):
        return directory.endswith("share\\vala-0.28\\vapi")
    return filename == "valac-0.28.exe"

def transform_identity(srcfile):
    return srcfile

def transform_sdk_dest(srcfile):
    dstfile = srcfile.replace("x86_64\\", "x64-")
    dstfile = dstfile.replace("x86\\", "Win32-")
    return dstfile

def transform_toolchain_dest(srcfile):
    return srcfile[srcfile.index("\\Release\\") + 9:]


#
# Utilities
#

def perform(*args, **kwargs):
    print(" ".join(args))
    subprocess.check_call(args, **kwargs)

def copy(src, dst):
    dst_dir = os.path.dirname(dst)
    if not os.path.isdir(dst_dir):
        os.makedirs(dst_dir)
    shutil.copyfile(src, dst)

def copy_files(fromdir, files, todir, transformdest=transform_identity):
    for file in files:
        src = os.path.join(fromdir, file)
        dst = os.path.join(todir, transformdest(file))
        dstdir = os.path.dirname(dst)
        if not os.path.isdir(dstdir):
            os.makedirs(dstdir)
        shutil.copyfile(src, dst)


if __name__ == '__main__':
    check_environment()
    for platform in ["x86_64", "x86"]:
        for configuration in ["Debug", "Release"]:
            build_hsmodules(platform, configuration)
            for runtime in ['static', 'dynamic']:
                build_v8(platform, configuration, runtime)
    package()
