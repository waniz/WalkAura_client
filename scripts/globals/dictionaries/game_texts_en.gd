extends Node

var location_texts = {
	1: "Location: NoobLand",
}

var location_descriptions = {
	1: "Nothing special, just spawn location for the new players.",
	2: "A vast ancient forest filled with rare herbs and hidden dangers.",
	3: "A murky swamp shrouded in mist, home to strange and hostile creatures.",
	4: "Rugged mountain terrain rich in ore veins and rocky outcroppings.",
	5: "A mountain range abundant with iron deposits, favoured by miners.",
	6: "A bustling settlement where travellers rest and trade their wares.",
	7: "A mysterious tower of unknown origin, its upper floors yet unexplored.",
	8: "A sunken harbour district, half-submerged and crawling with sea creatures.",
	9: "The scorched lair of a great dragon, littered with ancient treasure.",
	10: "An ancient place of power, older than any known civilisation.",
}

var avatar_names = {
	"0": "Pirat",
	"1": "Avatar 1",
	"2": "Avatar 2",
	"3": "Avatar 3",
	"4": "Avatar 4",
	"5": "Avatar 5",
}

var activities_texts = {
	0: "No",
	1: "Herbalism",
	2: "Alchemy",
	3: "Hunting",
	4: "Mining",
	5: "Woodcutting",
	6: "Fishing",
	7: "Rift Explorer",
	8: "Travelling",
	9: "Enchanting",
}

# Server error codes -> user-facing message. Keys must match the codes emitted
# by server.py exactly. The error-code parity lint in the server tests checks
# that every server code has a key here.
var error_texts = {
	"invalid_credentials": "Incorrect username or password.",
	"account_locked": "Account temporarily locked. Try again in a few minutes.",
	"rate_limited": "Too many attempts. Please wait a moment.",
	"username_taken": "That username is already taken.",
	"username_invalid": "Username must be 3 to 20 characters, letters, digits or underscore.",
	"password_too_weak": "Password must be at least 8 characters.",
	"bad_request": "Something went wrong. Please restart the app.",
	"registration_failed": "Could not create account. Please try again.",
	"version_mismatch": "Your game version is out of date. Please update.",
	"server_error": "Server error. Please try again.",
	"inventory_full": "Your inventory is full.",
	"skill_too_low": "Your skill is too low for this.",
}

# Reason subcodes for username_invalid / password_too_weak. Optional overlay
# on top of the generic error_texts entry.
var error_reason_texts = {
	"too_short": "Too short.",
	"too_long": "Too long.",
	"bad_chars": "Only letters, digits, and underscore are allowed.",
	"reserved": "That name is reserved, pick another.",
	"invalid": "Not valid.",
}
