# Fix Invalid Character JSON File
The intention of this PowerShell script is to fix any JSON file that have invalid character on it.

Here is the official list of all special characters that must be escaped:

https://tools.ietf.org/html/rfc7159

        %x22 /          ; "    quotation mark  U+0022
        %x5C /          ; \    reverse solidus U+005C
        %x2F /          ; /    solidus         U+002F
        %x62 /          ; b    backspace       U+0008
        %x66 /          ; f    form feed       U+000C
        %x6E /          ; n    line feed       U+000A
        %x72 /          ; r    carriage return U+000D
        %x74 /          ; t    tab             U+0009
        %x75 4HEXDIG )  ; uXXXX  U+XXXX

# How to Use this Script

This script is using Newtonsoft.Json.dll library.

You can download the file here: https://github.com/JamesNK/Newtonsoft.Json/releases

You need to change the DLL path in the script. Please look for this line as reference and replace the path:

        [Reflection.Assembly]::LoadFile

Create a folder and add all JSON files that you would like to process and change the folder path at:

        $folderPath = "C:\AffectedJSONFiles"

The script will process all files on this folder.

You have two scripts available:

        FixJSONFiles-SingleThread
        FixJSONFiles-MultiThread

The SingleThread will process all files in sequence.

The MultiThread will process files simultaneously based in the $Jobs variable. By default it will look for 4 files at the same time.