Set-Location .\server\hid
dotnet build . --output "bin" --self-contained true --runtime win-x64
Set-Location ../..

robocopy .\server\hid\bin package/hid