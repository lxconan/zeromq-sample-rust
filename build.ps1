[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('debug', 'release')]
    [System.String]
    $Configuration = 'debug'
)
$ErrorActionPreference = 'Stop'

$PROJECT_ROOT = $PSScriptRoot
$LIBZMQ_ROOT = "$PROJECT_ROOT\libzmq"

function BuildLibZmq () {
    Set-Location $LIBZMQ_ROOT

    $LIBZMQ_BUILD_DIR = "$LIBZMQ_ROOT\build"

    if (-not (Test-Path -Path "$LIBZMQ_BUILD_DIR\libzmq.vcxproj" -PathType Leaf)) {
        if (-not (Test-Path "$LIBZMQ_BUILD_DIR")) {
            mkdir $LIBZMQ_BUILD_DIR
        }

        Set-Location $LIBZMQ_BUILD_DIR
        & 'cmake' '-D' 'CMAKE_CXX_FLAGS_RELEASE="/MT"' '-D' 'CMAKE_CXX_FLAGS_DEBUG="/MTd"' 'WITH_DOC=OFF' '-D' 'WITH_PERF_TOOL=OFF' '-D' 'ZMQ_BUILD_TESTS=OFF' '-D' 'ENABLE_CPACK=OFF'  '"../"'
        if ($LASTEXITCODE -ne 0) {
            throw 'CMAKE command failed.'
        }
    }
    
    Set-Location $LIBZMQ_BUILD_DIR
    if (Test-Path "$LIBZMQ_BUILD_DIR\lib\$Configuration") {
        Remove-Item -Recurse -Force "$LIBZMQ_BUILD_DIR\lib\$Configuration"
    }
    
    & 'msbuild' '/t:rebuild' '/v:minimal' "/p:Configuration=$Configuration" 'libzmq.vcxproj'
    Move-Item "$LIBZMQ_BUILD_DIR\lib\$Configuration\*.lib" "$LIBZMQ_BUILD_DIR\lib\$Configuration\zmq.lib"
    if ($LASTEXITCODE -ne 0) {
        throw 'MSBuild failed.'
    }
}

function BuildWorkspace () {
    Set-Location $PROJECT_ROOT
    
    $env:LIBZMQ_LIB_DIR = "$LIBZMQ_ROOT\build\lib\$Configuration"
    $env:LIBZMQ_INCLUDE_DIR = "$LIBZMQ_ROOT\include"

    Write-Host "LIBZMQ_LIB_DIR = $env:LIBZMQ_LIB_DIR" -ForegroundColor Green
    Write-Host "LIBZMQ_INCLUDE_DIR = $env:LIBZMQ_INCLUDE_DIR" -ForegroundColor Green

    cargo build
    if ($LASTEXITCODE -ne 0) {
        throw 'cargo build failed.'
    }

    Copy-Item "$LIBZMQ_ROOT\build\bin\$Configuration\*.dll" "target\$Configuration"
}

Set-Location $PROJECT_ROOT
BuildLibZmq
BuildWorkspace
