add-type -path "C:\Program Files\VMware\Horizon Performance Tracker\VMware.Horizon.WaveLib.Net.dll"
$wave = [VMware.Horizon.WaveLib.Net.Wave]::new()
$wave.OpenWave()

$status1 = New-Object VMware.Horizon.WaveLib.Net.Wave+BlastVNCEncoderStatus
$status1
$wave.GetEncoderStatus([ref]$status1)
