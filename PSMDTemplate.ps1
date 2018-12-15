@{
	TemplateName = 'SSDTDbTest' # Insert name of template
	Version = "1.0.0.0" # Version to build to
	AutoIncrementVersion = $true # If a newer version than specified is present, instead of the specified version, make it one greater than the existing template
	Tags = @() # Insert Tags as desired
	Author = 'Sander Stad' # The author of the template, not the file / project created from it
	Description = '' # Try describing the template
	Exclusions = @() # Contains list of files - relative path to root - to ignore when building the template
	Scripts = @{
		projectGuid = {
			"{$([System.Guid]::NewGuid().ToString().ToUpper())}"
		}
		dataProjectGuid = {
			"{$([System.Guid]::NewGuid().ToString().ToUpper())}"
		}
		testProjectGuid = {
			"{$([System.Guid]::NewGuid().ToString().ToUpper())}"
		}
		solutionGuid = {
			"{$([System.Guid]::NewGuid().ToString().ToUpper())}"
		}
	} # Insert additional scriptblocks as needed. Each scriptblock will be executed once only on create, no matter how often it is referenced.
}