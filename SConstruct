#!python
import os, subprocess

opts = Variables([], ARGUMENTS)

# Gets the standard flags CC, CCX, etc.
env = DefaultEnvironment()

# Define our options
opts.Add(EnumVariable('target', "Compilation target", 'debug', ['d', 'debug', 'r', 'release']))
opts.Add(EnumVariable('platform', "Compilation platform", 'linux', ['', 'windows', 'x11', 'linux', 'osx']))
opts.Add(EnumVariable('p', "Compilation target, alias for 'platform'", '', ['', 'windows', 'x11', 'linux', 'osx']))
opts.Add(BoolVariable('use_llvm', "Use the LLVM / Clang compiler", 'no'))
opts.Add(PathVariable('target_path', 'The path where the lib should be installed.', 'survival/bin/'))
opts.Add(PathVariable('target_name', 'The library name.', 'libgdlibrary', PathVariable.PathAccept))

# Local dependency paths, adapt them to your setup
godot_headers_path = "godot-cpp/godot_headers/"
cpp_bindings_path = "godot-cpp/"
cpp_library = "libgodot-cpp"

# only support 64 at this time..
bits = 64

# Updates the environment with the option variables.
opts.Update(env)

# Process some arguments
if env['use_llvm']:
    env['CC'] = 'clang'
    env['CXX'] = 'clang++'

if env['p'] != '':
    env['platform'] = env['p']

if env['platform'] == '':
    print("No valid target platform selected.")
    quit()

# For the reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# Check our platform specifics
if env['platform'] == "osx":
    env['target_path'] += 'osx/'
    cpp_library += '.osx'
    if env['target'] in ('debug', 'd'):
        env.Append(CCFLAGS=['-g', '-O2', '-arch', 'x86_64'])
        env.Append(LINKFLAGS=['-arch', 'x86_64'])
    else:
        env.Append(CCFLAGS=['-g', '-O3', '-arch', 'x86_64'])
        env.Append(LINKFLAGS=['-arch', 'x86_64'])

elif env['platform'] in ('x11', 'linux'):
    env['target_path'] += 'x11/'
    cpp_library += '.linux'
    if env['target'] in ('debug', 'd'):
        env.Append(CCFLAGS=['-fPIC', '-g3', '-Og'])
        env.Append(CXXFLAGS=['-std=c++17'])
    else:
        env.Append(CCFLAGS=['-fPIC', '-g', '-O3'])
        env.Append(CXXFLAGS=['-std=c++17'])

elif env['platform'] == "windows":
    env['target_path'] += 'win64/'
    cpp_library += '.windows'
    # This makes sure to keep the session environment variables on windows,
    # that way you can run scons in a vs 2017 prompt and it will find all the required tools
    env.Append(ENV=os.environ)

    env.Append(CPPDEFINES=['WIN32', '_WIN32', '_WINDOWS', '_CRT_SECURE_NO_WARNINGS'])
    env.Append(CCFLAGS=['-W3', '-GR'])
    if env['target'] in ('debug', 'd'):
        env.Append(CPPDEFINES=['_DEBUG'])
        env.Append(CCFLAGS=['-EHsc', '-MDd', '-ZI'])
        env.Append(LINKFLAGS=['-DEBUG'])
    else:
        env.Append(CPPDEFINES=['NDEBUG'])
        env.Append(CCFLAGS=['-O2', '-EHsc', '-MD'])

if env['target'] in ('debug', 'd'):
    cpp_library += '.debug'
else:
    cpp_library += '.release'

cpp_library += '.' + str(bits)

fastnoisesimd_path = "FastNoiseSIMD/FastNoiseSIMD/"
fastnoisesimd_env = DefaultEnvironment()
fastnoisesimd_env.Append(CXXFLAGS=['-std=c++11'])
fastnoisesimd_library = 'libfast_noise_simd.linux.64'
fastnoisesimd_target = fastnoisesimd_path + 'bin/' + fastnoisesimd_library + fastnoisesimd_env['LIBSUFFIX']
fastnoisesimd_sources = [
    fastnoisesimd_path + 'FastNoiseSIMD.cpp',
    fastnoisesimd_path + 'FastNoiseSIMD_neon.cpp',
    fastnoisesimd_path + 'FastNoiseSIMD_internal.cpp',
    fastnoisesimd_env.Object(fastnoisesimd_path + 'FastNoiseSIMD_sse2.cpp', CXXFLAGS='-msse2'),
    fastnoisesimd_env.Object(fastnoisesimd_path + 'FastNoiseSIMD_sse41.cpp', CXXFLAGS='-msse4.1'),
    fastnoisesimd_env.Object(fastnoisesimd_path + 'FastNoiseSIMD_avx2.cpp', CXXFLAGS='-mavx2'),
    fastnoisesimd_env.Object(fastnoisesimd_path + 'FastNoiseSIMD_avx512.cpp', CXXFLAGS='-mavx512f'),
]
Default(fastnoisesimd_env.StaticLibrary(target=fastnoisesimd_target, source=fastnoisesimd_sources))

# make sure our binding library is properly included
env.Append(CPPPATH=['.', godot_headers_path, cpp_bindings_path + 'include/', cpp_bindings_path + 'include/core/', cpp_bindings_path + 'include/gen/', fastnoisesimd_path])
env.Append(LIBPATH=[cpp_bindings_path + 'bin/', fastnoisesimd_path + 'bin/'])
env.Append(LIBS=[cpp_library, fastnoisesimd_library])

# tweak this if you want to use different folders, or more folders, to store your source code in.
env.Append(CPPPATH=['src/'])
sources = Glob('src/*.cpp')

library = env.SharedLibrary(target=env['target_path'] + env['target_name'] , source=sources)

Default(library)

# Generates help for the -h scons option.
Help(opts.GenerateHelpText(env))
