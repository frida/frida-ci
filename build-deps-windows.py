import codecs
import datetime
import glob
import multiprocessing
import os
import platform
import shutil
import subprocess
import sys
import tempfile

HSBUILD_DIR = r"C:\Program Files (x86)\HSBuild"
MSVS = r"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community"
WIN10_SDK_DIR = r"C:\Program Files (x86)\Windows Kits\10"
WIN10_SDK_VERSION = "10.0.17134.0"
WINXP_SDK_DIR = r"C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A"
MESON = r"C:\Program Files\Python 3.6\Scripts\meson.bat"
PYTHON2 = r"C:\Program Files\Python 2.7\python.exe"
GIT = r"C:\Program Files\Git\bin\git.exe"
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
    "vala-0.42.lib",
    "vala-0.42.pdb",
    "valac-0.42.pdb",
    "glib-genmarshal.pdb",
    "gobject-query.pdb"
)

MESON_MSVS_FIXUPS = (
    ("<CharacterSet>MultiByte</CharacterSet>", "<CharacterSet>Unicode</CharacterSet>"),
    ("<PlatformToolset>v141</PlatformToolset>", "<PlatformToolset>v141_xp</PlatformToolset>"),
    ("<RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>", "<RuntimeLibrary>MultiThreaded</RuntimeLibrary>"),
    ("<RuntimeLibrary>MultiThreadedDebugDLL</RuntimeLibrary>", "<RuntimeLibrary>MultiThreadedDebug</RuntimeLibrary>"),
)


ci_dir = os.path.abspath(os.path.dirname(sys.argv[0]))
v8_dir = os.path.join(ci_dir, "v8")
output_dir = os.path.join(ci_dir, "__build__")

msvs_devenv = MSVS + r"\Common7\IDE\devenv.com"
msvs_multi_core_limit = multiprocessing.cpu_count() / 2
cached_meson_params = {}
cached_msvc_dir = None

build_platform = 'x86_64' if platform.machine().endswith("64") else 'x86'


def check_environment():
    for tool in [HSBUILD_DIR, MSVS, WIN10_SDK_DIR, WINXP_SDK_DIR, MESON, PYTHON2, GIT, SZIP]:
        if not os.path.exists(tool):
            print("ERROR: %s not found" % tool, file=sys.stderr)
            sys.exit(1)

def get_msvc_tool_dir():
    global cached_msvc_dir
    if cached_msvc_dir is None:
        version = sorted(glob.glob(os.path.join(MSVS, "VC", "Tools", "MSVC", "*.*.*")))[-1]
        cached_msvc_dir = os.path.join(MSVS, "VC", "Tools", "MSVC", version)
    return cached_msvc_dir

def platform_to_msvc(platform):
    return 'x64' if platform == 'x86_64' else 'x86'


#
# Building
#

def build_hs_modules(platform, configuration):
    hsbuild_executable = os.path.join(HSBUILD_DIR, "bin", "hsbuild.exe")
    vala_executable = os.path.join(ci_dir, "__build__", platform, configuration, "bin", "valac-0.42.exe")
    if not os.path.exists(vala_executable):
        perform(hsbuild_executable, "build", "-p", platform, "-c", configuration, "-v", "glib", "libgee", "json-glib", "vala")

def build_v8(platform, configuration, runtime):
    if not os.path.exists(v8_dir):
        perform(GIT, "clone", "git://github.com/frida/v8.git")
    headers = v8_headers(platform, configuration)
    base = []
    for i in range(V8_BASE_SHARDS):
        base.extend(v8_library("v8_base_%d" % i, platform, configuration, runtime))
    libbase = v8_library("v8_libbase", platform, configuration, runtime)
    libplatform = v8_library("v8_libplatform", platform, configuration, runtime)
    libsampler = v8_library("v8_libsampler", platform, configuration, runtime)
    snapshot = v8_library("v8_snapshot", platform, configuration, runtime)
    if not os.path.exists(snapshot[0][1]):
        perform(GIT, "clean", "-xffd", cwd=v8_dir)
        os.environ['DEPOT_TOOLS_WIN_TOOLCHAIN'] = '0'
        os.environ['GYP_MSVS_VERSION'] = '2017'
        os.environ['GYP_GENERATORS'] = 'msvs'
        perform(PYTHON2, os.path.join(v8_dir, "gypfiles", "gyp_v8"),
            "-Dtarget_arch=%s" % V8_ARCH[platform],
            "-Dv8_use_external_startup_data=0",
            "-Dv8_enable_i18n_support=0",
            "-Dmsvs_multi_core_limit=%d" % msvs_multi_core_limit,
            "-Dforce_dynamic_crt=" + str(int(runtime == 'dynamic')))
        perform(msvs_devenv, os.path.join(v8_dir, "gypfiles", "all.sln"),
            "/build", configuration,
            "/project", "v8_snapshot",
            "/projectconfig", configuration)
        for src, dst in headers + base + libbase + libplatform + libsampler + snapshot:
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
    intermediate_lib_dir = os.path.join(v8_dir, "gypfiles", configuration)
    output_lib_dir = os.path.join(ci_dir, "__build__", platform, configuration, lib_dir_name)
    for suffix in ('lib',):
        filename = name + "." + suffix
        intermediate = os.path.join(intermediate_lib_dir, filename)
        output = os.path.join(output_lib_dir, filename)
        files.append((intermediate, output))
    return files

def build_meson_modules(platform, configuration):
    for name in ["glib-schannel"]:
        build_meson_module(name, platform, configuration)

def build_meson_module(name, platform, configuration):
    env_dir, shell_env, cross_config_path = get_meson_params(platform, configuration)

    build_dir = os.path.join(env_dir, name)
    build_type = 'minsize' if configuration == 'Release' else 'debug'
    prefix = os.path.join(ci_dir, "__build__", platform, configuration)

    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)

    perform(
        MESON,
        build_dir,
        "--buildtype", build_type,
        "--prefix", prefix,
        "--backend", "vs2017",
        "--cross-file", cross_config_path,
        cwd=os.path.join(ci_dir, name),
        env=shell_env
    )

    fixup_meson_projects(build_dir)

def fixup_meson_projects(build_dir):
    for project_path in glob.glob(os.path.join(build_dir, "**", "*.vcxproj"), recursive=True):
        with codecs.open(project_path, "rb", 'utf-8') as f:
            project_xml = f.read()

        for (old, new) in MESON_MSVS_FIXUPS:
            project_xml = project_xml.replace(old, new)

        with codecs.open(project_path, "wb", 'utf-8') as f:
            f.write(project_xml)

def get_meson_params(platform, configuration):
    global cached_meson_params

    identifier = ":".join([platform, configuration])

    params = cached_meson_params.get(identifier, None)
    if params is None:
        params = generate_meson_params(platform, configuration)
        cached_meson_params[identifier] = params

    return params

def generate_meson_params(platform, configuration):
    host_env = generate_meson_env(platform, configuration)
    if platform == build_platform:
        build_env = host_env
    else:
        build_env = generate_meson_env(build_platform, configuration)
    return (host_env.path, build_env.shell_env, host_env.cross_config_path)

def generate_meson_env(platform, configuration):
    env_dir = os.path.join(output_dir, platform, configuration, "tmp")
    if not os.path.exists(env_dir):
        os.makedirs(env_dir)

    vc_dir = os.path.join(MSVS, "VC")

    msvc_platform = platform_to_msvc(platform)
    msvc_dir = get_msvc_tool_dir()
    msvc_bin_dir = os.path.join(msvc_dir, "bin", "Host" + platform_to_msvc(build_platform), msvc_platform)

    cl_path = os.path.join(msvc_bin_dir, "cl.exe")
    lib_path = os.path.join(msvc_bin_dir, "lib.exe")
    link_path = os.path.join(msvc_bin_dir, "link.exe")

    pkgconfig_path = os.path.join(HSBUILD_DIR, "tools", "bin", "pkg-config.exe")
    pkgconfig_lib_dir = os.path.join(ci_dir, "__build__", platform, configuration, "lib", "pkgconfig")

    exe_path = ";".join([
        env_dir,
        msvc_bin_dir,
    ])

    include_path = ";".join([
        os.path.join(msvc_dir, "include"),
        os.path.join(msvc_dir, "atlmfc", "include"),
        os.path.join(vc_dir, "Auxiliary", "VS", "include"),
        os.path.join(WIN10_SDK_DIR, "Include", WIN10_SDK_VERSION, "ucrt"),
        os.path.join(WINXP_SDK_DIR, "Include"),
    ])

    if platform == 'x86':
        winxp_lib_dir = os.path.join(WINXP_SDK_DIR, "Lib")
    else:
        winxp_lib_dir = os.path.join(WINXP_SDK_DIR, "Lib", msvc_platform)
    library_path = ";".join([
        os.path.join(msvc_dir, "lib", msvc_platform),
        os.path.join(msvc_dir, "atlmfc", "lib", msvc_platform),
        os.path.join(vc_dir, "Auxiliary", "VS", "lib", msvc_platform),
        os.path.join(WIN10_SDK_DIR, "Lib", WIN10_SDK_VERSION, "ucrt", msvc_platform),
        winxp_lib_dir,
    ])

    cl_wrapper_path = os.path.join(env_dir, "cl.bat")
    with codecs.open(cl_wrapper_path, "w", 'utf-8') as f:
        f.write("""@ECHO OFF
SETLOCAL EnableExtensions
SET PATH={exe_path};%PATH%
SET INCLUDE={include_path}
SET LIB={library_path}
SET _res=0
"{cl}" %* || SET _res=1
ENDLOCAL & SET _res=%_res%
EXIT /B %_res%""".format(
        cl=cl_path,
        exe_path=exe_path,
        include_path=include_path,
        library_path=library_path,
    ))

    pkgconfig_wrapper_path = os.path.join(env_dir, "pkg-config.bat")
    with codecs.open(pkgconfig_wrapper_path, "w", 'utf-8') as f:
        f.write("""@ECHO OFF
SETLOCAL EnableExtensions
SET _res=0
SET PKG_CONFIG_PATH={pkgconfig_lib_dir}
"{pkgconfig_path}" --static %*
ENDLOCAL & SET _res=%_res%
EXIT /B %_res%""".format(pkgconfig_path=pkgconfig_path, pkgconfig_lib_dir=pkgconfig_lib_dir))

    cross_config_path = os.path.join(env_dir, "config.txt")
    with codecs.open(cross_config_path, "w", 'utf-8') as f:
        f.write("""\
[binaries]
c = '{cl}'
cpp = '{cl}'
ar = '{lib}'
pkgconfig = '{pkgconfig}'

[properties]
c_args = []
cpp_args = []

[host_machine]
system = 'windows'
cpu_family = '{cpu_family}'
cpu = '{cpu}'
endian = 'little'
""".format(
        cl=escape_path(cl_wrapper_path),
        lib=escape_path(lib_path),
        pkgconfig=escape_path(pkgconfig_wrapper_path),
        cpu_family=platform,
        cpu=platform
    ))

    shell_env = {}
    shell_env.update(os.environ)
    shell_env["PATH"] = exe_path + ";" + shell_env["PATH"]
    shell_env["INCLUDE"] = include_path
    shell_env["LIB"] = library_path

    return MesonEnv(env_dir, shell_env, cross_config_path)

class MesonEnv(object):
    def __init__(self, path, shell_env, cross_config_path):
        self.path = path
        self.shell_env = shell_env
        self.cross_config_path = cross_config_path


#
# Packaging
#

def package():
    now = datetime.datetime.now()

    toolchain_filename = now.strftime("toolchain-%Y%m%d-windows-x86.exe")
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
        if base == "libvala-0.42":
            return False
        return not directory.endswith("share\\vala-0.42\\vapi")
    return filename not in SDK_BLACKLISTED_FILES

def file_is_vala_toolchain_related(directory, filename):
    base, ext = os.path.splitext(filename)
    ext = ext[1:]
    if ext in ('vapi', 'deps'):
        return directory.endswith("share\\vala-0.42\\vapi")
    return filename == "valac-0.42.exe"

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

def escape_path(path):
    return path.replace("\\", "\\\\")

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
            build_hs_modules(platform, configuration)
            for runtime in ['static', 'dynamic']:
                build_v8(platform, configuration, runtime)
            build_meson_modules(platform, configuration)
    package()
