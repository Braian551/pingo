Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.SetOutputToWaveFile('beep.wav')
$speak.Speak('beep')
$speak.Dispose()
