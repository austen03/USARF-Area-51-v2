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

function MainGroupRanks.EffectiveRank(groupId, rank)
	rank = tonumber(rank) or 0

	if groupId == MainGroupRanks.GroupId and rank == MainGroupRanks.QA then
		return MainGroupRanks.Member
	end

	return rank
end

function MainGroupRanks.IsDeveloper(rank)
	return rank == MainGroupRanks.Developer or rank == MainGroupRanks.A51Developer
end

function MainGroupRanks.IsFederalLeadership(rank)
	return rank >= MainGroupRanks.FederalAdministrator
end

return MainGroupRanks
