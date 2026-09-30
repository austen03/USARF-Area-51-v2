-- Rank numbers in the main USARF group (6033326).
--
-- QA (19) sits above President in the group's rank order but carries no in-game
-- authority: QA testers get their Cmdr commands from CmdrAdminConfig.QA and are a
-- plain member everywhere else. Rank checks read ranks through EffectiveRank so a
-- "rank >= N" check never treats QA as leadership.
local MainGroupRanks = {
	GroupId = 6033326,

	Member = 1,
	VicePresident = 16,
	President = 17,
	Developer = 18,
	QA = 19,
	A51Developer = 20,
	FederalAdministrator = 21,
	FederalManager = 22,
	FederalOverseer = 255,
}

-- The rank that in-game permission checks should use. Other groups pass through.
function MainGroupRanks.EffectiveRank(groupId, rank)
	rank = tonumber(rank) or 0

	if groupId == MainGroupRanks.GroupId and rank == MainGroupRanks.QA then
		return MainGroupRanks.Member
	end

	return rank
end

-- Developer (18) and A51 v2 Developer (20).
function MainGroupRanks.IsDeveloper(rank)
	return rank == MainGroupRanks.Developer or rank == MainGroupRanks.A51Developer
end

-- Federal Administrator and above.
function MainGroupRanks.IsFederalLeadership(rank)
	return rank >= MainGroupRanks.FederalAdministrator
end

return MainGroupRanks
