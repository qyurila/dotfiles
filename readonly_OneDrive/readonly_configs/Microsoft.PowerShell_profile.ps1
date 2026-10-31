# PowerShell Core addons
Import-Module scoop-completion
Import-Module gsudoModule

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Windows

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Set-Alias -name cd -value z
Set-Alias -name cm -value chezmoi
Set-Alias -name lg -value lazygit
Set-Alias -name ls -value eza
Set-Alias -name pn -value pnpm

Function cma { chezmoi add $args }
Function cmg { lazygit -p ~/.local/share/chezmoi }
Function cmz { z ~/.local/share/chezmoi }


# oh-my-posh config
# oh-my-posh init pwsh --config "C:\Users\Hyeon\OneDrive\configs\emodipt-qyurila-mod.omp.yaml" | Invoke-Expression
# Other theme candidates
# - craver
# - emodipt-extend
# - lambdageneration
# - sim-web
Invoke-Expression (&starship init powershell)

atuin init powershell | Out-String | Invoke-Expression
zoxide init powershell | Out-String | Invoke-Expression

### Functions ###

# kanata shortcut
function k { Set-Location "C:\Users\Hyeon\OneDrive\kanata" && sudo $args ".\kanata.exe" }

# yazi config
function y {
	$tmp = [System.IO.Path]::GetTempFileName()
	yazi $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
		Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
	}
	Remove-Item -Path $tmp
}

# Symlink creation shortcut (with Admin rights)
function sym {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$From,
		[Parameter(Mandatory=$true, Position=1)]
		[string]$To
	)
	try {
		if (!(Test-Path -Path $From)) {
			Write-Error "Error: The source path '$From' does not exist."
			return
		}
		if (Test-Path -Path $To) {
			Write-Error "Error: The destination path '$To' already exists. Please remove it manually or choose a different destination."
			return
		}
		New-Item -ItemType SymbolicLink -Path $To -Target $From -Force
		Write-Host "Symbolic link created: '$To' -> '$From'"
	}
	catch {
		Write-Error "An error occurred creating symbolic link: $($_.Exception.Message)"
	}
}

# yt-dlp format 141 shortcut
function ytm {
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$link
	)
	$modifiedLink = $link -replace '[&?]si=.*$'
	if ($modifiedLink -ne $link) {
		Write-Host "Removed 'si' parameters from URL" -ForegroundColor Yellow
		$link = $modifiedLink
	}

	if ($link -match 'https://music.youtube.com/watch') {
		# NOTE: yt-dlp can't fetch the actual original metadata
		# https://github.com/yt-dlp/yt-dlp/issues/429#issuecomment-3042332186
		yt-dlp -f 141 -o "%(track)s [%(id)s].%(ext)s" `
			--embed-thumbnail `
			--ppa 'ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop="min(iw\,ih)":"min(iw\,ih)"' `
			--embed-metadata `
			--parse-metadata ":(?P<meta_comment>)(?P<meta_description>)(?P<meta_synopsis>)" `
			--parse-metadata "release_year:(?P<meta_date>\d{4})" `
			--extractor-args "youtube:player-client=default,web_music;po_token=web_music.gvs+Ml-HnZFpaRh9cYehVWll3avkdPafwVao5MMvaY7cHUDfHp5SysXUtsTH9_2tXqonyeYdFp9Qncc1eW49iJlmtP8NHAf5EU9xUGrJb2_aHsy737Yq6jjKinZVr9Wbj7X9EQ==" `
			--cookies C:\Users\Hyeon\OneDrive\configs\cookies-youtube-com_260420.txt `
			$link
	} elseif ($link -match 'https://soundcloud.com/') {
		yt-dlp -f hls_aac_160k -o "%(track)s [%(id)s].%(ext)s" `
			--embed-thumbnail `
			--embed-metadata `
			--parse-metadata "release_year:(?P<meta_date>\d{4})" `
			$link
	}
}


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}
