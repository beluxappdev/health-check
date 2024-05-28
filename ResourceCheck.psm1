[string] $global:Pass = "PASS"
[string] $global:Fail = "FAIL"
[string] $global:Err = "ERROR"


class ResourceCheck {
    [string]$SubscriptionId
    [string]$SubscriptionName

    ResourceCheck([string]$subscriptionId, [string]$subscriptionName) {
        $this.SubscriptionId = $subscriptionId
        $this.SubscriptionName = $subscriptionName
    }

    [string] checkRule ($name, $rule) {
        try {
            $functionName = $rule.function
            $returnedValue = $this.PSObject.Methods[$functionName].Invoke()
            $isExpected = $returnedValue -eq $rule.expected
            
            if ($isExpected) {
                Write-Host "✅ $($name): $($returnedValue -eq $rule.expected ? $global:Pass : $global:Fail)" -ForegroundColor Green
            }
            else {
                # Write-Host "⚠️  $($name): $($returnedValue -eq $rule.expected ? $global:Pass : $global:Fail) Expected: $($rule.expected) but got: $($returnedValue)" -ForegroundColor Red
                Write-Host "⚠️  $($name): $($returnedValue -eq $rule.expected ? $global:Pass : $global:Fail) - $($rule.explanation)" -ForegroundColor Red
            }
            return $returnedValue
        }
        catch {
            Write-Host "⛔ $($name): $($global:Err). An error occured: $($_)" -ForegroundColor DarkRed
            return $null
        }
    }
}