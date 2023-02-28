--!strict
--Services
--Packages
local Package = script
local Packages = Package.Parent
local MeshUtil = require(Packages:WaitForChild("MeshUtil"))
local CFrameUtil = require(Packages:WaitForChild("CFrameUtil"))
--Modules
--Types
--Constants
--Class
local Util = {}

function transformModel(model: Model, scale: number, goal: CFrame)
	local origin = Util.getCFrame(model)
	
	local function getFinalCFrame(instOrigin: CFrame)
		return goal * CFrameUtil.setScale(origin:Inverse() * instOrigin, scale)
	end

	local function setChildren(inst: Instance)
		local primaryPart: BasePart?
		if inst:IsA("Model") then
			primaryPart = inst.PrimaryPart
		end
		local orphans: {[number]: Instance} = {}
		for i, v in ipairs(inst:GetChildren()) do
			if v:IsA("BasePart") then
				v.Parent = nil
				table.insert(orphans, v)
				setChildren(v)
			elseif v:IsA("Attachment") then
				v.Parent = nil
				table.insert(orphans, v)
				v.WorldCFrame = getFinalCFrame(v.WorldCFrame)
			else
				v.Parent = nil
				table.insert(orphans, v)
				setChildren(v)
			end
		end
		if inst:IsA("BasePart") then
			local cf = inst:GetPivot()
			local offset = CFrameUtil.setScale(inst.PivotOffset, scale)
			inst.Size *= scale
			inst.PivotOffset = offset
			inst:PivotTo(getFinalCFrame(cf))
		end
		if inst:IsA("Model") then
			inst:PivotTo(getFinalCFrame(inst:GetPivot()))
			if primaryPart then
				inst.PrimaryPart = primaryPart
			end
		end
		for i, v in ipairs(orphans) do
			v.Parent = inst
		end
	end

	setChildren(model)

	return nil
end

function Util.getPrimaryPartAsync(model: Model): BasePart
	if model.PrimaryPart then
		return model.PrimaryPart
	else
		local primaryPart: BasePart?
		repeat
			task.wait()
			primaryPart = model.PrimaryPart
		until primaryPart
		assert(primaryPart ~= nil)
		return primaryPart
	end
end

function Util.getCFrame(model: Model, usePrimaryPart: boolean?): CFrame
	if usePrimaryPart and model.PrimaryPart then
		return model.PrimaryPart:GetPivot()
	else
		return model:GetPivot()
	end
end

function Util.setScale(model: Model, goal: number, cf: CFrame?)
	transformModel(model, goal, cf or Util.getCFrame(model))
	return nil
end

function Util.setCFrame(model: Model, goal: CFrame)
	transformModel(model, 1, goal)
	return nil
end

function Util.getAlignedBoundingBox(model: Model, cf: CFrame): (CFrame, Vector3)
	local parts = {}
	for i, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end
	local boxSize, boxCF = MeshUtil.getBoundingBoxAtCFrame(cf, parts)
	return boxCF, boxSize
end



return Util
