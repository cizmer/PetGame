local currGame = nil

local MenusGui = script.Parent
local CookingGame = MenusGui.CookingGame

local CookingGameFrame = MenusGui.MainContainer.ActivitiesFrame.Cooking
local BounceGameFrame = MenusGui.MainContainer.ActivitiesFrame.Bounce

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local countdownTween = TweenService:Create(CookingGame.Countdown, tweenInfo, {Position = UDim2.new(0.371, 0,0.299, 0)})

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local StateHandler = require(game.ReplicatedStorage.Modules.StateHandler)

local foodImages = {
	"rbxassetid://95363253437108",
	"rbxassetid://140150520312731",
	"rbxassetid://118914036212467",
	"rbxassetid://97646338215741",
	"rbxassetid://95607744675208",
	"rbxassetid://93928425749486"
}

local waited = 0
local cooldown = math.random(70, 120) / 100
local GAME_DURATION = 15
local currTime = 0
local coinsEarned = 0

function newFood()
	local foodImage = CookingGame.Template:Clone()
	foodImage.Image = foodImages[math.random(1, #foodImages)]
	foodImage.Parent = CookingGame
	foodImage.Visible = true
	fallingFood(foodImage)
	
end

function fallingFood(food : ImageButton)
	task.spawn(function()
		local x = math.random(20, 80) / 100
		local waitRate = math.random(1, 4) / 100
		food.Position = UDim2.fromScale(x, -0.1)
		food:AddTag("Temp")
		
		while food.Position.Y.Scale < 1.1 and currGame == "cooking" do
			print(math.abs((food.AbsolutePosition.X - CookingGame.Pot.AbsolutePosition.X)) )
			if math.abs((food.AbsolutePosition.X - CookingGame.Pot.AbsolutePosition.X)) <= 130 and food.Position.Y.Scale >= 0.6 then
				food:Destroy()
				coinsEarned += 3
				CookingGame.Earned.Text = coinsEarned
				break
			end
			food.Position = UDim2.fromScale(x, food.Position.Y.Scale + 0.01)
			task.wait(waitRate)
		end
		
		food:Destroy()
	end)
end

CookingGame.GameOverContainer.Return.MouseButton1Up:Connect(function()
	CookingGame.Visible = false
end)

function InitializeCookingGame()
	CookingGame.Transparency = 1
	CookingGame.Visible = true
	
	currTime = GAME_DURATION
	coinsEarned = 0
	CookingGame.TimeLabel.Text = currTime
	CookingGame.Earned.Text = coinsEarned
	
	CookingGame.GameOverContainer.Visible = false
	CookingGame.Countdown.Visible = true

	TweenService:Create(CookingGame, tweenInfo, {Transparency = 0}):Play()

	for i = 3, 0, -1 do
		countdownTween:Cancel()
		CookingGame.Countdown.Position = UDim2.new(0.371, 0,0.31, 0)
		countdownTween:Play()
		CookingGame.Countdown.Text = i
		task.wait(1)
	end
	
	CookingGame.TimeLabel.Visible = true
	CookingGame.Countdown.Visible = false

	currGame = "cooking"

	task.spawn(function()
		task.wait(1)
		
		while currTime > 0 do
			currTime -=1
			CookingGame.TimeLabel.Text = currTime
			task.wait(1)
		end

		currGame = nil
		for i,v in (CookingGame:GetChildren()) do
			if v:HasTag("Temp") then
				v:Destroy()
			end
		end

		CookingGame.GameOverContainer.Visible = true
		CookingGame.TimeLabel.Visible = false
		CookingGame.GameOverContainer.PrizeText.Text = "You earned " .. coinsEarned .. " coins"
	end)

	while currGame == "cooking" do
		waited += 0.05
		if (waited >= cooldown) then
			newFood()
			waited = 0
		end
		CookingGame.Pot.Position = UDim2.new(0, mouse.X, 0.629, 0)
		task.wait(0.05)
	end
	
	player.PlayerGui.StatsGui.Money.Value += coinsEarned
	player.PlayerGui.StatsGui.MoneyContainer.MoneyText.Text = player.PlayerGui.StatsGui.Money.Value
	CookingGameFrame.UseButton.Interactable = true
end

CookingGameFrame.UseButton.MouseButton1Up:Connect(function()
	if CookingGameFrame.Parent.CookingUse.Value > 0 then
		CookingGameFrame.UseButton.Interactable = false
		CookingGameFrame.Parent.CookingUse.Value -= 1
		CookingGameFrame.Amount.Text = "x" .. CookingGameFrame.Parent.CookingUse.Value
		task.wait(0.5)
		InitializeCookingGame()
		StateHandler.SetState("Playing", 35)
		player.PlayerGui.StatsGui.Happiness.Value += 10
	end
end)