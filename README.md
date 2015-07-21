# run-tests
NUnit test discovery and execution utility for Powershell

## How to use it?
From a Visual Studio solution folder, just type `run-tests` to discover and execute all tests whithin this solution.

Any project whose name ends with `.Tests.csproj` will be considered a test project.

NUnit output will be saved within the `.\run-tests` folder

## Command Line Options
- Print usage options:
`--help` or `-h`
- Execute all tests automatically, instead of asking one by one:
`--all` or `-a`
- Inform the solution folder. The default is the current folder:
`--solution SolutionDir` or `-s SolutionDir`
- Inform the build configuration to use. The default is `Debug`:
`--config Debug/Release` or `-c Debug/Release`
- Filter the category of tests that shall be run (can be used multiple times):
`--include category` or `-i category`
- Filter the category of tests that shall not be run (can be used multiple times):
`--exclude category` or `-e category`
- Execute over mono instead of .NET:
`--mono` or `-m`