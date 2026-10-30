-- Restore then isolate test geometry for the selected camera target.
local TARGET = "TestPaletteBox"
local stash = game.ServerStorage:FindFirstChild("Test01_CaptureIsolation")
if not stash then stash=Instance.new("Folder");stash.Name="Test01_CaptureIsolation";stash.Parent=game.ServerStorage end
for _,v in stash:GetChildren() do v.Parent=workspace end
for _,v in workspace:GetChildren() do
 if (v.Name=="TestPaletteBox" or v.Name=="TestSkinBox" or v.Name=="TestUVBleed" or v.Name=="TestE" or v.Name=="TestF") and v.Name~=TARGET then v.Parent=stash end
end
