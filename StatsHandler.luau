local TweenService = game:GetService("TweenService")
local propertyTween = nil
local expTween = nil

local player = game.Players.LocalPlayer

local Remotes = game.ReplicatedStorage.Remotes
local Modules = game.ReplicatedStorage.Modules
local StateHandler = require(Modules.StateHandler)

local UIS = game:GetService("UserInputService")

local StatsGui = script.Parent
local successText = StatsGui.SuccessText

local hunger = StatsGui.Hunger
local hygiene = StatsGui.Hygiene
local money = StatsGui.Money
local happiness = StatsGui.Happiness
local EXP = StatsGui.EXP
local level = StatsGui.Level

local petHealthy = false
local petType = nil
local vetVisitCost = 150

local MAX_STAT = 20

local universalProperties = require(Modules.UniversalProperties)
local propertiesModule = nil

Remotes.Eat.OnClientEvent:Connect(function(foodName, petName, food)
	if StateHandler.GetState() == "Idle" then
		StateHandler.SetState("Eating", 5.5)
		food:Destroy()
		
		if propertiesModule == nil then
			propertiesModule = require(Modules[petName .. "Properties"])
		end
		
		Remotes.Eat:FireServer(propertiesModule.Food[foodName].Happy)

		addMoney(propertiesModule.Food[foodName].Money)

		if propertiesModule.Food[foodName].Money >= 0 then
			successText.Text = "Fed pet " .. foodName .. " (+ " .. propertiesModule.Food[foodName].EXP .. " EXP & +$" .. propertiesModule.Food[foodName].Money .. ")" 
		else
			successText.Text = "Fed pet " .. foodName .. " (+ " .. propertiesModule.Food[foodName].EXP .. " EXP & -$" .. string.sub(propertiesModule.Food[foodName].Money, string.find(propertiesModule.Food[foodName].Money, "-") + 1) .. ")" 
		end

		successText.Visible = true

		addHunger(propertiesModule.Food[foodName].Hunger)
		addHappiness(propertiesModule.Food[foodName].Happy)
		updateEXP(propertiesModule.Food[foodName].EXP)

		task.wait(5)
		successText.Visible = false
	end
	
end)

Remotes.Clean.OnClientEvent:Connect(function(objectName, petName, object)
	if StateHandler.GetState() == "Idle" then
		StateHandler.SetState("Cleaning", 5.5)
		object:Destroy()
		
		Remotes.Clean:FireServer(universalProperties.Hygiene[objectName].Happy)

		successText.Text = "Cleaned pet with " .. objectName .. " (+ " .. universalProperties.Hygiene[objectName].EXP .. " EXP & +$" .. universalProperties.Hygiene[objectName].Money .. ")" 
		successText.Visible = true

		addHygiene(universalProperties.Hygiene[objectName].Hygiene)
		addHappiness(universalProperties.Hygiene[objectName].Happy)
		updateEXP(universalProperties.Hygiene[objectName].EXP)

		task.wait(5)
		successText.Visible = false
	end
end)

happiness.Changed:Connect(function()
	updatePropertyGUI("Happiness")
end)

hygiene.Changed:Connect(function()
	updatePropertyGUI("Hygiene")
end)

hunger.Changed:Connect(function()
	updatePropertyGUI("Hunger")
end)

money.Changed:Connect(function()
	StatsGui.MoneyContainer.MoneyText.Text = "$" .. money.Value
end)

function updatePropertyGUI(property)
	propertyTween = TweenService:Create(
		StatsGui["StatsContainer"][property.. "Container"][property.."Bar"], 
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
		{Size = UDim2.fromScale((StatsGui[property].Value / MAX_STAT) * 1.001, 1)}):Play()
end

function updateEXP(exp)
	
	EXP:SetAttribute("CurrentEXP", EXP:GetAttribute("CurrentEXP") + exp)
	updateEXPGUI(0.6)
	
	task.wait(0.7)
	
	if EXP:GetAttribute("CurrentEXP") >= EXP.Value then
		local currEXP = EXP:GetAttribute("CurrentEXP")
		EXP:SetAttribute("CurrentEXP", EXP.Value)
		updateEXPGUI(0.4)	

		task.wait(0.4)
		
		EXP:SetAttribute("CurrentEXP", 0)
		updateEXPGUI(0)	
		
		task.wait(0.4)

		level.Value += 1
		EXP:SetAttribute("CurrentEXP", currEXP - EXP.Value)
		EXP.Value = (5 * level.Value^2) + 20
	end
	
	updateEXPGUI(0.6)	
	
end

function updateEXPGUI(tweenTime)
	StatsGui.PetName.Text = string.sub(StatsGui.PetName.Text, 1, string.find(StatsGui.PetName.Text, "Lv.", 1, false) - 2) .. "(Lv. " .. level.Value .. ")"
	expTween = TweenService:Create(
		StatsGui.EXPContainer.EXPBar,
		TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{Size = UDim2.fromScale(math.clamp((EXP:GetAttribute("CurrentEXP") / EXP.Value) * 1.001, 0, 1.001), 1)}
	):Play()
	
	
--	StatsGui.EXPContainer.EXPBar.Size = UDim2.fromScale((EXP:GetAttribute("CurrentEXP") / EXP.Value) * 1.001, 1)
end

--FUNCTIONS

function addHygiene(hygieneAdd)
	hygiene.Value += hygieneAdd

	if hygiene.Value > MAX_STAT then
		hygiene.Value = MAX_STAT
	elseif hygiene.Value < 0 then
		hygiene.Value = 0
	end
end

function addHunger(hungerAdd)
	hunger.Value += hungerAdd

	if hunger.Value > MAX_STAT then
		hunger.Value = MAX_STAT
	elseif hunger.Value < 0 then
		hunger.Value = 0
	end
end

function addHappiness(happy)
	happiness.Value += happy

	if happiness.Value > MAX_STAT then
		happiness.Value = MAX_STAT
	elseif happiness.Value < 0 then
		happiness.Value = 0
	end	
end	

function addMoney(moneyAdded)
	money.Value += moneyAdded
	StatsGui.MoneyContainer.MoneyText.Text = "$" .. money.Value
end

function initializeStats()
	money.Value = 170
	hunger.Value = 10
	hygiene.Value = 10
	happiness.Value = 10
	
	game.ReplicatedStorage.Remotes.GetFood:FireServer("destroy")
	game.ReplicatedStorage.Remotes.GetHygiene:FireServer("destroy")
	
	updatePropertyGUI("Happiness")
	updatePropertyGUI("Hunger")
	updatePropertyGUI("Hygiene")
	addMoney(0)

	EXP.Value = (5 * level.Value^2) + 20
	updateEXPGUI(0.6)
	petHealthy = true

end

StatsGui.EmergencyContainer.Pay.MouseButton1Up:Connect(function()
	if StatsGui.EmergencyContainer.Pay.Text == "Pay" then
		task.wait(0.1)
		
		if money.Value >= vetVisitCost then
			StatsGui.EmergencyContainer.Visible = false
			StatsGui.StatsContainer.Visible = true
			StatsGui.MoneyContainer.Visible = true
			StatsGui.EXPContainer.Visible = true
			game.ReplicatedStorage.Remotes.LostEvent:Fire("paid")
			money.Value -= vetVisitCost
			
			hunger.Value = 10
			hygiene.Value = 10
			happiness.Value = 10

			updatePropertyGUI("Happiness")
			updatePropertyGUI("Hunger")
			updatePropertyGUI("Hygiene")
			addMoney(0)

			EXP.Value = (5 * level.Value^2) + 20
			updateEXPGUI(0.6)
			petHealthy = true
			drainStats()

		else
			StatsGui.EmergencyContainer.ProblemText.Text = "Looks like you are in debt. Game over!"
			StatsGui.EmergencyContainer.Pay.Text = "Return"
			game.ReplicatedStorage.Remotes.InitializePet:FireServer("destroy")

		end
	else

		task.wait(0.1)
		game.ReplicatedStorage.Remotes.LostEvent:Fire("restart")
		StatsGui.EmergencyContainer.Visible = false
		player.PlayerGui.StarterGui.Enabled = true
		StatsGui.EmergencyContainer.Pay.Text = "Pay"

	end
	
end)

function drainStats()
	task.spawn(function()
		while petHealthy do
			if StateHandler.GetState() == "Idle" then
				addHunger(-1)
				addHygiene(-1)
				addHappiness(-1)
				if StatsGui.Hygiene.Value <= 0 or StatsGui.Happiness.Value <= 0 or StatsGui.Hunger.Value <= 0 then
					StatsGui.StatsContainer.Visible = false
					StatsGui.MoneyContainer.Visible = false
					StatsGui.EXPContainer.Visible = false
					
					StatsGui.EmergencyContainer.Balance.Text = "Current Balance: $" .. money.Value
					
					petHealthy = false
					game.ReplicatedStorage.Remotes.LostEvent:Fire("lost")


					StatsGui.EmergencyContainer.Visible = true
					if StatsGui.Hygiene.Value <= 0 then
						StatsGui.EmergencyContainer.ProblemText.Text = "Looks like your pet has gotten an infection. You will need to pay the medical costs to get that fixed!"
					elseif StatsGui.Happiness.Value <= 0 then
						StatsGui.EmergencyContainer.ProblemText.Text = "Looks like your pet is depressed. You will need to pay the medical costs to get that fixed!"
					else
						StatsGui.EmergencyContainer.ProblemText.Text = "Looks like your pet is ill. You will need to pay the medical costs to get that fixed!"
					end

				end
			end
			wait(30)
		end

	end)
end

game.ReplicatedStorage.Remotes.InitializePet.OnClientEvent:Connect(function(pet)
	propertiesModule = nil
	petType = pet
	StatsGui.StatsContainer.Visible = true
	StatsGui.MoneyContainer.Visible = true
	StatsGui.EXPContainer.Visible = true
	initializeStats()
	drainStats()
end)

local killKeys = {
	Enum.KeyCode.LeftBracket,
	Enum.KeyCode.RightBracket,
	Enum.KeyCode.BackSlash
}

UIS.InputEnded:Connect(function(input, gpe)
	if table.find(killKeys, input.KeyCode) then
		if input.KeyCode == Enum.KeyCode.LeftBracket then
			addHunger(-30)

		elseif input.KeyCode == Enum.KeyCode.RightBracket then
			addHygiene(-30)

		elseif input.KeyCode == Enum.KeyCode.BackSlash then
			addHappiness(-30)

		end
		
		task.wait(0.5)
		
		if StatsGui.Hygiene.Value <= 0 or StatsGui.Happiness.Value <= 0 or StatsGui.Hunger.Value <= 0 then
			StatsGui.StatsContainer.Visible = false
			StatsGui.MoneyContainer.Visible = false
			StatsGui.EXPContainer.Visible = false

			StatsGui.EmergencyContainer.Balance.Text = "Current Balance: $" .. money.Value

			petHealthy = false
			game.ReplicatedStorage.Remotes.LostEvent:Fire("lost")


			StatsGui.EmergencyContainer.Visible = true
			if StatsGui.Hygiene.Value <= 0 then
				StatsGui.EmergencyContainer.ProblemText.Text = "Looks like your pet has gotten an infection. You will need to pay the medical costs to get that fixed!"
			elseif StatsGui.Happiness.Value <= 0 then
				StatsGui.EmergencyContainer.ProblemText.Text = "Looks like your pet is depressed. You will need to pay the medical costs to get that fixed!"
			else
				StatsGui.EmergencyContainer.ProblemText.Text = "Looks like your pet is ill. You will need to pay the medical costs to get that fixed!"
			end
		end
		
	end
end)