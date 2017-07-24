--
-- Adjustable Mirrors
--
-- @author  StjerneIdioten
-- Version 0.1
-- @date 23.07.2017


AdjustableMirrors = {};

addModEventListener(AdjustableMirrors);

function AdjustableMirrors:loadMap(name)
	
	print ("AdjustableMirrors mod loaded!");

	g_currentMission.environment:addHourChangeListener(self)

	--[[
	DebugUtil.printTableRecursively(g_currentMission,".",0,5)

	g_currentMission.missionStats.loanMax = 5000000;
	g_currentMission.missionStats.saveLoan = 0;
	AdjustableMirrors:calculateLoanInterestRate();
	--]]

end;

function AdjustableMirrors:hourChanged()

	print ("An hour has passed!");

end;

function AdjustableMirrors:update(dt)

	--[[
	if g_currentMission.missionStats.saveLoan ~= g_currentMission.missionStats.loan then
		AdjustableMirrors:calculateLoanInterestRate();
		g_currentMission.missionStats.saveLoan = g_currentMission.missionStats.loan;
	end;
	--]]

end;

--[[
function AdjustableMirrors:calculateLoanInterestRate()

	local loanAnnualInterestRate = 0;
	
	if g_currentMission.missionStats.loan <= 200000 then
		loanAnnualInterestRate = 50;
	else
		loanAnnualInterestRate = g_currentMission.missionStats.loan / 2500;
	end;

	g_currentMission.missionStats.loanAnnualInterestRate = loanAnnualInterestRate * g_currentMission.missionInfo.difficulty;

end;
]]

function AdjustableMirrors:deleteMap()
	print ("AdjustableMirrors map deleted!");
end;

function AdjustableMirrors:delete()
	print ("AdjustableMirrors mod deleted!");
end;

function AdjustableMirrors:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AdjustableMirrors:keyEvent(unicode, sym, modifier, isDown)
end;

function AdjustableMirrors:draw()
end;

