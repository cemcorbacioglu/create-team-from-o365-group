# Connect to Microsoft Teams and AzureAD
Function Connect-O365 {
    Try {
        Connect-AzureAD -ErrorAction Stop
        Connect-MicrosoftTeams -ErrorAction Stop
        Write-Host "Successfully connected to AzureAD and Microsoft Teams" -ForegroundColor Green
    } Catch {
        Write-Host "Failed to connect to AzureAD or Microsoft Teams." -ForegroundColor Red
        Exit
    }
}

# Check if the group is dynamic
Function Is-DynamicO365Group {
    param (
        [string]$GroupId
    )
    $group = Get-AzureADMSGroup -Id $GroupId
    if ($group.GroupTypes -contains "DynamicMembership") {
        return $true
    }
    return $false
}

# Create a Microsoft Teams team from an O365 group
Function Create-TeamsTeamFromGroup {
    param (
        [string]$GroupId
    )
    Try {
        # Create a new team from the O365 group
        New-Team -GroupId $GroupId -ErrorAction Stop
        Write-Host "Teams team is being created for group ID: $GroupId" -ForegroundColor Green
    } Catch {
        Write-Host "Error creating the team. Ensure you have the correct permissions." -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

# List members of the O365 group
Function List-O365GroupMembers {
    param (
        [string]$GroupId
    )
    $members = Get-AzureADGroupMember -ObjectId $GroupId
    if ($members.Count -eq 0) {
        Write-Host "No members found in the group." -ForegroundColor Yellow
    } else {
        Write-Host "Members of the group:" -ForegroundColor Cyan
        foreach ($member in $members) {
            Write-Host "- $($member.DisplayName) ($($member.UserPrincipalName))"
        }
    }
}

# Main loop for getting group names and performing operations
Function Process-Groups {
    while ($true) {
        $groupName = Read-Host "Enter the name of the O365 group (or 'exit' to quit)"
        if ($groupName -eq "exit") {
            break
        }

        # Find the group by name
        $group = Get-AzureADMSGroup -Filter "DisplayName eq '$groupName'"
        if ($group) {
            $groupId = $group.Id
            Write-Host "Found group: $groupName" -ForegroundColor Green

            # Check if the group is dynamic
            if (Is-DynamicO365Group -GroupId $groupId) {
                Write-Host "$groupName is a dynamic O365 group." -ForegroundColor Green

                # Create Teams team from the group
                Create-TeamsTeamFromGroup -GroupId $groupId

                # List members of the group
                List-O365GroupMembers -GroupId $groupId
            } else {
                Write-Host "$groupName is not a dynamic O365 group." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No group found with the name '$groupName'." -ForegroundColor Red
        }
    }
}

# Run the script
Connect-O365
Process-Groups
