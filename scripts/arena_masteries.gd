extends RefCounted

# Each entry sets an alternate recovery time and price for one signature move.
const OPTIONS = {
	"breakwater": [
		{"name": "Rescue Detail", "slot": 4, "cooldown": 6.0, "cost": 22},
		{"name": "Bulwark", "slot": 7, "cooldown": 24.0, "cost": 27},
	],
	"threadkeeper": [
		{"name": "Field Surgeon", "slot": 6, "cooldown": 4.5, "cost": 34},
		{"name": "Spindle Tender", "slot": 7, "cooldown": 22.0, "cost": 26},
	],
	"echo_duelist": [
		{"name": "Backstep", "slot": 4, "cooldown": 4.5, "cost": 19},
		{"name": "Second Movement", "slot": 7, "cooldown": 25.0, "cost": 34},
	],
	"forgecaller": [
		{"name": "Hot Iron", "slot": 7, "cooldown": 8.5, "cost": 52},
		{"name": "Field Armorer", "slot": 6, "cooldown": 19.0, "cost": 20},
	],
	"lamplighter": [
		{"name": "Traveling Flame", "slot": 5, "cooldown": 2.5, "cost": 10},
		{"name": "Vigil", "slot": 7, "cooldown": 17.0, "cost": 15},
	],
	"longwatch": [
		{"name": "Quick Draw", "slot": 7, "cooldown": 5.8, "cost": 37},
		{"name": "Trapper", "slot": 6, "cooldown": 12.0, "cost": 6},
	],
	"sluicecaller": [
		{"name": "Undertow", "slot": 5, "cooldown": 3.0, "cost": 20},
		{"name": "Canal Keeper", "slot": 6, "cooldown": 12.0, "cost": 10},
	],
	"glassmage": [
		{"name": "Glasswalker", "slot": 2, "cooldown": 4.5, "cost": 15},
		{"name": "Prism Breaker", "slot": 7, "cooldown": 16.0, "cost": 17},
	],
	"blood_cantor": [
		{"name": "Chorus Leader", "slot": 5, "cooldown": 8.5, "cost": 35},
		{"name": "Last Rites", "slot": 7, "cooldown": 20.0, "cost": 27},
	],
	"bellwarden": [
		{"name": "Bell Escort", "slot": 4, "cooldown": 6.0, "cost": 20},
		{"name": "Cathedral Guard", "slot": 7, "cooldown": 22.0, "cost": 30},
	],
	"ash_dancer": [
		{"name": "Coal Raker", "slot": 2, "cooldown": 3.5, "cost": 19},
		{"name": "Kiln Dancer", "slot": 7, "cooldown": 18.0, "cost": 26},
	],
	"winter_scribe": [
		{"name": "Quick Hand", "slot": 5, "cooldown": 5.5, "cost": 22},
		{"name": "Illuminator", "slot": 7, "cooldown": 18.0, "cost": 29},
	],
	"dream_shepherd": [
		{"name": "Early Dawn", "slot": 4, "cooldown": 7.5, "cost": 23},
		{"name": "Deep Dream", "slot": 7, "cooldown": 19.0, "cost": 27},
	],
	"chainrunner": [
		{"name": "Rescue Line", "slot": 6, "cooldown": 6.5, "cost": 23},
		{"name": "Heavy Chain", "slot": 7, "cooldown": 11.0, "cost": 20},
	],
	"coilwright": [
		{"name": "Parallel Circuit", "slot": 2, "cooldown": 2.7, "cost": 21},
		{"name": "Cage Builder", "slot": 7, "cooldown": 16.0, "cost": 24},
	],
	"duskmoth": [
		{"name": "Molting", "slot": 3, "cooldown": 6.0, "cost": 20},
		{"name": "Night Reaper", "slot": 7, "cooldown": 11.0, "cost": 18},
	],
}
