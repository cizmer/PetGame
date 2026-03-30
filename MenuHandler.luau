local player = game.Players.LocalPlayer
local currentCamera = workspace.CurrentCamera
local mouse = player:GetMouse()
local TweenService = game:GetService("TweenService")
local cameraPart = workspace.Cameras:WaitForChild("MainCamera")

local maxTilt = 4

local MenuGui = script.Parent
local MainContainer = MenuGui.MainContainer
local CookingGameFrame = MainContainer.ActivitiesFrame.Cooking
local BounceGameFrame = MainContainer.ActivitiesFrame.Bounce


currentCamera.CameraType = Enum.CameraType.Scriptable
currentCamera.CFrame = cameraPart.CFrame

local foodAmount = {}
local hygieneAmount = {}
local gameAmount = {}

local StateHandler = require(game.ReplicatedStorage.Modules.StateHandler)

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local targetCFrame = cameraPart.CFrame * CFrame.Angles(
	math.rad((((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY)) * -maxTilt),
	math.rad((((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX)) * -maxTilt),
	0
)
local tween = TweenService:Create(currentCamera, tweenInfo, {CFrame = targetCFrame})

local function updateCamera()
	local targetCFrame = cameraPart.CFrame * CFrame.Angles(
		math.rad((((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY)) * -maxTilt),
		math.rad((((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX)) * -maxTilt),
		0
	)

	tween = TweenService:Create(currentCamera, tweenInfo, {CFrame = targetCFrame})
	tween:Play()
end

local conn = game:GetService("RunService").RenderStepped:Connect(function()
	updateCamera()
end)

game.ReplicatedStorage.Remotes.LostEvent.Event:Connect(function(state)
	if state == "lost" then
		MenuGui.Button.Visible = false
		MenuGui.MainContainer.Visible = false
		MenuGui.Kitchen.Visible = false
		MenuGui.Main.Visible = false
		MenuGui.Shower.Visible = false
		
		cameraPart = workspace.Cameras.AmbulanceCamera
	elseif state == "restart" then
		cameraPart = workspace.Cameras.MainCamera
		foodAmount = {}
		hygieneAmount = {}

	else
		MenuGui.Button.Visible = true
		MenuGui.Kitchen.Visible = true
		MenuGui.Main.Visible = true
		MenuGui.Shower.Visible = true
		cameraPart = workspace.Cameras.MainCamera
		game.ReplicatedStorage.Remotes.MoveRoom:FireServer("Main")

	end
end)	

for i,v in (MenuGui:GetChildren()) do
	if v:IsA("ImageButton") then
		v.MouseButton1Up:Connect(function()
			cameraPart = workspace.Cameras:WaitForChild(v.Name.."Camera")
			game.ReplicatedStorage.Remotes.MoveRoom:FireServer(v.Name)
			closeMainContainer()
			if v.Name == "Kitchen" then
				MenuGui.Button.Text = "Food Shop"

			else if v.Name == "Main" then
					MenuGui.Button.Text = "Activities"
				else
					MenuGui.Button.Text = "Hygiene Shop"

				end
			end
		end)
	end
end

MenuGui.Button.MouseButton1Up:Connect(function()
	task.wait(0.1)

	if MainContainer.Visible == true then
		closeMainContainer()
	else
		MenuGui.ExpensesContainer.Visible = true
		MainContainer.Visible = true

		if MenuGui.Button.Text == "Food Shop" then
			MainContainer.FoodFrame.Visible = true
			MainContainer.HygieneFrame.Visible = false
			MainContainer.ActivitiesFrame.Visible = false

		elseif	MenuGui.Button.Text == "Hygiene Shop" then
			MainContainer.HygieneFrame.Visible = true
			MainContainer.FoodFrame.Visible = false
			MainContainer.ActivitiesFrame.Visible = false

		else
			MainContainer.HygieneFrame.Visible = false
			MainContainer.FoodFrame.Visible = false
			MainContainer.ActivitiesFrame.Visible = true

		end
	end
	
	
end)

function closeMainContainer()
	MainContainer.Visible = false
	MenuGui.ExpensesContainer.Visible = false
end

function updateValue(value, amount)
	MenuGui.ExpensesContainer:FindFirstChild(value).Value += amount
	MenuGui.ExpensesContainer:FindFirstChild(value .."Cost").Text = value .. ": $" ..  MenuGui.ExpensesContainer:FindFirstChild(value).Value
	MenuGui.ExpensesContainer.TotalCost.Text = "Total: $" .. (MenuGui.ExpensesContainer.Food.Value + MenuGui.ExpensesContainer.Hygiene.Value + MenuGui.ExpensesContainer.Activities.Value)
end

function InitializeMenus()
	for i, v in (MenuGui.MainContainer.FoodFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v:Destroy()
		end
	end
	
	for i, v in (MenuGui.MainContainer.HygieneFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v:Destroy()
		end
	end
	-- For each model in food folder
	for i, food in (game.ReplicatedStorage.Assets.Food:GetChildren()) do
		local newFood = MainContainer.FoodFrame.Template:Clone()
		local cost =  food:GetAttribute("Cost")
				
		newFood.Visible = true
		newFood.Name = food.Name

		-- handle how much of each item the player has
		if not foodAmount[food] then
			foodAmount[food] = 0
		end
		
		-- initialize new food button
		newFood.Amount.Text = "x" .. foodAmount[food]
		newFood.FoodName.Text = food.Name .. " $" .. cost
		newFood.ImageLabel.Image = food:GetAttribute("Image")
		
		newFood.Parent = MainContainer.FoodFrame

		-- handle user purchase
		newFood.BuyButton.MouseButton1Up:Connect(function()
			if player.PlayerGui.StatsGui.Money.Value >= cost then
				player.PlayerGui.StatsGui.Money.Value -= cost
				foodAmount[food] += 1
				newFood.Amount.Text = "x" .. foodAmount[food]
				updateValue("Food", cost)

			end
		end)

		-- handle user 
		newFood.UseButton.MouseButton1Up:Connect(function()
			if foodAmount[food] > 0 then
				-- tell server to spawn food
				game.ReplicatedStorage.Remotes.GetFood:FireServer(food.Name) 
				foodAmount[food] -= 1
				newFood.Amount.Text = "x" .. foodAmount[food]
			end
		end)
	end
	
	for i, item in (game.ReplicatedStorage.Assets.Hygiene:GetChildren()) do
		local newItem = MainContainer.HygieneFrame.Template:Clone()
		local cost =  item:GetAttribute("Cost")

		newItem.Visible = true
		newItem.Name = item.Name

		if not hygieneAmount[item] then
			hygieneAmount[item] = 0
		end

		newItem.Amount.Text = "x" .. hygieneAmount[item]
		newItem.ItemName.Text = item.Name .. " $" .. cost
		newItem.ImageLabel.Image = item:GetAttribute("Image")

		newItem.Parent = MainContainer.HygieneFrame

		newItem.BuyButton.MouseButton1Up:Connect(function()
			if player.PlayerGui.StatsGui.Money.Value >= cost then
				player.PlayerGui.StatsGui.Money.Value -= cost
				hygieneAmount[item] += 1
				newItem.Amount.Text = "x" .. hygieneAmount[item]
				updateValue("Hygiene", cost)

			end
		end)

		newItem.UseButton.MouseButton1Up:Connect(function()
			if hygieneAmount[item] > 0 then
				game.ReplicatedStorage.Remotes.GetHygiene:FireServer(item.Name)
				hygieneAmount[item] -= 1
				newItem.Amount.Text = "x" .. hygieneAmount[item]
			end
		end)
	end
end


game.ReplicatedStorage.Remotes.InitializePet.OnClientEvent:Connect(function()
	MenuGui.Button.Visible = true
	MenuGui.Kitchen.Visible = true
	MenuGui.Main.Visible = true
	MenuGui.Shower.Visible = true
	InitializeMenus()

end)

CookingGameFrame.BuyButton.MouseButton1Up:Connect(function()
	if player.PlayerGui.StatsGui.Money.Value >= 10 then
		player.PlayerGui.StatsGui.Money.Value -= 10
		MainContainer.ActivitiesFrame.CookingUse.Value += 1
		CookingGameFrame.Amount.Text = "x" .. MainContainer.ActivitiesFrame.CookingUse.Value
		updateValue("Activities", 10)

	end
end)

BounceGameFrame.BuyButton.MouseButton1Up:Connect(function()
	if player.PlayerGui.StatsGui.Money.Value >= 10 then
		player.PlayerGui.StatsGui.Money.Value -= 10
		MainContainer.ActivitiesFrame.BounceUse.Value += 1
		BounceGameFrame.Amount.Text = "x" .. MainContainer.ActivitiesFrame.BounceUse.Value
		updateValue("Activities", 10)

	end
end)
