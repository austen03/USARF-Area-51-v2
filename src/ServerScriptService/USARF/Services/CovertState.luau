local CovertState = {}

export type Org = {
	Id: string,
	Tag: string,
	Logo: string,
	Color: Color3,
}

export type State = {
	HomeTeamKey: string,
	HomeTeamName: string,
	Name: string,
	SubjectNumber: string,
	Gold: boolean,
	Clearance: boolean,
	Org: Org?,
}

local NAME_ATTRIBUTE = "USARF_CovertName"

local states: { [Player]: State } = {}
local changed = Instance.new("BindableEvent")

CovertState.Changed = changed.Event

function CovertState.Get(player: Player): State?
	return states[player]
end

function CovertState.IsCovert(player: Player?): boolean
	return player ~= nil and states[player] ~= nil
end

function CovertState.GetHomeTeamKey(player: Player?): string?
	local state = player and states[player]
	return if state then state.HomeTeamKey else nil
end

function CovertState.HasClearance(player: Player?): boolean
	local state = player and states[player]
	return state ~= nil and state.Clearance == true
end

function CovertState.Set(player: Player, state: State?)
	states[player] = state
	player:SetAttribute(NAME_ATTRIBUTE, if state then state.Name else nil)
	changed:Fire(player)
end

function CovertState.Update(player: Player, edit: (State) -> ())
	local state = states[player]

	if not state then
		return
	end

	edit(state)

	player:SetAttribute(NAME_ATTRIBUTE, state.Name)
	changed:Fire(player)
end

return CovertState
