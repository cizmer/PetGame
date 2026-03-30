local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.53, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local plr = game.Players.LocalPlayer
local playerGui = plr.PlayerGui
local StarterGui = script.Parent

playerGui.MenusGui.Enabled = false
playerGui.StatsGui.Enabled = false
StarterGui.Enabled = true

for _, button in pairs(playerGui.StarterGui:GetDescendants()) do
	if button:IsA("ImageButton") then
		button.MouseButton1Up:Connect(function()
			StarterGui.NameInput.PlaceholderText = "Name Your " .. button.Name
			StarterGui.PetSelected.Value = button.Name
			StarterGui.NameInput.Visible = true
			StarterGui.Submit.Visible = true

			for _, clicked in (playerGui.StarterGui:GetDescendants()) do
				if clicked:IsA("ImageButton") then
					if clicked == button then
						clicked.Parent.BackgroundColor3 = Color3.fromRGB(255, 255, 110)
						
					else
						clicked.Parent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					end
					
				end
			end
			
		end)
		
		button.MouseEnter:Connect(function()
			button:TweenSize(UDim2.new(0.98, 0,0.98, 0),Enum.EasingDirection.Out,Enum.EasingStyle.Sine,.25,true)
		end)
		
		button.MouseLeave:Connect(function()
			button:TweenSize(UDim2.new(0.91, 0,0.915, 0),Enum.EasingDirection.Out,Enum.EasingStyle.Sine,.25,true)
		end)	
	end
end

StarterGui.NameInput.Visible = false
StarterGui.Submit.Visible = false

StarterGui.Submit.MouseButton1Up:Connect(function()
	local petName = StarterGui.NameInput.Text
	if string.gsub(petName, " ","")	~= "" then
		game.ReplicatedStorage.Remotes.InitializePet:FireServer(StarterGui.PetSelected.Value)
		playerGui.MenusGui.Enabled = true
		playerGui.StatsGui.Enabled = true
		StarterGui.Enabled = false
		playerGui.StatsGui.PetName.Text = petName .. " (Lv. 1)"
	end
end)