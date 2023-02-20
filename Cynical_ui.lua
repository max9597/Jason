local services = setmetatable({}, {
    __index = function(index, service)
        return game:GetService(service)
    end,
    __newindex = function(index, value)
        index[value] = nil
        return
    end
});

local theme = (getgenv()).theme or {
    Color3.fromRGB(34, 34, 34),
    Color3.fromRGB(37, 37, 37),
    Color3.fromRGB(243, 18, 221),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(214, 214, 214),
    Color3.fromRGB(66, 66, 66),
};
local library = {};
library.flags = {};
library.objstorage = {};
library.funcstorage = {};
library.binds = {};
library.binding = false;
library.tabinfo = { button = nil, tab = nil };
library.destroyed = false;
local function isreallypressed(bind, inp)
    local key = bind;
    if typeof(key) == "Instance" then
        if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
            return true;
        elseif (tostring(key.UserInputType)):find("MouseButton") and inp.UserInputType == key.UserInputType then
            return true;
        end;
    end;
    if (tostring(key)):find("MouseButton1") then
        return key == inp.UserInputType;
    else
        return key == inp.KeyCode;
    end;
end;
pcall(function()
    services.UserInputService.InputBegan:Connect(function(input, gp)
        if library.destroyed then
            return;
        end;
        if gp then
 
        else
            if not library.binding then
                for idx, binds in next, library.binds do
                    local real_binding = binds.location[idx];
                    if real_binding and isreallypressed(real_binding, input) then
                        binds.callback();
                    end;
                end;
            end;
        end;
    end);
end);
local mouse = services.Players.LocalPlayer:GetMouse();
local utils = {};
function utils.Tween(self, obj, t, data)
    (services.TweenService:Create(obj, TweenInfo.new(t[1], Enum.EasingStyle[t[2]], Enum.EasingDirection[t[3]]), data)):Play();
    return true;
end;
function utils.Ripple(self, obj)
    spawn(function()
        if obj.ClipsDescendants ~= true then
            obj.ClipsDescendants = true;
        end;
        local Ripple = Instance.new("ImageLabel");
        Ripple.Name = "Ripple";
        Ripple.Parent = obj;
        Ripple.BackgroundColor3 = theme[4];
        Ripple.BackgroundTransparency = 1;
        Ripple.ZIndex = 8;
        Ripple.Image = "rbxassetid://2708891598";
        Ripple.ImageTransparency = .8;
        Ripple.ScaleType = Enum.ScaleType.Fit;
        Ripple.ImageColor3 = theme[3];
        Ripple.Position = UDim2.new((mouse.X - Ripple.AbsolutePosition.X) / obj.AbsoluteSize.X, 0, (mouse.Y - Ripple.AbsolutePosition.Y) / obj.AbsoluteSize.Y, 0);
        self:Tween(Ripple, { .3, "Linear", "InOut" }, { Position = UDim2.new(-5.5, 0, -5.5, 0), Size = UDim2.new(12, 0, 12, 0) });
        wait(.15);
        self:Tween(Ripple, { .3, "Linear", "InOut" }, { ImageTransparency = 1 });
        wait(.3);
        Ripple:Destroy();
    end);
end;
library.ChangingTab = false;
function utils.ChangeTab(self, newData)
    if library.ChangingTab then
        return;
    end;
    local btn, tab = newData[1], newData[2];
    if not btn or not tab then
        return;
    end;
    if library.tabinfo.button == btn then
        return;
    end;
    library.ChangingTab = true;
    local oldbtn, oldtab = library.tabinfo.button, library.tabinfo.tab;
    library.tabinfo = { button = btn, tab = tab };
    utils:Tween(oldbtn, { .2, "Sine", "InOut" }, { TextColor3 = theme[5], BorderColor3 = theme[6] });
    oldtab.Visible = false;
    tab.Visible = true;
    utils:Tween(btn, { .2, "Sine", "InOut" }, { TextColor3 = theme[4], BorderColor3 = theme[3] });
    library.ChangingTab = false;
end;
function utils.MakeDraggable(self, frame, hold)
    if not hold then
        hold = frame;
    end;
    local dragging;
    local dragInput;
    local dragStart;
    local startPos;
    local function update(input)
        local delta = input.Position - dragStart;
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
    end;
    hold.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true;
            dragStart = input.Position;
            startPos = frame.Position;
            boxDrag = false;
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false;
                    boxDrag = true;
                end;
            end);
        end;
    end);
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input;
        end;
    end);
    services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input);
        end;
    end);
end;
function library.UpdateSlider(self, flag, value, min, max, precise)
    local slider = self.objstorage[flag];
    local bar = slider.SliderBar;
    local box = slider.SliderHolder.SliderVal;
    local percent = (mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X;
    if value then
        percent = (value - min) / (max - min);
    end;
    percent = math.clamp(percent, 0, 1);
    if precise then
        value = value or tonumber(tostring(string.format("%.2f", min + (max - min) * percent)));
    else
        value = value or math.floor(min + (max - min) * percent);
    end;
    library.flags[flag] = value;
    --if GuiSettings[flag] ~= nil then
        --GuiSettings[flag] = value;
    --end;
    box.Text = tostring(value);
    utils:Tween(bar.SliderFill, { .05, "Linear", "InOut" }, { Size = UDim2.new(percent, 0, 1, 0) });
    self.funcstorage[flag](tonumber(value));
    return tonumber(value);
end;
function library.UpdateToggle(self, flag, value)
    if not library.objstorage[flag] then
        return;
    end;
    local oldval = library.flags[flag];
    local obj = library.objstorage[flag];
    local func = library.funcstorage[flag];
    if oldval == value then
        return;
    end;
    if not value then
        value = not oldval;
    end;
    library.flags[flag] = value;
    --if GuiSettings[flag] ~= nil then
        --GuiSettings[flag] = value;
    --end;
    local fill = obj.ToggleDisplay.ToggleSwitch;
    local toggleoff = UDim2.new(0, 3, .5, 0);
    local toggleon = UDim2.new(0, 16, .5, 0);
    local toggleval = value and toggleon or toggleoff;
    utils:Tween(fill, { .15, "Sine", "InOut" }, { Position = toggleval, BackgroundColor3 = value and theme[3] or theme[1] });
    spawn(function()
        func(value);
    end);
end;
function library.CreateUI(self, propTbl)
    local propTbl = propTbl or {};
    local projectName = propTbl.ProjectName or "UILibrary";
    local uiTitle = propTbl.UiText or "UI Library";
    self.ProjectName = projectName;
    local CynicalLite = Instance.new("ScreenGui");
    local Drag = Instance.new("Frame");
    local DragC = Instance.new("UICorner");
    local DragHold = Instance.new("Frame");
    local Main = Instance.new("Frame");
    local MainC = Instance.new("UICorner");
    local SideBar = Instance.new("Frame");
    local SideBarC = Instance.new("UICorner");
    local Title = Instance.new("TextLabel");
    local TBtns = Instance.new("ScrollingFrame");
    local TBtnsL = Instance.new("UIListLayout");
    local TBtnsP = Instance.new("UIPadding");
    local TabHolder = Instance.new("Frame");
    local TabHolderC = Instance.new("UICorner");
    local Notifications = Instance.new("Frame");
    local NotificationsL = Instance.new("UIListLayout");
    library.UiParent = (function()
        return services.CoreGui;
    end)();
    CynicalLite.Name = self.ProjectName;
    CynicalLite.Parent = library.UiParent;
    CynicalLite.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    library.ui = CynicalLite;
    Drag.Name = "Drag";
    Drag.Parent = CynicalLite;
    Drag.BackgroundColor3 = theme[1];
    Drag.BorderSizePixel = 0;
    Drag.Position = UDim2.new(.235238984, 0, .119544595, 0);
    Drag.Size = UDim2.new(0, 564, 0, 400);
    DragHold.Name = "DragHold";
    DragHold.Parent = Drag;
    DragHold.BackgroundTransparency = 1;
    DragHold.ZIndex = 69;
    DragHold.Position = UDim2.new(0, 0, 0, 0);
    DragHold.Size = UDim2.new(1, 0, 0, 30);
    DragHold.BorderSizePixel = 0;
    utils:MakeDraggable(Drag, DragHold);
    Notifications.Name = "Notifications";
    Notifications.Parent = Drag;
    Notifications.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
    Notifications.BackgroundTransparency = 1;
    Notifications.BorderSizePixel = 0;
    Notifications.Position = UDim2.new(1.02304959, 0, 0, 0);
    Notifications.Size = UDim2.new(0, 207, 0, 400);
    NotificationsL.Name = "lol";
    NotificationsL.Parent = Notifications;
    NotificationsL.HorizontalAlignment = Enum.HorizontalAlignment.Left;
    NotificationsL.SortOrder = Enum.SortOrder.LayoutOrder;
    NotificationsL.Padding = UDim.new(0, 4);
    DragC.Name = "DragC";
    DragC.Parent = Drag;
    Main.Name = "Main";
    Main.Parent = Drag;
    Main.BackgroundColor3 = theme[2];
    Main.BorderSizePixel = 0;
    Main.Position = UDim2.new(.011406865, 0, .0149999997, 0);
    Main.Size = UDim2.new(0, 551, 0, 390);
    MainC.Name = "MainC";
    MainC.Parent = Main;
    SideBar.Name = "SideBar";
    SideBar.Parent = Main;
    SideBar.BackgroundColor3 = theme[1];
    SideBar.BorderSizePixel = 0;
    SideBar.Position = UDim2.new(.0108892918, 0, .0154639175, 0);
    SideBar.Size = UDim2.new(0, 126, 0, 376);
    SideBarC.Name = "SideBarC";
    SideBarC.Parent = SideBar;
    Title.Name = "Title";
    Title.Parent = SideBar;
    Title.BackgroundColor3 = theme[4];
    Title.BackgroundTransparency = 1;
    Title.Size = UDim2.new(0, 126, 0, 32);
    Title.Font = Enum.Font.GothamBold;
    Title.Text = uiTitle;
    Title.TextColor3 = theme[4];
    Title.TextSize = 16;
    TBtns.Name = "TBtns";
    TBtns.Parent = SideBar;
    TBtns.Active = true;
    TBtns.BackgroundColor3 = theme[4];
    TBtns.BackgroundTransparency = 1;
    TBtns.Position = UDim2.new(0, 0, .0851063803, 0);
    TBtns.Size = UDim2.new(0, 126, 0, 344);
    TBtns.ScrollBarThickness = 0;
    TBtnsL.Name = "TBtnsL";
    TBtnsL.Parent = TBtns;
    TBtnsL.HorizontalAlignment = Enum.HorizontalAlignment.Center;
    TBtnsL.SortOrder = Enum.SortOrder.LayoutOrder;
    TBtnsP.Name = "TBtnsP";
    TBtnsP.Parent = TBtns;
    TBtnsP.PaddingTop = UDim.new(0, 4);
    TabHolder.Name = "TabHolder";
    TabHolder.Parent = Main;
    TabHolder.BackgroundColor3 = theme[1];
    TabHolder.BorderSizePixel = 0;
    TabHolder.Position = UDim2.new(.246823952, 0, .0154639175, 0);
    TabHolder.Size = UDim2.new(0, 409, 0, 376);
    TabHolderC.Name = "TabHolderC";
    TabHolderC.Parent = TabHolder;
    (TBtnsL:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
        TBtns.CanvasSize = UDim2.new(0, 0, 0, TBtnsL.AbsoluteContentSize.Y + 4);
    end);
    local Modules = {};
    function library.CreateNotification(self, Title, Description, Duration, CanClose)
        local Title = Title or "Hello, World!";
        local Description = Description or "Hello, World!";
        local CanClose = CanClose or false;
        local Notification = Instance.new("Frame");
        local NotificationC = Instance.new("UICorner");
        local NotificationTitle = Instance.new("TextLabel");
        local NotificationText = Instance.new("TextLabel");
        local NotiHolder = Instance.new("Frame");
        local NotiHolderL = Instance.new("UIListLayout");
        local Close = Instance.new("TextButton");
        Notification.Name = "Notification";
        Notification.Parent = Notifications;
        Notification.BackgroundColor3 = Color3.fromRGB(37, 37, 37);
        Notification.BorderSizePixel = 0;
        Notification.ClipsDescendants = true;
        Notification.Size = UDim2.new(0, 140, 0, 0);
        NotificationC.CornerRadius = UDim.new(0, 4);
        NotificationC.Name = "NotificationC";
        NotificationC.Parent = Notification;
        NotificationTitle.Name = "NotificationTitle";
        NotificationTitle.Parent = Notification;
        NotificationTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
        NotificationTitle.BackgroundTransparency = 1;
        NotificationTitle.BorderSizePixel = 0;
        NotificationTitle.Size = UDim2.new(0, 235, 0, 26);
        NotificationTitle.Font = Enum.Font.GothamBold;
        NotificationTitle.Text = "  " .. Title;
        NotificationTitle.TextColor3 = Color3.fromRGB(255, 255, 255);
        NotificationTitle.TextSize = 14;
        NotificationTitle.TextXAlignment = Enum.TextXAlignment.Left;
        NotificationText.Name = "NotificationText";
        NotificationText.Parent = Notification;
        NotificationText.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
        NotificationText.BackgroundTransparency = 1;
        NotificationText.BorderSizePixel = 0;
        NotificationText.Position = UDim2.new(0, 0, .519841313, 0);
        NotificationText.Size = UDim2.new(0, 253, 0, 22);
        NotificationText.Font = Enum.Font.Gotham;
        NotificationText.Text = "  " .. Description;
        NotificationText.TextColor3 = Color3.fromRGB(255, 255, 255);
        NotificationText.TextSize = 14;
        NotificationText.TextXAlignment = Enum.TextXAlignment.Left;
        NotificationText.Size = UDim2.new(0, NotificationText.TextBounds.X, 0, 22);
        local newX;
        if NotificationText.TextBounds.X > 100 then
            newX = NotificationText.TextBounds.X + 40;
            Notification.Size = UDim2.new(0, newX, 0, 0);
        end;
        NotiHolder.Name = "NotiHolder";
        NotiHolder.Parent = Notification;
        NotiHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
        NotiHolder.BackgroundTransparency = 1;
        NotiHolder.BorderSizePixel = 0;
        NotiHolder.Size = UDim2.new(1, 0, 1, 0);
        NotiHolderL.Name = "NotiHolderL";
        NotiHolderL.Parent = NotiHolder;
        NotiHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        NotiHolderL.SortOrder = Enum.SortOrder.LayoutOrder;
        NotiHolderL.Padding = UDim.new(0, 4);
        local closed = false;
        local function closeNotification()
            if closed then
                return;
            end;
            utils:Tween(Notification, { .2, "Sine", "InOut" }, { Size = UDim2.new(0, NotificationText.Size.X, 0, 56) });
            wait(.22);
            Notification:Destroy();
        end;
        if CanClose then
            Close.Name = "Close";
            Close.Parent = NotiHolder;
            Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
            Close.BackgroundTransparency = 1;
            Close.Position = UDim2.new(.90216887, 0, 0, 0);
            Close.Size = UDim2.new(0, 26, 0, 26);
            Close.Font = Enum.Font.GothamBold;
            Close.Text = "X";
            Close.TextColor3 = Color3.fromRGB(255, 255, 255);
            Close.TextSize = 14;
            Close.MouseButton1Click:Connect(closeNotification);
        end;
        utils:Tween(Notification, { .2, "Sine", "InOut" }, { Size = UDim2.new(0, newX, 0, 56) });
        wait(Duration);
        closeNotification();
    end;
    function Modules.CreateCategory(self, TabName)
        local TabName = TabName or "Tab";
        local Tab = Instance.new("ScrollingFrame");
        local TabL = Instance.new("UIListLayout");
        local TabP = Instance.new("UIPadding");
        local TabOpenBtn = Instance.new("TextButton");
        TabOpenBtn.Name = "TabOpenBtn";
        TabOpenBtn.Parent = TBtns;
        TabOpenBtn.BackgroundColor3 = theme[1];
        TabOpenBtn.BorderColor3 = theme[6];
        TabOpenBtn.Position = UDim2.new(-0.209677413, 0, .0116279069, 0);
        TabOpenBtn.Size = UDim2.new(0, 176, 0, 30);
        TabOpenBtn.AutoButtonColor = false;
        TabOpenBtn.Font = Enum.Font.Gotham;
        TabOpenBtn.Text = TabName;
        TabOpenBtn.TextColor3 = theme[4];
        TabOpenBtn.TextSize = 14;
        TabOpenBtn.BorderMode = Enum.BorderMode.Inset;
        Tab.Name = "Tab";
        Tab.Parent = TabHolder;
        Tab.BackgroundColor3 = theme[4];
        Tab.BackgroundTransparency = 1;
        Tab.Size = UDim2.new(0, 409, 0, 376);
        Tab.ScrollBarThickness = 0;
        Tab.Visible = false;
        TabL.Name = "TabL";
        TabL.Parent = Tab;
        TabL.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        TabL.SortOrder = Enum.SortOrder.LayoutOrder;
        TabL.Padding = UDim.new(0, 4);
        TabP.Name = "TabP";
        TabP.Parent = Tab;
        TabP.PaddingTop = UDim.new(0, 4);
        if not library.tabinfo.button then
            library.tabinfo = { button = TabOpenBtn, tab = Tab };
            TabOpenBtn.BorderColor3 = theme[3];
            Tab.Visible = true;
        end;
        TabOpenBtn.MouseButton1Click:Connect(function()
            utils:Ripple(TabOpenBtn);
            utils:ChangeTab({ TabOpenBtn, Tab });
        end);
        (TabL:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
            Tab.CanvasSize = UDim2.new(0, 0, 0, TabL.AbsoluteContentSize.Y + 8);
        end);
        local secs = {};
        function secs.CreateSection(self, SecName)
            local SecName = SecName or "Section";
            local Section = Instance.new("Frame");
            local SectionC = Instance.new("UICorner");
            local SectionText = Instance.new("TextLabel");
            local SectionL = Instance.new("UIListLayout");
            Section.Name = "Section";
            Section.Parent = Tab;
            Section.BackgroundColor3 = theme[2];
            Section.BorderSizePixel = 0;
            Section.Position = UDim2.new(.0110024447, 0, -0.787234068, 0);
            Section.Size = UDim2.new(0, 400, 0, 534);
            SectionC.Name = "SectionC";
            SectionC.Parent = Section;
            SectionText.Name = "SectionText";
            SectionText.Parent = Section;
            SectionText.BackgroundColor3 = theme[4];
            SectionText.BackgroundTransparency = 1;
            SectionText.Position = UDim2.new(-0.230000004, 0, 0, 0);
            SectionText.Size = UDim2.new(1, 0, 0, 32);
            SectionText.Font = Enum.Font.GothamBold;
            SectionText.Text = "  " .. SecName;
            SectionText.TextColor3 = theme[4];
            SectionText.TextSize = 16;
            SectionText.TextXAlignment = Enum.TextXAlignment.Left;
            SectionL.Name = "SectionL";
            SectionL.Parent = Section;
            SectionL.HorizontalAlignment = Enum.HorizontalAlignment.Center;
            SectionL.SortOrder = Enum.SortOrder.LayoutOrder;
            SectionL.Padding = UDim.new(0, 4);
            (SectionL:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
                Section.Size = UDim2.new(0, 400, 0, SectionL.AbsoluteContentSize.Y + 8);
            end);
            local Modules = {};
            function Modules.Create(self, Object, Text, Callback, Options)
                local Text = Text or "Text";
                local Options = Options or {};
                local Callback = Callback or function()
 
                end;
                if Object:lower() == "button" then
                    local ButtonMain = Instance.new("Frame");
                    local ButtonMainC = Instance.new("UICorner");
                    local ButtonText = Instance.new("TextLabel");
                    local BtnHolder = Instance.new("Frame");
                    local BtnHolderL = Instance.new("UIListLayout");
                    local Btn = Instance.new("TextButton");
                    local BtnC = Instance.new("UICorner");
                    local BtnInfo = Instance.new("TextButton");
                    local BtnInfoC = Instance.new("UICorner");
                    ButtonMain.Name = "ButtonMain";
                    ButtonMain.Parent = Section;
                    ButtonMain.BackgroundColor3 = theme[1];
                    ButtonMain.BorderSizePixel = 0;
                    ButtonMain.Position = UDim2.new(.00875000004, 0, .189473689, 0);
                    ButtonMain.Size = UDim2.new(0, 393, 0, 36);
                    ButtonMainC.CornerRadius = UDim.new(0, 4);
                    ButtonMainC.Name = "ButtonMainC";
                    ButtonMainC.Parent = ButtonMain;
                    ButtonText.Name = "ButtonText";
                    ButtonText.Parent = ButtonMain;
                    ButtonText.BackgroundColor3 = theme[4];
                    ButtonText.BackgroundTransparency = 1;
                    ButtonText.Position = UDim2.new(0, 0, 2.11927627e-007, 0);
                    ButtonText.Size = UDim2.new(.335000008, 0, 1, 0);
                    ButtonText.Font = Enum.Font.Gotham;
                    ButtonText.Text = "   " .. Text;
                    ButtonText.TextColor3 = theme[4];
                    ButtonText.TextSize = 14;
                    ButtonText.TextXAlignment = Enum.TextXAlignment.Left;
                    BtnHolder.Name = "BtnHolder";
                    BtnHolder.Parent = ButtonMain;
                    BtnHolder.BackgroundColor3 = theme[4];
                    BtnHolder.BackgroundTransparency = 1;
                    BtnHolder.BorderSizePixel = 0;
                    BtnHolder.Position = UDim2.new(.735000014, 0, 0, 0);
                    BtnHolder.Size = UDim2.new(0, 100, 0, 36);
                    BtnHolderL.Name = "BtnHolderL";
                    BtnHolderL.Parent = BtnHolder;
                    BtnHolderL.FillDirection = Enum.FillDirection.Horizontal;
                    BtnHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    BtnHolderL.SortOrder = Enum.SortOrder.LayoutOrder;
                    BtnHolderL.VerticalAlignment = Enum.VerticalAlignment.Center;
                    BtnHolderL.Padding = UDim.new(0, 4);
                    Btn.Name = "Btn";
                    Btn.Parent = BtnHolder;
                    Btn.BackgroundColor3 = theme[2];
                    Btn.BorderSizePixel = 0;
                    Btn.Position = UDim2.new(.735000014, 0, .111000001, 0);
                    Btn.Size = UDim2.new(0, 100, 0, 28);
                    Btn.AutoButtonColor = false;
                    Btn.Font = Enum.Font.Gotham;
                    Btn.Text = Options.BtnText or "Click Here!";
                    Btn.TextColor3 = theme[4];
                    Btn.TextSize = 14;
                    BtnC.CornerRadius = UDim.new(0, 4);
                    BtnC.Name = "BtnC";
                    BtnC.Parent = Btn;
                    BtnInfo.Name = "BtnInfo";
                    BtnInfo.Parent = BtnHolder;
                    BtnInfo.BackgroundColor3 = theme[2];
                    BtnInfo.BorderSizePixel = 0;
                    BtnInfo.Position = UDim2.new(.720000029, 0, .111111112, 0);
                    BtnInfo.Size = UDim2.new(0, 28, 0, 28);
                    BtnInfo.AutoButtonColor = false;
                    BtnInfo.Font = Enum.Font.Gotham;
                    BtnInfo.Text = "?";
                    BtnInfo.TextColor3 = theme[4];
                    BtnInfo.TextSize = 20;
                    BtnInfoC.CornerRadius = UDim.new(0, 4);
                    BtnInfoC.Name = "BtnInfoC";
                    BtnInfoC.Parent = BtnInfo;
                    Btn.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(Btn);
                        end);
                        Callback();
                    end);
                    local desc = Options.Description or "No info for this function found!";
                    BtnInfo.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(BtnInfo);
                        end);
                        library:CreateNotification(Text, desc, 10000, true);
                    end);
                    return ButtonMain;
                end;
                if Object:lower() == "toggle" then
                    local ToggleMain = Instance.new("Frame");
                    local ToggleMainC = Instance.new("UICorner");
                    local ToggleText = Instance.new("TextLabel");
                    local ToggleDisplay = Instance.new("Frame");
                    local ToggleDisplayC = Instance.new("UICorner");
                    local ToggleSwitch = Instance.new("TextButton");
                    local ToggleSwitchC = Instance.new("UICorner");
                    local ToggleInfo = Instance.new("TextButton");
                    local ToggleInfoC = Instance.new("UICorner");
                    library.flags[Options.Flag] = Options.Default or false;
                    library.objstorage[Options.Flag] = ToggleMain;
                    library.funcstorage[Options.Flag] = Callback;
                    ToggleMain.Name = "ToggleMain";
                    ToggleMain.Parent = Section;
                    ToggleMain.BackgroundColor3 = theme[1];
                    ToggleMain.BorderSizePixel = 0;
                    ToggleMain.Position = UDim2.new(.00875000004, 0, .189473689, 0);
                    ToggleMain.Size = UDim2.new(0, 393, 0, 36);
                    ToggleMainC.CornerRadius = UDim.new(0, 4);
                    ToggleMainC.Name = "ToggleMainC";
                    ToggleMainC.Parent = ToggleMain;
                    ToggleText.Name = "ToggleText";
                    ToggleText.Parent = ToggleMain;
                    ToggleText.BackgroundColor3 = theme[4];
                    ToggleText.BackgroundTransparency = 1;
                    ToggleText.Size = UDim2.new(.335000008, 0, 1, 0);
                    ToggleText.Font = Enum.Font.Gotham;
                    ToggleText.Text = "   " .. Text;
                    ToggleText.TextColor3 = theme[4];
                    ToggleText.TextSize = 14;
                    ToggleText.TextXAlignment = Enum.TextXAlignment.Left;
                    ToggleDisplay.Name = "ToggleDisplay";
                    ToggleDisplay.Parent = ToggleMain;
                    ToggleDisplay.BackgroundColor3 = theme[2];
                    ToggleDisplay.BorderSizePixel = 0;
                    ToggleDisplay.Position = UDim2.new(.78371501, 0, .111111112, 0);
                    ToggleDisplay.Size = UDim2.new(0, 48, 0, 28);
                    ToggleDisplayC.CornerRadius = UDim.new(0, 4);
                    ToggleDisplayC.Name = "ToggleDisplayC";
                    ToggleDisplayC.Parent = ToggleDisplay;
                    ToggleSwitch.Name = "ToggleSwitch";
                    ToggleSwitch.Parent = ToggleDisplay;
                    ToggleSwitch.AnchorPoint = Vector2.new(0, .5);
                    ToggleSwitch.BackgroundColor3 = theme[1];
                    ToggleSwitch.BorderSizePixel = 0;
                    ToggleSwitch.Position = library.flags[Options.Flag] and UDim2.new(0, 16, .5, 0) or UDim2.new(0, 3, .5, 0);
                    ToggleSwitch.Size = UDim2.new(0, 28, 0, 22);
                    ToggleSwitch.AutoButtonColor = false;
                    ToggleSwitch.Text = "";
                    ToggleSwitchC.CornerRadius = UDim.new(0, 4);
                    ToggleSwitchC.Name = "ToggleSwitchC";
                    ToggleSwitchC.Parent = ToggleSwitch;
                    ToggleInfo.Name = "ToggleInfo";
                    ToggleInfo.Parent = ToggleMain;
                    ToggleInfo.BackgroundColor3 = theme[2];
                    ToggleInfo.BorderSizePixel = 0;
                    ToggleInfo.Position = UDim2.new(.918206036, 0, .111111112, 0);
                    ToggleInfo.Size = UDim2.new(0, 28, 0, 28);
                    ToggleInfo.AutoButtonColor = false;
                    ToggleInfo.Font = Enum.Font.Gotham;
                    ToggleInfo.Text = "?";
                    ToggleInfo.TextColor3 = theme[4];
                    ToggleInfo.TextSize = 20;
                    ToggleInfo.TextWrapped = true;
                    ToggleInfoC.CornerRadius = UDim.new(0, 4);
                    ToggleInfoC.Name = "ToggleInfoC";
                    ToggleInfoC.Parent = ToggleInfo;
                    if library.flags[Options.Flag] == true then
                        Callback();
                    end;
                    ToggleSwitch.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(ToggleSwitch);
                        end);
                        library:UpdateToggle(Options.Flag);
                    end);
                    local desc = Options.Description or "No info for this function found!";
                    ToggleInfo.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(ToggleInfo);
                        end);
                        library:CreateNotification(Text, desc, 10000, true);
                    end);
                    return ToggleMain;
                end;
                if Object:lower() == "label" then
                    local Label = Instance.new("TextLabel");
                    Label.Name = "Label";
                    Label.Parent = Section;
                    Label.BackgroundColor3 = theme[4];
                    Label.BackgroundTransparency = 1;
                    Label.Position = UDim2.new(.33255738, 0, .754098356, 0);
                    Label.Size = UDim2.new(1, 0, 0, 32);
                    Label.Font = Enum.Font.Gotham;
                    Label.Text = "    " .. Text;
                    Label.TextColor3 = theme[4];
                    Label.TextSize = 14;
                    Label.TextXAlignment = Enum.TextXAlignment.Left;
                    return Label;
                end;
                if Object:lower() == "textbox" then
                    local TextboxMain = Instance.new("Frame");
                    local TextboxText = Instance.new("TextLabel");
                    local BoxHolderMain = Instance.new("Frame");
                    local BoxHolderMainL = Instance.new("UIListLayout");
                    local TextBox = Instance.new("TextBox");
                    local TextboxC = Instance.new("UICorner");
                    local BoxInfo = Instance.new("TextButton");
                    local BoxInfoC = Instance.new("UICorner");
                    local TextboxMainC = Instance.new("UICorner");
                    library.flags[Options.Flag] = Options.Default or "Text";
                    TextboxMain.Name = "TextboxMain";
                    TextboxMain.Parent = Section;
                    TextboxMain.BackgroundColor3 = theme[1];
                    TextboxMain.BorderSizePixel = 0;
                    TextboxMain.Position = UDim2.new(.00875000004, 0, .189473689, 0);
                    TextboxMain.Size = UDim2.new(0, 393, 0, 36);
                    TextboxText.Name = "TextboxText";
                    TextboxText.Parent = TextboxMain;
                    TextboxText.BackgroundColor3 = theme[4];
                    TextboxText.BackgroundTransparency = 1;
                    TextboxText.Position = UDim2.new(0, 0, 2.11927627e-007, 0);
                    TextboxText.Size = UDim2.new(.335000008, 0, 1, 0);
                    TextboxText.Font = Enum.Font.Gotham;
                    TextboxText.Text = "   " .. Text;
                    TextboxText.TextColor3 = theme[4];
                    TextboxText.TextSize = 14;
                    TextboxText.TextXAlignment = Enum.TextXAlignment.Left;
                    BoxHolderMain.Name = "BoxHolderMain";
                    BoxHolderMain.Parent = TextboxMain;
                    BoxHolderMain.BackgroundColor3 = theme[4];
                    BoxHolderMain.BackgroundTransparency = 1;
                    BoxHolderMain.BorderSizePixel = 0;
                    BoxHolderMain.Position = UDim2.new(.735000014, 0, 0, 0);
                    BoxHolderMain.Size = UDim2.new(0, 100, 0, 36);
                    BoxHolderMainL.Name = "BoxHolderMainL";
                    BoxHolderMainL.Parent = BoxHolderMain;
                    BoxHolderMainL.FillDirection = Enum.FillDirection.Horizontal;
                    BoxHolderMainL.HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    BoxHolderMainL.SortOrder = Enum.SortOrder.LayoutOrder;
                    BoxHolderMainL.VerticalAlignment = Enum.VerticalAlignment.Center;
                    BoxHolderMainL.Padding = UDim.new(0, 4);
                    TextBox.Parent = BoxHolderMain;
                    TextBox.BackgroundColor3 = theme[2];
                    TextBox.BorderSizePixel = 0;
                    TextBox.Position = UDim2.new(0, 0, .111111112, 0);
                    TextBox.Size = UDim2.new(0, 100, 0, 28);
                    TextBox.Font = Enum.Font.Gotham;
                    TextBox.Text = library.flags[Options.Flag];
                    TextBox.TextColor3 = theme[4];
                    TextBox.TextSize = 14;
                    TextBox.Size = UDim2.new(0, TextBox.TextBounds.X + 18, 0, 26);
                    TextboxC.CornerRadius = UDim.new(0, 4);
                    TextboxC.Name = "TextboxC";
                    TextboxC.Parent = TextBox;
                    BoxInfo.Name = "BoxInfo";
                    BoxInfo.Parent = BoxHolderMain;
                    BoxInfo.BackgroundColor3 = theme[2];
                    BoxInfo.BorderSizePixel = 0;
                    BoxInfo.Position = UDim2.new(.918206036, 0, .111111112, 0);
                    BoxInfo.Size = UDim2.new(0, 28, 0, 28);
                    BoxInfo.AutoButtonColor = false;
                    BoxInfo.Font = Enum.Font.Gotham;
                    BoxInfo.Text = "?";
                    BoxInfo.TextColor3 = theme[4];
                    BoxInfo.TextSize = 20;
                    BoxInfo.TextWrapped = true;
                    BoxInfoC.CornerRadius = UDim.new(0, 4);
                    BoxInfoC.Name = "BoxInfoC";
                    BoxInfoC.Parent = BoxInfo;
                    TextboxMainC.CornerRadius = UDim.new(0, 4);
                    TextboxMainC.Name = "TextboxMainC";
                    TextboxMainC.Parent = TextboxMain;
                    TextBox.FocusLost:Connect(function()
                        if TextBox.Text == "" then
                            TextBox.Text = library.flags[Options.Flag];
                        end;
                        library.flags[Options.Flag] = TextBox.Text;
                        --if GuiSettings[Options.Flag] ~= nil then
                            --GuiSettings[Options.Flag] = TextBox.Text;
                        --end;
                        Callback(TextBox.Text);
                    end);
                    utils:Tween(TextBox, { .1, "Linear", "InOut" }, { Size = UDim2.new(0, TextBox.TextBounds.X + 18, 0, 26) });
                    (TextBox:GetPropertyChangedSignal("TextBounds")):Connect(function()
                        utils:Tween(TextBox, { .1, "Linear", "InOut" }, { Size = UDim2.new(0, TextBox.TextBounds.X + 18, 0, 26) });
                    end);
                    local desc = Options.Description or "No info for this function found!";
                    BoxInfo.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(BoxInfo);
                        end);
                        library:CreateNotification(Text, desc, 10000, true);
                    end);
                    return TextboxMain;
                end;
                if Object:lower() == "keybind" then
                    local callback = Callback or function()
 
                        end;
                    local flag = Options.Flag;
                    local default = Options.Default;
                    if not flag then
                        return;
                    end;
                    local banned = {
                            Return = true,
                            Space = true,
                            Tab = true,
                            Unknown = true,
                     };
                    local shortNames = {
                            RightControl = "RightControl",
                            LeftControl = "LeftControl",
                            LeftShift = "LeftShift",
                            RightShift = "RightShift",
                            Semicolon = ";",
                            Quote = "\"",
                            LeftBracket = "[",
                            RightBracket = "]",
                            Equals = "=",
                            Minus = "-",
                            RightAlt = "RightAlt",
                            LeftAlt = "LeftAlt",
                            End = "End",
                            Home = "Home",
                            PageDown = "PageDown",
                            PageUp = "PageUp",
                     };
                    local allowed = { MouseButton1 = false, MouseButton2 = false };
                    local nm = default and (shortNames[default.Name] or default.Name) or "None";
                    library.flags[flag] = default or "None";
                    local KeybindMain = Instance.new("Frame");
                    local KeybindMainC = Instance.new("UICorner");
                    local KeybindText = Instance.new("TextLabel");
                    local BindHolder = Instance.new("Frame");
                    local BindHolderL = Instance.new("UIListLayout");
                    local KeybindValue = Instance.new("TextButton");
                    local KeybindValueC = Instance.new("UICorner");
                    local BindInfo = Instance.new("TextButton");
                    local BindInfoC = Instance.new("UICorner");
                    KeybindMain.Name = "KeybindMain";
                    KeybindMain.Parent = Section;
                    KeybindMain.BackgroundColor3 = theme[1];
                    KeybindMain.BorderSizePixel = 0;
                    KeybindMain.Position = UDim2.new(.00875000004, 0, .189473689, 0);
                    KeybindMain.Size = UDim2.new(0, 393, 0, 36);
                    KeybindMainC.CornerRadius = UDim.new(0, 4);
                    KeybindMainC.Name = "KeybindMainC";
                    KeybindMainC.Parent = KeybindMain;
                    KeybindText.Name = "KeybindText";
                    KeybindText.Parent = KeybindMain;
                    KeybindText.BackgroundColor3 = theme[4];
                    KeybindText.BackgroundTransparency = 1;
                    KeybindText.Position = UDim2.new(0, 0, 2.11927627e-007, 0);
                    KeybindText.Size = UDim2.new(.335000008, 0, 1, 0);
                    KeybindText.Font = Enum.Font.Gotham;
                    KeybindText.Text = "   " .. Text;
                    KeybindText.TextColor3 = theme[4];
                    KeybindText.TextSize = 14;
                    KeybindText.TextXAlignment = Enum.TextXAlignment.Left;
                    BindHolder.Name = "BindHolder";
                    BindHolder.Parent = KeybindMain;
                    BindHolder.BackgroundColor3 = theme[4];
                    BindHolder.BackgroundTransparency = 1;
                    BindHolder.BorderSizePixel = 0;
                    BindHolder.Position = UDim2.new(.735000014, 0, 0, 0);
                    BindHolder.Size = UDim2.new(0, 100, 0, 36);
                    BindHolderL.Name = "BindHolderL";
                    BindHolderL.Parent = BindHolder;
                    BindHolderL.FillDirection = Enum.FillDirection.Horizontal;
                    BindHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    BindHolderL.SortOrder = Enum.SortOrder.LayoutOrder;
                    BindHolderL.VerticalAlignment = Enum.VerticalAlignment.Center;
                    BindHolderL.Padding = UDim.new(0, 4);
                    KeybindValue.Name = "KeybindValue";
                    KeybindValue.Parent = BindHolder;
                    KeybindValue.BackgroundColor3 = theme[2];
                    KeybindValue.BorderSizePixel = 0;
                    KeybindValue.Position = UDim2.new(.735000014, 0, .111000001, 0);
                    KeybindValue.Size = UDim2.new(0, 100, 0, 28);
                    KeybindValue.AutoButtonColor = false;
                    KeybindValue.Font = Enum.Font.Gotham;
                    KeybindValue.Text = nm;
                    KeybindValue.TextColor3 = theme[4];
                    KeybindValue.TextSize = 14;
                    KeybindValueC.CornerRadius = UDim.new(0, 4);
                    KeybindValueC.Name = "KeybindValueC";
                    KeybindValueC.Parent = KeybindValue;
                    BindInfo.Name = "BindInfo";
                    BindInfo.Parent = BindHolder;
                    BindInfo.BackgroundColor3 = theme[2];
                    BindInfo.BorderSizePixel = 0;
                    BindInfo.Position = UDim2.new(.918206036, 0, .111111112, 0);
                    BindInfo.Size = UDim2.new(0, 28, 0, 28);
                    BindInfo.AutoButtonColor = false;
                    BindInfo.Font = Enum.Font.Gotham;
                    BindInfo.Text = "?";
                    BindInfo.TextColor3 = theme[4];
                    BindInfo.TextSize = 20;
                    BindInfo.TextWrapped = true;
                    BindInfoC.CornerRadius = UDim.new(0, 4);
                    BindInfoC.Name = "BindInfoC";
                    BindInfoC.Parent = BindInfo;
                    spawn(function()
                        wait();
                        KeybindValue.Size = UDim2.new(0, KeybindValue.TextBounds.X + 18, 0, 28);
                    end);
                    (KeybindValue:GetPropertyChangedSignal("TextBounds")):Connect(function()
                        utils:Tween(KeybindValue, { .1, "Linear", "InOut" }, { Size = UDim2.new(0, KeybindValue.TextBounds.X + 18, 0, 28) });
                    end);
                    KeybindValue.MouseButton1Click:Connect(function()
                        library.binding = true;
                        KeybindValue.Text = "...";
                        local a, b = services.UserInputService.InputBegan:wait();
                        local name = tostring(a.KeyCode.Name);
                        local typeName = tostring(a.UserInputType.Name);
                        if a.UserInputType ~= Enum.UserInputType.Keyboard and (allowed[a.UserInputType.Name] and not data.KbOnly) or a.KeyCode and not banned[a.KeyCode.Name] then
                            local name = a.UserInputType ~= Enum.UserInputType.Keyboard and a.UserInputType.Name or a.KeyCode.Name;
                            library.flags[flag] = a;
                            KeybindValue.Text = shortNames[name] or name;
                        else
                            if library.flags[flag] then
                                if not pcall(function()
                                    return library.flags[flag].UserInputType;
                                end) then
                                    local name = tostring(library.flags[flag]);
                                    KeybindValue.Text = shortNames[name] or name;
                                else
                                    local name = library.flags[flag].UserInputType ~= Enum.UserInputType.Keyboard and library.flags[flag].UserInputType.Name or library.flags[flag].KeyCode.Name;
                                    KeybindValue.Text = shortNames[name] or name;
                                end;
                            end;
                        end;
                        wait(.1);
                        library.binding = false;
                        --if GuiSettings[flag] ~= nil then
                            --GuiSettings[flag] = KeybindValue.Text;
                        --end;
                    end);
                    if library.flags[flag] then
                        KeybindValue.Text = shortNames[tostring(library.flags[flag].Name)] or tostring(library.flags[flag].Name);
                    end;
                    library.binds[flag] = { location = library.flags, callback = function()
                                callback();
                            end };
                    local desc = Options.Description or "No info for this function found!";
                    BindInfo.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(BindInfo);
                        end);
                        library:CreateNotification(Text, desc, 10000, true);
                    end);
                    return KeybindMain;
                end;
                if Object:lower() == "slider" then
                    local min = Options.Min or 1;
                    local flag = Options.Flag;
                    local max = Options.Max or 10;
                    local default = Options.Default or min;
                    local precise = Options.Precise or false;
                    local SliderMain = Instance.new("Frame");
                    local SliderMainC = Instance.new("UICorner");
                    local SliderText = Instance.new("TextLabel");
                    local SliderHolder = Instance.new("Frame");
                    local SliderHolderL = Instance.new("UIListLayout");
                    local SliderVal = Instance.new("TextBox");
                    local SliderValC = Instance.new("UICorner");
                    local SliderInfo = Instance.new("TextButton");
                    local SliderInfoC = Instance.new("UICorner");
                    local SliderBar = Instance.new("Frame");
                    local SliderBarC = Instance.new("UICorner");
                    local SliderFill = Instance.new("Frame");
                    local SliderFillC = Instance.new("UICorner");
                    library.flags[flag] = default;
                    library.objstorage[flag] = SliderMain;
                    library.funcstorage[flag] = Callback;
                    SliderMain.Name = "SliderMain";
                    SliderMain.Parent = Section;
                    SliderMain.BackgroundColor3 = theme[1];
                    SliderMain.BorderSizePixel = 0;
                    SliderMain.Position = UDim2.new(.00875000004, 0, .633879781, 0);
                    SliderMain.Size = UDim2.new(0, 393, 0, 50);
                    SliderMainC.CornerRadius = UDim.new(0, 4);
                    SliderMainC.Name = "SliderMainC";
                    SliderMainC.Parent = SliderMain;
                    SliderText.Name = "SliderText";
                    SliderText.Parent = SliderMain;
                    SliderText.BackgroundColor3 = theme[4];
                    SliderText.BackgroundTransparency = 1;
                    SliderText.Position = UDim2.new(0, 0, 2.11927627e-007, 0);
                    SliderText.Size = UDim2.new(.335000008, 0, 0, 36);
                    SliderText.Font = Enum.Font.Gotham;
                    SliderText.Text = "   " .. Text;
                    SliderText.TextColor3 = theme[4];
                    SliderText.TextSize = 14;
                    SliderText.TextXAlignment = Enum.TextXAlignment.Left;
                    SliderHolder.Name = "SliderHolder";
                    SliderHolder.Parent = SliderMain;
                    SliderHolder.BackgroundColor3 = theme[4];
                    SliderHolder.BackgroundTransparency = 1;
                    SliderHolder.BorderSizePixel = 0;
                    SliderHolder.Position = UDim2.new(.735000014, 0, 0, 0);
                    SliderHolder.Size = UDim2.new(0, 100, 0, 36);
                    SliderHolderL.Name = "SliderHolderL";
                    SliderHolderL.Parent = SliderHolder;
                    SliderHolderL.FillDirection = Enum.FillDirection.Horizontal;
                    SliderHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    SliderHolderL.SortOrder = Enum.SortOrder.LayoutOrder;
                    SliderHolderL.VerticalAlignment = Enum.VerticalAlignment.Center;
                    SliderHolderL.Padding = UDim.new(0, 4);
                    SliderVal.Name = "SliderVal";
                    SliderVal.Parent = SliderHolder;
                    SliderVal.BackgroundColor3 = theme[2];
                    SliderVal.BorderSizePixel = 0;
                    SliderVal.Position = UDim2.new(.511450171, 0, .111111112, 0);
                    SliderVal.Size = UDim2.new(0, 48, 0, 28);
                    SliderVal.Font = Enum.Font.Gotham;
                    SliderVal.Text = default;
                    SliderVal.TextColor3 = theme[4];
                    SliderVal.TextSize = 14;
                    SliderValC.CornerRadius = UDim.new(0, 4);
                    SliderValC.Name = "SliderValC";
                    SliderValC.Parent = SliderVal;
                    SliderInfo.Name = "SliderInfo";
                    SliderInfo.Parent = SliderHolder;
                    SliderInfo.BackgroundColor3 = theme[2];
                    SliderInfo.BorderSizePixel = 0;
                    SliderInfo.Position = UDim2.new(.918206036, 0, .111111112, 0);
                    SliderInfo.Size = UDim2.new(0, 28, 0, 28);
                    SliderInfo.AutoButtonColor = false;
                    SliderInfo.Font = Enum.Font.Gotham;
                    SliderInfo.Text = "?";
                    SliderInfo.TextColor3 = theme[4];
                    SliderInfo.TextSize = 20;
                    SliderInfo.TextWrapped = true;
                    SliderInfoC.CornerRadius = UDim.new(0, 4);
                    SliderInfoC.Name = "SliderInfoC";
                    SliderInfoC.Parent = SliderInfo;
                    SliderBar.Name = "SliderBar";
                    SliderBar.Parent = SliderMain;
                    SliderBar.BackgroundColor3 = theme[2];
                    SliderBar.BorderSizePixel = 0;
                    SliderBar.Position = UDim2.new(.00800000038, 0, .720000029, 0);
                    SliderBar.Size = UDim2.new(0, 385, 0, 10);
                    SliderBarC.CornerRadius = UDim.new(0, 4);
                    SliderBarC.Name = "SliderBarC";
                    SliderBarC.Parent = SliderBar;
                    SliderFill.Name = "SliderFill";
                    SliderFill.Parent = SliderBar;
                    SliderFill.BackgroundColor3 = theme[3];
                    SliderFill.BorderSizePixel = 0;
                    SliderFill.Size = UDim2.new(0, 86, 0, 10);
                    SliderFillC.CornerRadius = UDim.new(0, 4);
                    SliderFillC.Name = "SliderFillC";
                    SliderFillC.Parent = SliderFill;
                    SliderVal.Size = UDim2.new(0, SliderVal.TextBounds.X + 18, 0, 26);
                    (SliderVal:GetPropertyChangedSignal("TextBounds")):Connect(function()
                        utils:Tween(SliderVal, { .1, "Linear", "InOut" }, { Size = UDim2.new(0, SliderVal.TextBounds.X + 18, 0, 26) });
                    end);
                    library:UpdateSlider(flag, default, min, max, precise);
                    local dragging = false;
                    SliderBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            library:UpdateSlider(flag, nil, min, max, precise);
                            dragging = true;
                        end;
                    end);
                    SliderBar.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false;
                        end;
                    end);
                    services.UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            library:UpdateSlider(flag, nil, min, max, precise);
                        end;
                    end);
                    local boxFocused = false;
                    local allowed = { [""] = true, ["-"] = true };
                    SliderVal.Focused:Connect(function()
                        boxFocused = true;
                    end);
                    SliderVal.FocusLost:Connect(function()
                        boxFocused = false;
                        if not tonumber(SliderVal.Text) then
                            library:UpdateSlider(flag, default or min, min, max);
                        end;
                    end);
                    (SliderVal:GetPropertyChangedSignal("Text")):Connect(function()
                        if not boxFocused then
                            return;
                        end;
                        SliderVal.Text = SliderVal.Text:gsub("%D+", "");
                        local text = SliderVal.Text;
                        if not tonumber(text) then
                            SliderVal.Text = SliderVal.Text:gsub("%D+", "");
                        elseif not allowed[text] then
                            if tonumber(text) > max then
                                text = max;
                                SliderVal.Text = tostring(max);
                            end;
                            library:UpdateSlider(flag, tonumber(text) or value, min, max);
                        end;
                    end);
                    local desc = Options.Description or "No info for this function found!";
                    SliderInfo.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(SliderInfo);
                        end);
                        library:CreateNotification(Text, desc, 10000, true);
                    end);
                    return SliderMain;
                end;
                if Object:lower() == "dropdown" then
                    local playerList = Options.PlayerList or false;
                    local allowLP = Options.ShowLocalPlayer or false;
                    local dropdownFunctions = {};
                    local OptionBtns = {};
                    local options = {};
                    if playerList then
                        local function updplrs()
                            options = {};
                            for _, v in next, services.Players:GetChildren() do
                                if v.Name ~= services.Players.LocalPlayer.Name then
                                    table.insert(options, v.Name);
                                elseif allowLP then
                                    table.insert(options, v.Name);
                                end;
                            end;
                        end;
                        updplrs();
                        if not options[1] then
                            options = { "No players found." };
                        end;
                        services.Players.PlayerAdded:Connect(function(plr)
                            table.insert(options, plr.Name);
                            if table.find(options, "No players found.") then
                                table.remove(options, table.find(options, "No players found."));
                            end;
                            dropdownFunctions:Refresh(options);
                        end);
                        services.Players.PlayerRemoving:Connect(function(plr)
                            table.remove(options, table.find(options, plr.Name));
                            if #options == 0 then
                                options = { "No players found." };
                            end;
                            dropdownFunctions:Refresh(options);
                        end);
                    else
                        options = Options.Options or { "No Options Found." };
                    end;
                    local flag = Options.Flag;
                    library.flags[flag] = options[1];
                    local DropdownMain = Instance.new("Frame");
                    local DropdownMainC = Instance.new("UICorner");
                    local DropdownTitle = Instance.new("TextLabel");
                    local DropdownOption = Instance.new("TextLabel");
                    local Back = Instance.new("TextButton");
                    local BackC = Instance.new("UICorner");
                    local DropdownInfo = Instance.new("TextButton");
                    local DropdownInfoC = Instance.new("UICorner");
                    local DropdownBottom = Instance.new("Frame");
                    local DropdownBottomC = Instance.new("UICorner");
                    local DropdownOptions = Instance.new("ScrollingFrame");
                    local DropdownOptionsL = Instance.new("UIListLayout");
                    local UIPadding = Instance.new("UIPadding");
                    DropdownMain.Name = "DropdownMain";
                    DropdownMain.Parent = Section;
                    DropdownMain.BackgroundColor3 = theme[1];
                    DropdownMain.BorderSizePixel = 0;
                    DropdownMain.Position = UDim2.new(.00875000004, 0, .781420767, 0);
                    DropdownMain.Size = UDim2.new(0, 393, 0, 44);
                    DropdownMainC.CornerRadius = UDim.new(0, 4);
                    DropdownMainC.Name = "DropdownMainC";
                    DropdownMainC.Parent = DropdownMain;
                    DropdownTitle.Name = "DropdownTitle";
                    DropdownTitle.Parent = DropdownMain;
                    DropdownTitle.BackgroundColor3 = theme[4];
                    DropdownTitle.BackgroundTransparency = 1;
                    DropdownTitle.Size = UDim2.new(.335000008, 0, -0.200000003, 36);
                    DropdownTitle.Font = Enum.Font.Gotham;
                    DropdownTitle.Text = "   " .. Text;
                    DropdownTitle.TextColor3 = theme[4];
                    DropdownTitle.TextSize = 14;
                    DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left;
                    DropdownOption.Name = "DropdownOption";
                    DropdownOption.Parent = DropdownMain;
                    DropdownOption.BackgroundColor3 = theme[4];
                    DropdownOption.BackgroundTransparency = 1;
                    DropdownOption.Position = UDim2.new(0, 0, .479999989, 0);
                    DropdownOption.Size = UDim2.new(.365534335, 0, -0.340000004, 36);
                    DropdownOption.Font = Enum.Font.Gotham;
                    DropdownOption.Text = "   " .. library.flags[Options.Flag];
                    DropdownOption.TextColor3 = theme[5];
                    DropdownOption.TextSize = 14;
                    DropdownOption.TextXAlignment = Enum.TextXAlignment.Left;
                    Back.Name = "Back";
                    Back.Parent = DropdownMain;
                    Back.BackgroundColor3 = theme[2];
                    Back.BackgroundTransparency = 1;
                    Back.BorderSizePixel = 0;
                    Back.Position = UDim2.new(.839694679, 0, .201909155, 0);
                    Back.Size = UDim2.new(0, 26, 0, 26);
                    Back.AutoButtonColor = false;
                    Back.Font = Enum.Font.Gotham;
                    Back.Text = "+";
                    Back.TextColor3 = theme[4];
                    Back.TextSize = 30;
                    Back.TextWrapped = true;
                    BackC.CornerRadius = UDim.new(0, 4);
                    BackC.Name = "BackC";
                    BackC.Parent = Back;
                    DropdownInfo.Name = "DropdownInfo";
                    DropdownInfo.Parent = DropdownMain;
                    DropdownInfo.AnchorPoint = Vector2.new(0, .5);
                    DropdownInfo.BackgroundColor3 = theme[2];
                    DropdownInfo.BorderSizePixel = 0;
                    DropdownInfo.Position = UDim2.new(.917999983, 0, .5, 0);
                    DropdownInfo.Size = UDim2.new(0, 28, 0, 38);
                    DropdownInfo.AutoButtonColor = false;
                    DropdownInfo.Font = Enum.Font.Gotham;
                    DropdownInfo.Text = "?";
                    DropdownInfo.TextColor3 = theme[4];
                    DropdownInfo.TextSize = 20;
                    DropdownInfo.TextWrapped = true;
                    DropdownInfoC.CornerRadius = UDim.new(0, 4);
                    DropdownInfoC.Name = "DropdownInfoC";
                    DropdownInfoC.Parent = DropdownInfo;
                    DropdownBottom.Name = "DropdownBottom";
                    DropdownBottom.Parent = Section;
                    DropdownBottom.BackgroundColor3 = theme[1];
                    DropdownBottom.BorderSizePixel = 0;
                    DropdownBottom.Position = UDim2.new(.00875000004, 0, .607272744, 0);
                    DropdownBottom.Size = UDim2.new(0, 393, 0, 0);
                    DropdownBottom.ClipsDescendants = true;
                    DropdownBottom.Visible = false;
                    DropdownBottomC.CornerRadius = UDim.new(0, 4);
                    DropdownBottomC.Name = "DropdownBottomC";
                    DropdownBottomC.Parent = DropdownBottom;
                    DropdownOptions.Name = "DropdownOptions";
                    DropdownOptions.Parent = DropdownBottom;
                    DropdownOptions.Active = true;
                    DropdownOptions.BackgroundColor3 = theme[4];
                    DropdownOptions.BackgroundTransparency = 1;
                    DropdownOptions.BorderSizePixel = 0;
                    DropdownOptions.Size = UDim2.new(0, 393, 0, 196);
                    DropdownOptions.ScrollBarThickness = 0;
                    DropdownOptionsL.Name = "DropdownOptionsL";
                    DropdownOptionsL.Parent = DropdownOptions;
                    DropdownOptionsL.HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    DropdownOptionsL.SortOrder = Enum.SortOrder.LayoutOrder;
                    DropdownOptionsL.Padding = UDim.new(0, 4);
                    UIPadding.Parent = DropdownOptions;
                    UIPadding.PaddingTop = UDim.new(0, 4);
                    (DropdownOptionsL:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
                        DropdownOptions.CanvasSize = UDim2.new(0, 0, 0, DropdownOptionsL.AbsoluteContentSize.Y + 8);
                    end);
                    local isOpen = false;
                    local function toggleDropdown()
                        isOpen = not isOpen;
                        if not isOpen then
                            spawn(function()
                                wait(.25);
                                DropdownBottom.Visible = false;
                            end);
                        else
                            DropdownBottom.Visible = true;
                        end;
                        local openTo = 192;
                        if DropdownOptionsL.AbsoluteContentSize.Y < openTo then
                            openTo = DropdownOptionsL.AbsoluteContentSize.Y + 4;
                        end;
                        utils:Tween(Back, { .3, "Sine", "InOut" }, { Rotation = isOpen and 45 or 0 });
                        utils:Tween(DropdownBottom, { .3, "Sine", "InOut" }, { Size = UDim2.new(0, 393, 0, isOpen and openTo + 4 or 0) });
                    end;
                    (DropdownOptionsL:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
                        if not isOpen then
                            return;
                        end;
                        local openTo = 192;
                        if DropdownOptionsL.AbsoluteContentSize.X < openTo then
                            openTo = DropdownOptionsL.AbsoluteContentSize.Y + 4;
                        end;
                        utils:Tween(DropdownBottom, { .3, "Sine", "InOut" }, { Size = UDim2.new(0, 393, 0, isOpen and openTo + 4 or 0) });
                    end);
                    Back.MouseButton1Click:Connect(toggleDropdown);
                    local function CreateOption(v)
                        local Option = Instance.new("TextButton");
                        local OptionC = Instance.new("UICorner");
                        table.insert(OptionBtns, Option);
                        Option.Name = "Option";
                        Option.Parent = DropdownOptions;
                        Option.BackgroundColor3 = theme[2];
                        Option.BorderSizePixel = 0;
                        Option.Position = UDim2.new(.372773528, 0, .0224719103, 0);
                        Option.Size = UDim2.new(0, 384, 0, 28);
                        Option.AutoButtonColor = false;
                        Option.Font = Enum.Font.Gotham;
                        Option.Text = v;
                        Option.TextColor3 = theme[4];
                        Option.TextSize = 14;
                        Option.TextWrapped = true;
                        OptionC.CornerRadius = UDim.new(0, 4);
                        OptionC.Name = "OptionC";
                        OptionC.Parent = Option;
                        Option.MouseButton1Click:Connect(function()
                            library.flags[flag] = v;
                            DropdownOption.Text = "   " .. v;
                            spawn(toggleDropdown);
                            spawn(function()
                                Callback(v);
                            end);
                        end);
                    end;
                    for _, v in next, options do
                        CreateOption(v);
                    end;
                    function dropdownFunctions.Refresh(self, newOptions)
                        for _, v in next, OptionBtns do
                            v:Destroy();
                        end;
                        OptionBtns = {};
                        for _, v in next, newOptions do
                            CreateOption(v);
                        end;
                    end;
                    function dropdownFunctions.ToggleVisible(self, hide)
                        if isOpen then
                            toggleDropdown();
                        end;
                        DropdownMain.Visible = hide;
                    end;
                    local desc = Options.Description or "No info for this function found!";
                    DropdownInfo.MouseButton1Click:Connect(function()
                        spawn(function()
                            utils:Ripple(SliderInfo);
                        end);
                        library:CreateNotification(Text, desc, 10000, true);
                    end);
                    return dropdownFunctions;
                end;
            end;
            return Modules;
        end;
        return secs;
    end;
    return Modules;
end;
return library
