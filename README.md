# Fix Invalid Character JSON File
The intention of this PowerShell script is to fix any JSON file that have invalid character on it.

This PowerShell command'let will Fix a JSON file that doesn't have escape characters behind a special characters.

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

You can install this module from PowerShell Gallery:

        Install-Module FixEscapeJSON

# Examples

Fixing all JSON files in a folder

If you have more than one file in a folder the command will simultaneously (Multithreading) process 4 files by default.

        Invoke-FixJSON -Folder C:\JsonFiles

Fixing all JSON files in a folder specifing how many files you would like to simultaneously process (Multithreading)

By default it will process 4 files simultaneously (Multithreading)

        Invoke-FixJSON -Folder C:\JsonFiles -Threads 2
        Invoke-FixJSON -Folder C:\JsonFiles -Threads 6

Fixing a single JSON file

        Invoke-FixJSON -File C:\JsonFiles\jsonfile.json