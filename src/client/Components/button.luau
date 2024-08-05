-- Fusion
local fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Value = fusion.Value
local Hydrate = fusion.Hydrate
local New = fusion.New
local Tween = fusion.Tween
local OnEvent = fusion.OnEvent

local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")

local playerScripts = game.Players.LocalPlayer.PlayerScripts
local util = require(playerScripts.Client.Util)

-- Button
local button = {}
button.__index = button
button.ti = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
button.multis = {hover = 1.2, click = 0.9}
button.sounds = {}
button.callbacks = {}

button.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://18497925021", hover = "rbxassetid://18497999901", hoverVolume = 0.25, clickVolume = 0.5}
}


local function _playLocalSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.Parent = soundService
	sound.Volume = volume or 1
	sound.SoundId = soundId
	soundService:PlayLocalSound(sound)
	debris:AddItem(sound, sound.TimeLength)
end

function button.new(props)
	local self = setmetatable({}, button)
	if props.type == "ImageButton" or props.type == "TextButton" then
		if props.instance then
			for i, v in props do
				self[i] = v
			end

			self.origSize = self.instance.Size
			self.origPos = self.instance.Position
			self.newHoverSize = util.userdataManipulation.multUDim2(self.origSize, self.multis.hover)
			self.newClickSize = util.userdataManipulation.multUDim2(self.origSize, self.multis.click)
			self.size = Value(self.origSize)
			self.position = Value(self.origPos)

			self.clicking = false
			self.hovering = false

			self.button = Hydrate(self.instance) {
				Size = Tween(self.size, self.ti),
				Position = Tween(self.position, self.ti),
				[OnEvent "MouseEnter"] = function()
					if self.onHover then
						self:hover(true)
					end
				end,
				[OnEvent "MouseLeave"] = function()
					if self.onHover then
						self:hover()
					end
				end,
				[OnEvent "MouseButton1Click"] = function()
					if self.onClick then
						self:click()
					end
				end
			}
		else
			New "Imagebutton" {
				Image = props.Image,
				BackgroundTransparency = 1
			}
		end
	end
	return self
end

function button:hover(state)
	if self.callbacks and self.callbacks.hover then
		self.callbacks.hover(self, state)
	end

	task.spawn(function()
		if self.sounds.hover and state then
		_playLocalSound(self.sounds.hover, self.sounds.hoverVolume or 1)
		end
	end)
	if state then
		self.size:set(self.newHoverSize)
		self.hovering = true
	else
		self.hovering = false
		if not self.clicking then
			self.size:set(self.origSize)
		end
	end
end

function button:click()
	self.clicking = true
	self.size:set(self.newClickSize)
	task.spawn(function()
		if self.sounds.click then
			_playLocalSound(self.sounds.click, self.sounds.clickVolume or 1)
		end
	end)
	task.wait(self.ti.Time + 0.05)
	if self.hovering then
		self.size:set(self.newHoverSize)
	else
		self.size:set(self.origSize)
	end
	if self.callbacks and self.callbacks.click then
		self.callbacks.click(self)
	end
	self.clicking = false
end


return button