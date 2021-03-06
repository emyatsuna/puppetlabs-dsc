$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'SystemLocaleDsc.ResourceHelper' `
            -ChildPath 'SystemLocaleDsc.ResourceHelper.psm1'))

# Import Localization Strings
$LocalizedData = Get-LocalizedData `
    -ResourceName 'MSFT_SystemLocale' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Returns the current System Local on the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SystemLocale
        Specifies the System Locale.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SystemLocale
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingSystemLocaleMessage)
        ) -join '' )

    # Get the current System Locale
    $currentSystemLocale = Get-WinSystemLocale `
        -ErrorAction Stop

    # Generate the return object.
    $returnValue = @{
        IsSingleInstance = $IsSingleInstance
        SystemLocale     = $currentSystemLocale.Name
    }

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Sets the current System Locale on the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SystemLocale
        Specifies the System Locale.
#>
function Set-TargetResource
{
    # Suppressing this rule because $global:DSCMachineStatus is used to trigger a reboot when there are pending changes.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SystemLocale
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingSystemLocaleMessage)
        ) -join '' )

    # Get the current System Locale
    $currentSystemLocale = Get-WinSystemLocale `
        -ErrorAction Stop

    if ($currentSystemLocale.Name -ne $SystemLocale)
    {
        Set-WinSystemLocale `
            -SystemLocale $SystemLocale `
            -ErrorAction Stop

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SystemLocaleUpdatedMessage)
            ) -join '' )

        $global:DSCMachineStatus = 1

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.RestartRequiredMessage)
            ) -join '' )
    }
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests if the current System Locale on the node needs to be changed.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SystemLocale
        Specifies the System Locale.

    .OUTPUTS
        Returns false if the System Locale needs to be changed or true if it is correct.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SystemLocale
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestingSystemLocaleMessage)
        ) -join '' )

    if (-not (Test-SystemLocaleValue -SystemLocale $SystemLocale))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.InvalidSystemLocaleError -f $SystemLocale) `
            -ArgumentName 'SystemLocale'
    } # if

    # Get the current System Locale
    $currentSystemLocale = Get-WinSystemLocale `
        -ErrorAction Stop

    if ($currentSystemLocale.Name -ne $SystemLocale)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SystemLocaleParameterNeedsUpdateMessage -f `
                $currentSystemLocale.Name,$SystemLocale)
        ) -join '' )

        return $false
    }
    return $true
} # Test-TargetResource

<#
    .SYNOPSIS
        Checks the provided System Locale against the list of valid cultures.

    .PARAMETER SystemLocale
        The System Locale to check the validitiy of.
#>
function Test-SystemLocaleValue
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SystemLocale
    )

    $validCultures = [System.Globalization.CultureInfo]::GetCultures(`
        [System.Globalization.CultureTypes]::AllCultures`
        ).name

    return ($SystemLocale -in $validCultures)
}

Export-ModuleMember -Function *-TargetResource
