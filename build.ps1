[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('debug', 'release')]
    [System.String]
    $Configuration = 'debug'
)

# You may want to change this line
$LIBZMQ_ROOT = 'C:\Workspace\libzmq'

$env:LIBZMQ_LIB_DIR = "$LIBZMQ_ROOT\build\lib\Release"
$env:LIBZMQ_INCLUDE_DIR = "$LIBZMQ_ROOT\include"
cargo build

cp "$LIBZMQ_ROOT\build\bin\Release\*.dll" "target\$Configuration"