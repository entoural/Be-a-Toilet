local soundService = game:GetService("SoundService")

local musicService = {}
musicService.currentSong = 1
musicService.songs = nil
musicService.songInstance = soundService:WaitForChild("Music")
musicService.songs = soundService:WaitForChild("Songs"):GetChildren()

function musicService:playNextSong()
	if musicService.currentSong == #musicService.songs then
		musicService.currentSong = 1
	else
		musicService.currentSong += 1
	end

	local nextSong = musicService.songs[musicService.currentSong].SoundId
	musicService.songInstance:Stop()
	musicService.songInstance.SoundId = nextSong
	musicService.songInstance:Play()
end

function musicService.start()
	musicService:playNextSong()

	musicService.songInstance.Ended:Connect(function()
		musicService:playNextSong()
	end)
end


return musicService