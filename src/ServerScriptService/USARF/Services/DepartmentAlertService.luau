local ServerScriptService = game:GetService("ServerScriptService")

local DepartmentAlertService = {}

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local AnnouncementService = require(
	Services:WaitForChild("AnnouncementService")
)

local SECURITY_TEAMS = {
	"108th Infantry",
	"137th MP",
	"1st Spec Ops A.I.G",
	"Secret Service",
}

local INTELLIGENCE_TEAMS = {
	"CIA",
	"FBI",
	"FDS",
}

local MEDICAL_TEAMS = {
	"Medical",
}

local RESEARCH_TEAMS = {
	"Research",
}

function DepartmentAlertService.SecurityIncident(message)
	AnnouncementService.SendToTeams(
		SECURITY_TEAMS,
		{
			Title = "Security Incident",
			Message = message,
			Type = "Security",
		}
	)
end

function DepartmentAlertService.ContainmentBreach(message)
	AnnouncementService.SendToTeams(
		SECURITY_TEAMS,
		{
			Title = "Containment Breach",
			Message = message,
			Type = "Security",
		}
	)

	AnnouncementService.SendToTeams(
		RESEARCH_TEAMS,
		{
			Title = "Containment Breach",
			Message = message,
			Type = "Warning",
		}
	)
end

function DepartmentAlertService.MedicalEmergency(message)
	AnnouncementService.SendToTeams(
		MEDICAL_TEAMS,
		{
			Title = "Medical Emergency",
			Message = message,
			Type = "Medical",
		}
	)
end

function DepartmentAlertService.ResearchEmergency(message)
	AnnouncementService.SendToTeams(
		RESEARCH_TEAMS,
		{
			Title = "Research Emergency",
			Message = message,
			Type = "Research",
		}
	)
end

function DepartmentAlertService.IntelligenceAlert(message)
	AnnouncementService.SendToTeams(
		INTELLIGENCE_TEAMS,
		{
			Title = "Intelligence Alert",
			Message = message,
			Type = "Intelligence",
		}
	)
end

function DepartmentAlertService.PresidentialMovement(message)
	AnnouncementService.SendToTeams(
		{
			"Secret Service",
			"FDS",
			"Presidential Cabinet",
			"Vice President",
			"President",
		},
		{
			Title = "Presidential Movement",
			Message = message,
			Type = "Leadership",
		}
	)
end

return DepartmentAlertService