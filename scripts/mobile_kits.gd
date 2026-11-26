extends RefCounted

## Each entry stores original desktop slot IDs in touch button order.
## Keeping the IDs preserves the cast events used by animation and spell effects.
const ACTIVE_SLOTS = {
	"breakwater": [0, 2, 3, 6, 1, 7], # Brace and Holdfast add ways to hold ground.
	"threadkeeper": [0, 1, 5, 6, 2, 3], # Borrowed Time defers damage for Mend the Break to clear.
	"echo_duelist": [0, 1, 3, 2, 4, 6], # Retrace returns along the trail instead of spending it on Afterstroke.
	"forgecaller": [0, 1, 6, 7, 3, 4], # Quench and Furnace Bed offer defense and area pressure.
	"blood_cantor": [0, 1, 3, 6, 4, 7], # Reap a sample to pay for a stronger emergency heal.
	"bellwarden": [0, 2, 5, 7, 4, 6], # Intercede protects an ally and Tempered Footing breaks movement control.
	"ash_dancer": [0, 1, 2, 7, 4, 5], # Snuff interrupts and Firebreak forces foes to move.
	"winter_scribe": [0, 1, 5, 2, 4, 7], # Ward allies in the seal or turn it into a lasting frost storm.
	"lamplighter": [0, 1, 2, 7, 3, 5], # Move the lantern and shield allies within it.
	"longwatch": [0, 1, 3, 7, 4, 5], # Bellshot interrupts and Fan Volley pressures groups in the open.
	"sluicecaller": [0, 2, 5, 7, 4, 6], # Displace foes into Floodgate or break away with Slipstream.
	"glassmage": [0, 1, 4, 7, 2, 3], # Mirror Step repositions toward the prism and Mirror Guard protects the caster.
	"dream_shepherd": [0, 1, 2, 7, 4, 6], # Daybreak frees an ally and Dream Hollow grants area healing.
	"chainrunner": [0, 1, 2, 7, 3, 6], # Root a foe or pull an ally clear.
	"coilwright": [0, 1, 3, 2, 5, 7], # Protect an ally with Insulation or hold ground with Thunder Cage.
	"duskmoth": [0, 1, 5, 7, 2, 3], # Gale Flit and Shed Husk give the skirmisher escape options.
}


static func slots(class_id: String) -> Array[int]:
	var result: Array[int] = []
	result.assign(ACTIVE_SLOTS.get(class_id, []))
	return result


static func allows(class_id: String, slot: int) -> bool:
	return ACTIVE_SLOTS.get(class_id, []).has(slot)
