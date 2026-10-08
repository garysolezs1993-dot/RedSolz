@tool
extends RefCounted
# Sonilo Audio Generator - static option data (mirrors the other plugins).

const PRIMARY_GAME_TYPES: Array[String] = [
	"Action", "Adventure", "RPG", "Shooter", "Strategy", "Simulation", "Puzzle",
	"Platformer", "Racing", "Sports", "Fighting", "Horror", "Survival", "Sandbox",
	"Stealth", "Roguelike / Roguelite", "Card Game", "Board Game", "Rhythm / Music",
	"Visual Novel", "Dating Sim", "Idle / Incremental", "Casual", "Party Game",
	"Social Game", "Cozy Game", "Educational", "Serious Game", "VR / XR",
	"Interactive Experience",
]

const SUB_GAME_TYPES: Dictionary = {
	"Action": ["Hack & Slash", "Beat 'em Up", "Character Action", "Action Adventure"],
	"Adventure": ["Narrative Adventure", "Point & Click", "Exploration", "Action Adventure"],
	"RPG": ["Action RPG", "JRPG", "CRPG", "Tactical RPG", "MMORPG", "Roguelite RPG"],
	"Shooter": ["FPS", "TPS", "Tactical Shooter", "Hero Shooter", "Extraction Shooter", "Bullet Hell"],
	"Strategy": ["RTS", "Turn-Based Strategy", "4X", "Tower Defense", "Auto Battler", "Grand Strategy"],
	"Simulation": ["Life Simulation", "Farming Simulation", "Business / Tycoon", "City Builder", "Vehicle Simulation", "Job Simulation"],
	"Puzzle": ["Casual Puzzle", "Logic Puzzle", "Physics Puzzle", "Match-3", "Escape Room"],
	"Platformer": ["2D Platformer", "3D Platformer", "Precision Platformer", "Metroidvania"],
	"Racing": ["Arcade Racing", "Simulation Racing", "Kart Racing", "Futuristic Racing"],
	"Sports": ["Traditional Sports", "Extreme Sports", "Arcade Sports", "Sports Management"],
	"Fighting": ["2D Fighting", "3D Fighting", "Arena Fighter", "Platform Fighter"],
	"Horror": ["Survival Horror", "Psychological Horror", "Action Horror", "Cosmic Horror", "Multiplayer Horror"],
	"Survival": ["Open World Survival", "Crafting Survival", "Hardcore Survival"],
	"Sandbox": ["Open World Sandbox", "Creative Sandbox", "Physics Sandbox"],
	"Stealth": ["Stealth Action", "Tactical Stealth", "Social Stealth"],
	"Card Game": ["CCG / TCG", "Deckbuilder", "Card Battler"],
	"Casual": ["Hypercasual", "Casual Arcade", "Casual Puzzle", "Mobile Casual"],
}

const SCENARIO_CATEGORIES: Array[String] = [
	"Core Gameplay", "Exploration", "Combat", "Boss", "Stealth & Tension",
	"Narrative", "Safe / Social", "Progression", "Special Gameplay",
]

const SCENARIO_DETAILS: Dictionary = {
	"Core Gameplay": ["Main Gameplay", "Tutorial", "Intro Level", "Early Game", "Mid Game", "Late Game", "Final Level", "Challenge Level", "Bonus Level", "Secret Level", "Time Trial", "Survival Round", "Endless Mode"],
	"Exploration": ["Peaceful Exploration", "Open World Exploration", "Unknown Territory", "Dangerous Exploration", "Underground Exploration", "Night Exploration", "Discovery", "Hidden Area", "Ancient Ruins", "Dungeon", "Cave", "Forest", "Desert", "Snow / Ice", "Ocean / Underwater", "Sky / Floating World", "Space", "Urban City", "Village / Town", "Cyber City", "Wasteland", "Alien World"],
	"Combat": ["Light Combat", "Standard Combat", "Intense Combat", "Large-Scale Battle", "Arena Battle", "Wave Combat", "Ambush", "Chase Combat", "Tactical Combat", "Stealth Combat", "Final Stand"],
	"Boss": ["Mini Boss", "Boss Introduction", "Boss Battle", "Multi-Phase Boss", "Final Boss", "Secret Boss", "Victory After Boss"],
	"Stealth & Tension": ["Sneaking", "Infiltration", "Detection Risk", "Suspicion", "Hiding", "Escape", "Pursuit / Chase", "Countdown", "High Alert"],
	"Narrative": ["Story Introduction", "Dialogue Scene", "Character Introduction", "Emotional Conversation", "Revelation", "Mystery Reveal", "Betrayal", "Loss / Death", "Reunion", "Romance", "Flashback", "Dream Sequence", "Transformation", "Heroic Moment", "Villain Reveal", "Ending", "Credits"],
	"Safe / Social": ["Main Menu", "Lobby", "Character Select", "Loadout", "Inventory", "Shop", "Tavern", "Home Base", "Safe Zone", "Social Hub", "Crafting", "Building", "Farming", "Resting"],
	"Progression": ["Level Up", "Skill Unlock", "Item Discovery", "Rare Loot", "Achievement", "Quest Accepted", "Quest Complete", "Victory", "Defeat", "Game Over"],
	"Special Gameplay": ["Puzzle Solving", "Racing", "Flying", "Swimming", "Climbing", "Platforming", "Parkour", "Rhythm Sequence", "Sports Match", "Training", "Preparation", "Character Customization"],
}

const MOOD_CATEGORIES: Array[String] = [
	"Positive", "Calm", "Epic", "Dark", "Tension", "Sad / Emotional",
	"Mystery", "Action", "Cool / Stylish",
]

const MOOD_DETAILS: Dictionary = {
	"Positive": ["Happy", "Joyful", "Playful", "Fun", "Cheerful", "Cute", "Whimsical", "Hopeful", "Optimistic", "Uplifting", "Celebratory", "Triumphant"],
	"Calm": ["Calm", "Peaceful", "Relaxing", "Cozy", "Warm", "Gentle", "Dreamy", "Serene", "Meditative", "Comforting", "Nostalgic"],
	"Epic": ["Epic", "Heroic", "Grand", "Majestic", "Powerful", "Legendary", "Victorious", "Cinematic", "Inspirational", "Awe-Inspiring"],
	"Dark": ["Dark", "Ominous", "Sinister", "Evil", "Menacing", "Disturbing", "Creepy", "Unsettling", "Haunted", "Macabre"],
	"Tension": ["Tense", "Suspenseful", "Nervous", "Anxious", "Urgent", "Dangerous", "Paranoid", "Claustrophobic", "Unpredictable", "High-Stakes"],
	"Sad / Emotional": ["Sad", "Melancholic", "Tragic", "Lonely", "Heartbroken", "Emotional", "Bittersweet", "Regretful", "Grieving", "Reflective"],
	"Mystery": ["Mysterious", "Curious", "Enigmatic", "Secretive", "Strange", "Supernatural", "Otherworldly", "Magical", "Ancient", "Cosmic"],
	"Action": ["Energetic", "Intense", "Aggressive", "Fast-Paced", "Adrenaline", "Chaotic", "Explosive", "Relentless", "Driving"],
	"Cool / Stylish": ["Cool", "Stylish", "Confident", "Sexy", "Sophisticated", "Luxurious", "Futuristic", "Edgy", "Rebellious", "Urban"],
}

const DYNAMIC_BEHAVIORS: Array[String] = [
	"Static Loop", "Seamless Loop", "Adaptive Intensity", "Exploration To Combat",
	"Combat To Boss", "Calm To Tension", "Layered Music", "Event Triggered",
	"Victory Transition", "Defeat Transition", "Day Night Transition", "Multi-Phase Boss",
]

const SFX_CATEGORIES: Array[String] = [
	"UI Click", "Button Hover", "Confirm", "Cancel", "Error", "Notification",
	"Pickup", "Coin", "Power Up", "Level Up", "Achievement", "Footstep", "Jump",
	"Land", "Dash", "Attack", "Sword Hit", "Gun Shot", "Explosion", "Magic Cast",
	"Impact", "Door Open", "Door Close", "Chest Open", "Ambient One-Shot",
	"Monster Growl", "Creature Sound", "Machine", "Vehicle", "Alarm",
	"Transition Whoosh",
]
