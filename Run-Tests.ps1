#Set-PSDebug -Trace 1
Write-Host ""
Write-Host "NUnit test discovery and execution utility for Powershell"
Write-Host ""
Write-Host "https://github.com/rafaelromao/run-tests"
Write-Host ""

# Parse the input arguments
Function ParseArguments($input_args) {
	$result = New-Object System.Object
	$result | Add-Member -type NoteProperty -name printHelp -value $false
	$result | Add-Member -type NoteProperty -name runAllTests -value $false
	$result | Add-Member -type NoteProperty -name nunitIncludes -value $null
	$result | Add-Member -type NoteProperty -name nunitExcludes -value $null
	$result | Add-Member -type NoteProperty -name nunitOverMono -value $false
	$result | Add-Member -type NoteProperty -name config -value "Debug"
	$result | Add-Member -type NoteProperty -name solutionDir -value "."

	For ($i = 0; $i -lt $input_args.Length; $i++) {
		# Parse the current and next arguments
		$arg = $input_args[$i]
		$hasNextArg = $i -lt $input_args.Length-1
		$nextArg = $null
		if ($hasNextArg) {
			$nextArg = $input_args[$i+1]
		}

		# Check if shall print help
		if ($arg -eq "--help" -or $arg -eq "-h") {
			$result.printHelp = $true
		}
		
		# Check if shall run all tests automatically
		if ($arg -eq "--all" -or $arg -eq "-a") {
			$result.runAllTests = $true
		}
		
		# Get the solution folder to use as reference
		if (($arg -eq "--solutionDir" -or $arg -eq "-s") -and $hasNextArg) {
			$result.solutionDir = "$($nextArg)"
		}

		# Get the desired build configuration to run
		if (($arg -eq "--config" -or $arg -eq "-c") -and $hasNextArg) {
			$result.config = "$($nextArg)"
		}
		
		# Check /include argument to nunit-console
		if (($arg -eq "--include" -or $arg -eq "-i") -and $hasNextArg) {
			if ($result.nunitIncludes -eq $null) {
				$result.nunitIncludes = "$($nextArg)"
			}
			else {
				$result.nunitIncludes = "$($result.nunitIncludes),$($nextArg)"
			}
		}
			
		# Check /exclude argument to nunit-console
		if (($arg -eq "--exclude" -or $arg -eq "-e") -and $hasNextArg) {
			if ($result.nunitExcludes -eq $null) {
				$result.nunitExcludes = "$($nextArg)"
			}
			else {
				$result.nunitExcludes = "$($result.nunitExcludes),$($nextArg)"
			}
		}
		
		#Check if shall run nunit over mono
		if ($arg -eq "--mono" -or $arg -eq "-m") {
			$result.nunitOverMono = $true
		}		
	}
	
	return $result
}

# Check if the arguments used require the help to be printed
Function CheckIfMustPrintHelp($printHelp) {
	if ($printHelp) {
		Write-Host ""
		Write-Host "--help `t`t`t -h `t`t`t Print usage options"
		Write-Host "--all `t`t`t -a `t`t`t Execute all tests automatically instead of asking one by one"
		Write-Host "--solution SolutionDir `t -s SolutionDir `t Inform the solution folder. The default is the current folder"
		Write-Host "--config Debug/Release `t -c Debug/Release `t Inform the build configuration to use. The default is Debug"
		Write-Host "--include category `t -i category `t`t Filter the category of tests that shall be run"
		Write-Host "--exclude category `t -e category `t`t Filter the category of tests that shall not be run"
		Write-Host "--mono `t`t`t -m `t`t`t Execute the tests over mono instead of .NET"
		Write-Host ""
		exit
	}
}

# Find all test assemblies within the current directory recursivelly, excluing only the .git folder
Function FindTestAssemblies($solutionDir, $config) {
	Write-Host "Finding tests..."
	$testProjects = (Get-ChildItem $solutionDir -Recurse -Include *.Tests.csproj -Exclude .git)
	$testAssemblies = @()
	ForEach ($testProject in $testProjects) {
		$testProjectFolder = [System.IO.Path]::GetDirectoryName($testProject)
		$testProjectName = [System.IO.Path]::GetFileNameWithoutExtension($testProject)
		$testBinFolder = [System.IO.Path]::Combine($testProjectFolder, "bin\$($config)")
		$testAssembly = [System.IO.Path]::Combine($testBinFolder, "$($testProjectName).dll")
		$testAssemblies += $testAssembly
	}
	Write-Host "$($testAssemblies.Length) test assemblies found!"
	
	return $testAssemblies
}

# Runs a given test assembly
Function RunTestAssembly($testAssembly, $counter, $config, $nunitOverMono, $nunitIncludes, $nunitExcludes) {
	#$nunitConsole = "${env:ProgramFiles(x86)}\NUnit 2.6.4\bin\nunit-console.exe"
	$nunitConsole = "${env:ProgramFiles(x86)}\NUnit.org\bin\nunit-console.exe"
	$nunitArgs = "--labels=all"
	$tmp = mkdir -Force Run-Tests
	$outputs = "--out=Run-Tests\Run-Tests_$($counter).out --err=Run-Tests\Run-Tests_$($counter).err"
	$arguments = "$($nunitArgs) --config=$($config) $($outputs)"
	if ($nunitIncludes -ne $null) {
		$arguments = "$($arguments) --include=$($nunitIncludes)"
	}
	if ($nunitExcludes -ne $null) {
		$arguments = "$($arguments) --exclude=$($nunitExcludes)"
	}
	if ($nunitOverMono) {
		Write-Host -foregroundcolor Yellow "Executing mono $($nunitConsole) ""$($testAssembly)"" --framework=mono-4.0 $($arguments)"
		& mono "$($nunitConsole)" """$($testAssembly)"" --framework=mono-4.0 $($arguments)"
		#& $nunitConsole """$($testAssembly)"" --framework=mono-4.0 $($arguments)"
	}
	else {
		Write-Host -foregroundcolor Yellow "Executing $($nunitConsole) ""$($testAssembly)"" $($arguments)"
		& $nunitConsole """$($testAssembly)"" --framework=net-4.5 $($arguments)"
	}
}

# Loop through test assemblies found and ask if shall run them
Function RunTestAssemblies($testAssemblies, $runAllTests, $config, $nunitOverMono, $nunitIncludes, $nunitExcludes) {
	For ($i = 0; $i -lt $testAssemblies.Length; $i++) {
		$testAssembly = $testAssemblies[$i]
		if ($runAllTests) {
			RunTestAssembly $testAssembly $i $config $nunitOverMono $nunitIncludes $nunitExcludes
		}
		else {
			Write-Host -foregroundcolor Cyan "Found $($testAssembly)."
			Write-Host "Run this test assembly [Yes, No, All, Cancel]?"
			$key = [System.Console]::ReadKey($true)
			switch ($key.Key.ToString().ToLower()) {
				"a" { $runAllTests = $true }
				"y" { RunTestAssembly $testAssembly $i $config $nunitOverMono $nunitIncludes $nunitExcludes }
				"c" { exit }
			}
		}
	}
}



# Parse the input arguments
$arguments = ParseArguments $args
# Check if the arguments used require the help to be printed
CheckIfMustPrintHelp $arguments.printHelp
# Find all test assemblies within the current directory recursivelly, excluing only the .git folder
$testAssemblies = FindTestAssemblies $arguments.solutionDir $arguments.config
# Loop through test assemblies found and ask if shall run them
RunTestAssemblies $testAssemblies $arguments.runAllTests $arguments.config $arguments.nunitOverMono $arguments.nunitIncludes $arguments.nunitExcludes