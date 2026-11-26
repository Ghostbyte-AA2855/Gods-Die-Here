extends RefCounted

## Each entry stores original desktop slot IDs in touch button order.
## Keeping the IDs preserves the cast events used by animation and spell effects.
const ACTIVE_SLOTS = {
	"breakwater": [0, 2, 3, 6], # Guard an ally to empower Keelbreaker.
	"threadkeeper": [0, 1, 5, 6], # Shield and speed up an ally before threading a heal through a foe.
	"echo_duelist": [0, 1, 3, 2], # Tracecut creates the trail that Afterstroke strikes again.
	"forgecaller": [0, 1, 6, 7], # Heat Brand adds damage to Hammerfall.
	"blood_cantor": [0, 1, 3, 6], # Reap a Siphon Note sample to recover the health spent on allies.
	"bellwarden": [0, 2, 5, 7], # A basic hit rings the target so Tocsin can silence it.
	"ash_dancer": [0, 1, 2, 7], # Basic hits brand targets for a burn or an area finisher.
	"winter_scribe": [0, 1, 5, 2], # Root an enemy inside a seal before shattering it.
	"lamplighter": [0, 1, 2, 7], # Sustain allies with a lantern, then spend it on a group heal.
	"longwatch": [0, 1, 3, 7], # Mark Quarry improves basic shots and sets up Quarry's End.
	"sluicecaller": [0, 2, 5, 7], # Apply Undertow with Crosscurrent or Maelstrom, then use Riptide.
	"glassmage": [0, 1, 4, 7], # Set a prism, pin an enemy near it, and shatter it.
	"dream_shepherd": [0, 1, 2, 7], # Shield a healthy ally to prime a stronger Soft Landing.
	"chainrunner": [0, 1, 2, 7], # Hook a target, close the distance, and finish with Last Link.
	"coilwright": [0, 1, 3, 2], # Polarize a foe, then spread damage or root the marked target.
	"duskmoth": [0, 1, 5, 7], # Spread Night Dust among nearby enemies, then reap a dusted foe.
}


static func slots(class_id: String) -> Array[int]:
	var result: Array[int] = []
	result.assign(ACTIVE_SLOTS.get(class_id, []))
	return result


static func allows(class_id: String, slot: int) -> bool:
	return ACTIVE_SLOTS.get(class_id, []).has(slot)
