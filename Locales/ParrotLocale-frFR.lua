-- $Rev: 400 $

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot")
L:AddTranslations("frFR", function() return {
		["Parrot"] = "Parrot",
		["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."] = "Texte de combat flottant. Croac. Coco veut un gâteau.",
		["Inherit"] = "Par héritage",
		["Parrot Configuration"] = "Configuration de Parrot",
		["Waterfall-1.0 is required to access the GUI."] = "Waterfall-1.0 est requis pour accéder au GUI.",
		["General"] = "Général",
		["General settings"] = "Permet de configurer les paramètres généraux.",
		["Game damage"] = "Dégâts du jeu",
		["Whether to show damage over the enemy's heads."] = "Affiche ou non les dégâts au dessus de la tête des ennemis.",
		["Game healing"] = "Soins du jeu",
		["Whether to show healing over the enemy's heads."] = "Affiche ou non les soins au dessus de la tête des alliés.",
		["|cffffff00Left-Click|r to change settings with a nice GUI configuration."] = "|cffffff00Clic-gauche|r pour modifier les paramètres via une fenêtre de configuration.",
		["|cffffff00Right-Click|r to change settings with a drop-down menu."] = "|cffffff00Clic-droit|r pour modifier les paramètres via un menu déroulant.",
}end)

local L_CombatEvents = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_CombatEvents")
L_CombatEvents:AddTranslations("frFR", function() return {
		["[Text] (crit)"] = "[Text] (crit)",
		["[Text] (crushing)"] = "[Text] (écrase)",
		["[Text] (glancing)"] = "[Text] (érafle)",
		[" ([Amount] absorbed)"] = " ([Amount] absorbés)",
		[" ([Amount] blocked)"] = " ([Amount] bloqués)",
		[" ([Amount] resisted)"] = " ([Amount] résistés)",
		[" ([Amount] vulnerable)"] = " ([Amount] de vulnérabilité)",
		[" ([Amount] overheal)"] = " ([Amount] en excès)",
		["Events"] = "Événements",
		["Change event settings"] = "Modifie les paramètres des événements.",
		["Incoming"] = "Entrants",
		["Incoming events are events which a mob or another player does to you."] = "Les événements entrants sont les événements que les monstres et les autres joueurs font sur vous.",
		["Outgoing"] = "Sortants",
		["Outgoing events are events which you do to a mob or another player."] = "Les événements sortants sont les événements que vous faites sur les montres et les autres joueurs.",
		["Notification"] = "Notification",
		["Notification events are available to notify you of certain actions."] = "Les événements de notification vous préviennent de certaines actions.",
		["Event modifiers"] = "Modificateurs d'événements",
		["Options for event modifiers."] = "Options concernant les modificateurs d'événements.",
		["Color"] = "Couleur",
		["Whether to color event modifiers or not."] = "Colorie ou non les modificateurs d'événements.",
		["Damage types"] = "Types de dégâts",
		["Options for damage types."] = "Options concernant les types de dégâts.",
		["Whether to color damage types or not."] = "Colorie ou non les types de dégâts.",
		["Sticky crits"] = "Critiques en évidence",
		["Enable to show crits in the sticky style."] = "Affiche ou non les critiques dans le style En évidence.",
		["Throttle events"] = "Rassemblement d'événements",
		["Whether to merge mass events into single instances instead of excessive spam."] = "Fusionne ou non plusieurs événements ensemble au lieu d'un spam excessif.",
		["Filters"] = "Filtres",
		["Filters to be checked for a minimum amount of damage/healing/etc before showing."] = "Détermine les filtres à vérifier avant affichage des dégâts/soins/etc.",
		["Shorten spell names"] = "Noms des sorts raccourcis",
		["How or whether to shorten spell names."] = "Détermine s'il faut raccourcir ou non les noms des sorts et comment.",
		["Style"] = "Style",
		["How or whether to shorten spell names."] = "Détermine s'il faut raccourcir ou non les noms des sorts et comment.",
		["None"] = "Aucun",
		["Abbreviate"] = "Abbrévier",
		["Truncate"] = "Tronquer",
		["Do not shorten spell names."] = "Ne raccourci pas les noms des sorts.",
		["Gift of the Wild => GotW."] = "Marque du fauve => MdF",
		["Gift of the Wild => Gift of t..."] = "Marque du fauve => Marque du f...",
		["Length"] = "Longueur",
		["The length at which to shorten spell names."] = "Détermine la longueur à partir de laquelle les noms des sorts sont raccourcis.",
		["Critical hits/heals"] = "Soins/coups critiques",
		["Crushing blows"] = "Coups écrasants",
		["Glancing hits"] = "Coups éraflés",
		["Partial absorbs"] = "Absorbés partiellement",
		["Partial blocks"] = "Bloqués partiellement",
		["Partial resists"] = "Résistés partiellement",
		["Vulnerability bonuses"] = "Bonus de vulnérabilité",
		["Overheals"] = "Soins en excès",
		["<Text>"] = "<Texte>",
		["Enabled"] = "Activé",
		["Whether to enable showing this event modifier."] = "Affiche ou non ce modificateur d'événements.",
		["What color this event modifier takes on."] = "Détermine la couleur à utiliser pour ce modificateur d'événements.",
		["Text"] = "Texte",
		["What text this event modifier shows."] = "Détermine le texte à afficher pour ce modificateur d'événements.",
		["Physical"] = "Physique",
		["Holy"] = "Sacré",
		["Fire"] = "Feu",
		["Nature"] = "Nature",
		["Frost"] = "Givre",
		["Shadow"] = "Ombre",
		["Arcane"] = "Arcanes",
		["What color this damage type takes on."] = "Détermine la couleur à utiliser pour ce type de dégâts.",
		["Inherit"] = "Par héritage",
		["Thin"] = "Fin",
		["Thick"] = "Épais",
		["<Tag>"] = "<Tag>",
		["Uncategorized"] = "Non répertorié",
		["Tag"] = "Tag",
		["Tag to show for the current event."] = "Détermine le tag à afficher pour l'événement actuel.",
		["Color of the text for the current event."] = "Colorie le texte de l'événement actuel.",
		["Sound"] = "Son",
		["What sound to play when the current event occurs."] = "Détermine le son à jouer quand l'événement actuel se produit.",
		["Sticky"] = "En évidence",
		["Whether the current event should be classified as \"Sticky\""] = "Classe ou non l'événement actuel comme étant \"En évidence\"",
		["Custom font"] = "Police perso",
		["Font face"] = "Type de police",
		["Inherit font size"] = "Hériter de la taille de la police",
		["Font size"] = "Taille de la police",
		["Font outline"] = "Contour de la police",
		["Enable the current event."] = "Active l'événement actuel.",
		["Scroll area"] = "Zone de défilement",
		["Which scroll area to use."] = "Détermine la zone de défilement à utiliser.",
		["What timespan to merge events within.\nNote: a time of 0s means no throttling will occur."] = "Détermine le laps de temps pendant lequel les événements seront rassemblés.\nNote : un laps de 0s signife qu'aucun rassemblement ne sera fait.",
		["What amount to filter out. Any amount below this will be filtered.\nNote: a value of 0 will mean no filtering takes place."] = "Détermine la quantité à filter. Toute quantité inférieure sera filtrée.\nNotes : une valeur de 0 signifie qu'aucun filtrage ne sera fait.",
		["The amount of damage absorbed."] = "La quantité de dégâts absorbés.",
		["The amount of damage blocked."] = "La quantité de dégâts bloqués.",
		["The amount of damage resisted."] = "La quantité de dégâts résistés.",
		["The amount of vulnerability bonus."] = "La quantité de dégâts du bonus de vulnérabilité.",
		["The amount of overhealing."] = "La quantité de soins en excès.",
		["The normal text."] = "Le texte normal.",
}end)

local L_Display = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Display")
L_Display:AddTranslations("frFR", function() return {
		["None"] = "Aucun",
		["Thin"] = "Mince",
		["Thick"] = "Épais",
		["Text transparency"] = "Transparence du texte",
		["How opaque/transparent the text should be."] = "Détermine la transparence du texte.",
		["Icon transparency"] = "Transparence des icônes",
		["How opaque/transparent icons should be."] = "Détermine la transparence des icônes.",
		["Enable icons"] = "Activer les icônes",
		["Set whether icons should be enabled or disabled altogether."] = "Affiche ou non les icônes.",
		["Master font settings"] = "Paramètres de la police principale",
		["Normal font"] = "Police normale",
		["Normal font face."] = "Détermine la police d'écriture  à utiliser pour le texte normal.",
		["Normal font size"] = "Taille de la police normale",
		["Normal outline"] = "Contour de la police normale",
		["Sticky font"] = "Police en évidence",
		["Sticky font face."] = "Détermine la police d'écriture à utiliser pour les événements mis en évidence.",
		["Sticky font size"] = "Taille de la police en évidence",
		["Sticky outline"] = "Contour de la police en évidence",
}end)

local L_ScrollAreas = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_ScrollAreas")
L_ScrollAreas:AddTranslations("frFR", function() return {
		["Incoming"] = "Entrant",
		["Outgoing"] = "Sortant",
		["Notification"] = "Notification",
		["New scroll area"] = "Nouvelle zone de défilement",
		["Inherit"] = "Par héritage",
		["None"] = "Aucun",
		["Thin"] = "Fin",
		["Thick"] = "Épais",
		["Left"] = "Gauche",
		["Right"] = "Droite",
		["Disable"] = "Désactiver",
		["Options for this scroll area."] = "Options concernant cette zone de défilement.",
		["Name"] = "Nom",
		["Name of the scroll area."] = "Nom de la zone de défilement.",
		["<Name>"] = "<Nom>",
		["Remove"] = "Enlever",
		["Remove this scroll area."] = "Enlève cette zone de défilement.",
		["Icon side"] = "Côté de l'icône",
		["Set the icon side for this scroll area or whether to disable icons entirely."] = "Détermine de quel côté s'affichera les icônes pour cette zone de défilement, ou s'ils doivent être masqués.",
		["Test"] = "Test",
		["Send a test message through this scroll area."] = "Envoye un message de test dans cette zone de défilement.",
		["Normal"] = "Normal",
		["Send a normal test message."] = "Envoye un message de test normal.",
		["Sticky"] = "En évidence",
		["Send a sticky test message."] = "Envoye un message de test en évidence.",
		["Direction"] = "Direction",
		["Which direction the animations should follow."] = "Détermine la direction que les animations doivent suivre.",
		["Direction for normal texts."] = "Direction des textes normaux.",
		["Direction for sticky texts."] = "Direction des textes en évidence.",
		["Animation style"] = "Style d'animation",
		["Which animation style to use."] = "Détermine le style d'animation à utiliser.",
		["Animation style for normal texts."] = "Style d'animation pour les textes normaux.",
		["Animation style for sticky texts."] = "Style d'animation pour les textes en évidence.",
		["Position: horizontal"] = "Position : horizontale",
		["The position of the box across the screen"] = "La position horizontale de la boîte sur l'écran.",
		["Position: vertical"] = "Position : verticale",
		["The position of the box up-and-down the screen"] = "La position verticale de la boîte sur l'écran.",
		["Size"] = "Taille",
		["How large of an area to scroll."] = "Détermine la largeur de la zone de défilement.",
		["Scrolling speed"] = "Vitesse de défilement",
		["How fast the text scrolls by."] = "Détermine la rapidité avec laquelle le texte défile.",
		["Seconds for the text to complete the whole cycle, i.e. larger numbers means slower."] = "Le nombre de secondes pendant lesquelles le texte devra faire tout le cycle. Par exemple, de gros nombres rend le texte lent.",
		["Custom font"] = "Police perso",
		["Normal font face"] = "Police d'écriture normale",
		["Normal inherit font size"]  = "Hériter de la taille de la police normale",
		["Normal font size"] = "Taille de la police normale",
		["Normal font outline"] = "Contour de la police normale",
		["Sticky font face"] = "Police d'écriture en évidence",
		["Sticky inherit font size"] = "Hériter de la taille de la police en évidence",
		["Sticky font size"] = "Taille de la police en évidence",
		["Sticky font outline"] = "Contour de la police en évidence",
		["Click and drag to the position you want."]  = "Cliquer et saisir vers la position désirée.",
		["Scroll area: %s"] = "Zone de défilement : %s",
		["Position: %d, %d"] = "Position : %d, %d",
		["Scroll areas"] = "Zones de défilement",
		["Options regarding scroll areas."] = "Options concernant les zones de défilement.",
		["Configuration mode"] = "Mode de configuration",
		["Enter configuration mode, allowing you to move around the scroll areas and see them in action."] = "Entre dans le mode de configuration, vous permettant de déplacer les zones de défilement et de les voir en action.",
		["New scroll area"] = "Nouvelle zone de défilement",
		["Add a new scroll area."] = "Ajoute une nouvelle zone de défilement",
		--new below (Missed locale,used frFR)
		["Center of screen"] = "Center of screen",
		["Edge of screen"] = "Center of screen",
		["Create"] = "Create",
		["Are you sure?"] = "Are you sure?",
		["Send"] = "Send",
}end)

local L_Suppressions = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Suppressions")
L_Suppressions:AddTranslations("frFR", function() return {
		["New suppression"] = "Nouvelle suppression",
		["Edit"] = "Éditer",
		["Edit search string"] = "Édite le string à rechercher.",
		["<Any text> or <Lua search expression>"] = "<N'importe quel texte> ou <expression de recherche Lua>",
		["Lua search expression"] = "Expression de recherche Lua",
		["Whether the search string is a lua search expression or not."] = "Indique si le string à rechercher est une expression de recherche lua ou non.",
		["Remove"] = "Enlever",
		["Remove suppression"] = "Enlève la suppression.",
		["Suppressions"] = "Suppressions",
		["List of strings that will be squelched if found."] = "Liste des strings qui seront mis sous silence si trouvés.",
		["Add a new suppression."] = "Ajoute une nouvelle suppression.",
		--new below (Missed locale,used frFR)
		-- ["Create"] = true,
}end)

local L_Triggers = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Triggers")
L_Triggers:AddTranslations("frFR", function() return {
		["%s!"] = "%s !",
		["Low Health!"] = "Vie faible !",
		["Low Mana!"] = "Mana faible !",
		["Low Pet Health!"] = "Fam. Vie faible !",
		["Free %s!"] = "%s gratuit !",
		["Trigger cooldown"] = "Temps de recharge du déclencheur",
		["Check every XX seconds"] = "Vérifier toutes les XX secondes",
		["Triggers"] = "Déclencheurs",
		["New trigger"] = "Nouveau déclencheur",
		["Create a new trigger"] = "Créer un nouveau déclencheur",
		["Inherit"] = "Par héritage",
		["None"] = "Aucun",
		["Thin"] = "Fin",
		["Thick"] = "Épais",
		["Druid"] = "Druide",
		["Rogue"] = "Voleur",
		["Shaman"] = "Chaman",
		["Paladin"] = "Paladin",
		["Mage"] = "Mage",
		["Warlock"] = "Démoniste",
		["Priest"] = "Prêtre",
		["Warrior"] = "Guerrier",
		["Hunter"] = "Chasseur",
		["Output"] = "Sortie",
		["The text that is shown"] = "Détermine le texte à afficher.",
		['<Text to show>'] = "<Texte à afficher>",
		["Icon"] = "Icône",
		["The icon that is shown"] = "Détermine l'icône à afficher.",
		['<Spell name> or <Item name> or <Path> or <SpellId>'] = "<Nom du sort> ou <Nom de l'objet> ou <Chemin d'accès> ou <SpellId>",--need locale
		["Enabled"] = "Activé",
		["Whether the trigger is enabled or not."] = "Active ou non ce déclencheur.",
		["Remove trigger"] = "Enlever le déclencheur",
		["Remove this trigger completely."] = "Enlève complètement ce déclencheur.",
		["Color"] = "Couleur",
		["Color of the text for this trigger."] = "Détermine la couleur du texte de ce déclencheur.",
		["Sticky"] = "En évidence",
		["Whether to show this trigger as a sticky."] = "Affiche ou non ce déclencheur en évidence.",
		["Classes"] = "Classes",
		["Classes affected by this trigger."] = "Détermine les classes affectées par ce déclencheur.",
		["Scroll area"] = "Zone de défilement",
		["Which scroll area to output to."] = "Détermine la zone de défilement de la sortie.",
		["Sound"] = "Son",
		["What sound to play when the trigger is shown."] = "Détermine le son à jouer quand le déclencheur est affiché.",
		["Test"] = "Test",
		["Test how the trigger will look and act."] = "Teste la façon dont le déclencheur se présente et réagit.",
		["Custom font"] = "Police perso",
		["Font face"] = "Type de police",
		["Inherit font size"] = "Hériter de la taille de la police",
		["Font size"] = "Taille de la police",
		["Font outline"] = "Contour de la police",
		["Primary conditions"] = "Conditions primaires",
		["When any of these conditions apply, the secondary conditions are checked."] = "Quand n'importe laquelle de ces conditions s'appliquent, les conditions secondaires sont vérifiées",
		["New condition"] = "Nouvelle condition",
		["Add a new primary condition"] = "Ajouter une nouvelle condition primaire",
		["Remove condition"] = "Enlever la condition",
		["Remove a primary condition"] = "Enlève une condition primaire.",
		["Secondary conditions"] = "Conditions secondaires",
		["When all of these conditions apply, the trigger will be shown."] = "quand n'importe laquelle de ces conditions s'appliquent, le déclencheur est affiché.",
		["Add a new secondary condition"] = "Ajouter une nouvelle condition secondaire",
		["Remove a secondary condition"] = "Enlever une condition secondaire",
		--new below (Missed locale,used frFR)
		["Create"] = "Create",
		["Remove"] = "Remove",
		["Are you sure?"] = "Are you sure?",
}end)

local L_AnimationStyles = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_AnimationStyles")
L_AnimationStyles:AddTranslations("frFR", function() return {
		["Straight"] = "Droit/Direct",
		["Up, left-aligned"] = "Vers le haut, alignés à gauche",
		["Up, right-aligned"] = "Vers le haut, alignés à droite",
		["Up, center-aligned"] = "Vers le haut, alignés au centre",
		["Down, left-aligned"] = "Vers le bas, alignés à gauche",
		["Down, right-aligned"] = "Vers le bas, alignés à droite",
		["Down, center-aligned"] = "Vers le bas, alignés au centre",
		["Parabola"] = "Parabole",
		["Up, left"] = "Vers le haut, gauche",
		["Up, right"] = "Vers le haut, droite",
		["Up, alternating"] = "Vers le haut, alternant",
		["Down, left"] = "Vers le bas, gauche",
		["Down, right"] = "Vers le bas, droite",
		["Down, alternating"] = "Vers le bas, alternant",
		["Semicircle"] = "Demi-cercle",
		["Pow"] = "Pow",
		["Static"] = "Statique",
		["Rainbow"] = "Arc-en-ciel",
		["Horizontal"] = "Horizontal",
		["Left"] = "Gauche",
		["Right"] = "Droite",
		["Alternating"] = "Alternant",
		["Action"] = "Action",
		["Action Sticky"] = "Action en évidence",
		["Angled"] = "Angulaire",
		["Sprinkler"] = "Sprinkler",
		["Up, clockwise"] = "Vers le haut, sens des aiguilles d'une montre",
		["Down, clockwise"] = "Vers le bas, sens des aiguilles d'une montre",
		["Left, clockwise"] = "Gauche, sens des aiguilles d'une montre",
		["Right, clockwise"] = "Droite, sens des aiguilles d'une montre",
		["Up, counter-clockwise"] = "Vers le haut, sens inverse des aiguilles d'une montre",
		["Down, counter-clockwise"] = "Vers le bas, sens inverse des aiguilles d'une montre",
		["Left, counter-clockwise"] = "Gauche, sens inverse des aiguilles d'une montre",
		["Right, counter-clockwise"] = "Droite, sens inverse des aiguilles d'une montre",
}end)

local L_Auras = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Auras")
L_Auras:AddTranslations("frFR", function() return {
		["Auras"] = "Auras",
		["Debuff gains"] = "Gain d'un débuff",
		["The name of the debuff gained."] = "Le nom du débuff gagné.",
		["Buff gains"] = "Gain d'un buff",
		["The name of the buff gained."] = "Le nom du buff gagné.",
		["Item buff gains"] = "Gain d'un buff d'objet",
		["The name of the item buff gained."] = "Le nom du buff d'objet gagné.",
		["The rank of the item buff gained."] = "Le rang du buff d'objet gagné.",
		["Debuff fades"] = "Disparition d'un débuff",
		["The name of the debuff lost."] = "Le nom du débuff perdu.",
		["Buff fades"] = "Disparition d'un buff",
		["The name of the buff lost."] = "Le nom du buff perdu.",
		["Item buff fades"] = "Disparition d'un buff d'objet",
		["The name of the item buff lost."] = "Le nom du buff d'objet perdu.",
		["The rank of the item buff lost."] = "Le rang du buff d'objet perdu.",
		["Self buff gain"] = "Gain d'un buff sur le joueur",
		["<Buff name>"] = "<nom du buff>",
		["Self buff fade"] = "Disparition d'un buff sur le joueur",
		["Self debuff gain"] = "Gain d'un débuff sur le joueur",
		["<Debuff name>"] = "<nom du débuff>",
		["Self debuff fade"] = "Disparition d'un débuff sur le joueur",
		["Self item buff gain"] = "Gain d'un buff d'objet sur le joueur",
		["<Item buff name>"] = "<nom du buff de l'objet>",
		["Self item buff fade"] = "Disparition d'un buff d'objet sur le joueur",
		["Target buff gain"] = "Gain d'un buff sur la cible",
		["Target debuff gain"] = "Gain d'un débuff sur la cible",
		["Buff inactive"] = "Buff inactif",
		["Buff active"] = "Buff actif",
}end)

local L_CombatEvents_Data = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_CombatEvents_Data")
L_CombatEvents_Data:AddTranslations("frFR", function() return {
		["Incoming damage"] = "Dégâts reçus",
		["Melee damage"] = "Dégâts en mêlée",
		["Melee"] = "Mêlée",
		["The name of the enemy that attacked you."] = "Le nom de l'ennemi qui vous a attaqué.",
		["The amount of damage done."] = "La quantité de dégâts infligés.",
		[" (%d hit, %d crit)"] = " (%d impact, %d crit)",
		[" (%d hit, %d crits)"] = " (%d impact, %d crits)",
		[" (%d hits, %d crit)"] = " (%d impacts, %d crit)",
		[" (%d hits, %d crits)"] = " (%d impacts, %d crits)",
		[" (%d crits)"] = " (%d crits)",
		[" (%d hits)"] = " (%d impacts)",
		["Multiple"] = "Multiple",
		["Melee misses"] = "Att. en mêlée ratées",
		["Miss!"] = "Rate !",
		["Melee dodges"] = "Att. en mêlée esquivées",
		["Dodge!"] = "Esquive !",
		["Melee parries"] = "Att. en mêlée parées",
		["Parry!"] = "Parade !",
		["Melee blocks"] = "Att. en mêlée bloquées",
		["Block!"] = "Blocage !",
		["Melee absorbs"] = "Att. en mêlée absorbées",
		["Absorb!"] = "Absorbe !",
		["Melee immunes"] = "Att. en mêlée sans effet",
		["Immune!"] = "Insensible !",
		["Melee evades"] = "Att. en mêlée évitées",
		["Evade!"] = "Evite !",
		["Skills"] = "Compétences",
		["Skill damage"] = "Dégâts des compétences",
		["The type of damage done."] = "Le type de dégâts infligés.",
		["The spell or ability that the enemy attacked you with."] = "Le sort ou la capacité avec lequel l'ennemi vous a attaqué.",
		["DoTs and HoTs"] = "DoTs et HoTs",
		["Skill DoTs"] = "Dégâts sur la durée",
		["Ability misses"] = "Capacités ratées",
		["Ability dodges"] = "Capacités esquivées",
		["Ability parries"] = "Capacités parées",
		["Ability blocks"] = "Capacités bloquées",
		["Spell resists"] = "Sorts résistés",
		["Resist!"] = "Résiste !",
		["Skill absorbs"] = "Compétences absorbées",
		["Skill immunes"] = "Compétences sans effet",
		["Skill reflects"] = "Compétences renvoyées",
		["Reflect!"] = "Renvoie !",
		["Skill interrupts"] = "Compétences interrompues",
		["Interrupt!"] = "Interrompu !",
		["Incoming heals"] = "Soins reçus",
		["Heals"] = "Soins",
		["The name of the ally that healed you."] = "Le nom de l'allié qui vous a soigné.",
		["The spell or ability that the ally healed you with."] = "Le sort ou la capacité avec lequel l'allié vous a soigné.",
		["The amount of healing done."] = "La quantité de soins prodigués.",
		[" (%d heal, %d crit)"] = " (%d soin, %d crit)",
		[" (%d heal, %d crits)"] = " (%d soin, %d crits)",
		[" (%d heals, %d crit)"] = " (%d soins, %d crit)",
		[" (%d heals, %d crits)"] = " (%d soins, %d crits)",
		[" (%d heals)"] = " (%d soins)",
		["Heals over time"] = "Soins sur la durée",
		["Environmental damage"] = "Dégâts de l'environnement",
		["Outgoing damage"] = "Dégâts infligés",
		["The name of the enemy you attacked."] = "Le nom de l'ennemi que vous avez attaqué.",
		["The spell or ability that you used."] = "Le sort ou la capacité que vous avez utilisé.",
		["Skill evades"] = "Compétences évitées",
		["Outgoing heals"] = "Soins prodigués",
		["The name of the ally you healed."] = "Le nom de l'allié que vous avez soigné.",
		["Pet melee"] = "Att. en mêlée du fam.",
		["Pet melee damage"] = "Dégâts en mêlée du fam.",
		["(Pet) -[Amount]"] = "(Fam.) -[Amount]",
		["(Pet) +[Amount]"] = "(Fam.) +[Amount]",
		["Pet heals"] = "Soins du familier",
		["The name of the enemy your pet attacked."] = "Le nom de l'ennemi que votre familier a attaqué.",
		["Pet melee misses"] = "(Fam.) Att. en mêlée ratés",
		["Pet Miss!"] = "Fam. Rate !",
		["Pet melee dodges"] = "(Fam.) Att. en mêlée esquivées",
		["Pet Dodge!"] = "Fam. Esquive !",
		["Pet melee parries"] = "(Fam.) Att. en mêlée parées",
		["Pet Parry!"] = "Fam. Parade !",
		["Pet melee blocks"] = "(Fam.) Att. en mêlée bloquées",
		["Pet Block!"] = "Fam. Blocage !",
		["Pet melee absorbs"] = "(Fam.) Att. en mêlée absorbées",
		["Pet Absorb!"] = "Fam. Absorbe !",
		["Pet melee immunes"] = "(Fam.) Att. en mêléesans effet",
		["Pet Immune!"] = "Fam. Insensible !",
		["Pet melee evades"] = "(Fam.) Att. en mêlée évitées",
		["Pet Evade!"] = "Fam. Evite !",
		["Pet skills"] = "(Fam.) Compétences",
		["Pet skill"] = "(Fam.) Compétence",
		["Pet skill damage"] = "(Fam.) Dégâts des compétences",
		["Pet [Amount] ([Skill])"] = "Fam. [Amount] ([Skill])",
		["The ability or spell your pet used."] = "La capacité ou le sort utilisé par votre familier.",
		["Pet ability misses"] = "(Fam.) Capacités ratées",
		["Pet ability dodges"] = "(Fam.) Capacités esquivées",
		["Pet ability parries"] = "(Fam.) Capacités parées",
		["Pet ability blocks"] = "(Fam.) Capacités. bloquées",
		["Pet spell resists"] = "(Fam.) Sorts résistés",
		["Pet Resist!"] = "Fam. Résiste !",
		["Pet skill absorbs"] = "(Fam.) Compétences absorbées",
		["Pet skill immunes"] = "(Fam.) Compétences sans effet",
		["Pet skill reflects"] = "(Fam.) Compétences renvoyées",
		["Pet Reflect!"] = "Fam. Renvoie !",
		["Pet skill evades"] = "(Fam.) Compétences évitées",
		["Combat status"] = "Statut du combat",
		["Enter combat"] = "Début du combat",
		["Leave combat"] = "Fin du combat",
		["Power gain/loss"] = "Gains/Pertes de puissance",
		["Power change"] = "Changement de puissance",
		["Power gain"] = "Gains de puissance",
		["+[Amount] [Type]"] = "+[Amount] [Type]",
		["The amount of power gained."] = "La quantité de puissance gagnée.",
		["The type of power gained (Mana, Rage, Energy)."] = "Le type de puissance gagné (Mana, rage ou énergie).",
		["The ability or spell used to gain power."] = "La capacité ou le sort utilisé pour gagner de la puissance.",
		["The character that the power comes from."] = "Le personnage à l'origine du gain de puissance.",
		[" (%d gains)"] = " (%d gains)",
		["Power loss"] = "Pertes de puissance",
		["-[Amount] [Type]"] = "-[Amount] [Type]",
		["The amount of power lost."] = "La quantité de puissance perdue.",
		["The type of power lost (Mana, Rage, Energy)."] = "Le type de puissance perdue (Mana, rage ou énergie).",
		["The ability or spell take away your power."] = "La capacité ou le sort qui a pris votre puissance.",
		["The character that caused the power loss."] = "Le personnage à l'origine de la perte de puissance.",
		[" (%d losses)"] = " (%d perdus)",
		["Combo points"] = "Points de combo",
		["Combo point gain"] = "Gains de point de combo",
		["[Num] CP"] = "[Num] PC",
		["The current number of combo points."] = "Le nombre actuel de points de combo.",
		["Combo points full"] = "Points de combo au max.",
		["[Num] CP Finish It!"] = "[Num] PC - Finis-le !",
		["Honor gains"] = "Gains d'honneur",
		["The amount of honor gained."] = "La quantité d'honneur gagnée.",
		["The name of the enemy slain."] = "Le nom de l'ennemi tué.",
		["The rank of the enemy slain."] = "Le rang de l'ennemi tué.",
		["Reputation"] = "Réputation",
		["Reputation gains"] = "Gains de réputation",
		["The amount of reputation gained."] = "La quantité de points de réputation gagnée.",
		["The name of the faction."] = "Le nom de la faction.",
		["Reputation losses"] = "Pertes de réputation",
		["The amount of reputation lost."] = "La quantité de points de réputation perdue.",
		["Skill gains"] = "Gains de compétence",
		["The skill which experienced a gain."] = "La compétence qu",
		["The amount of skill points currently."] = "Le nombre actuel de points de compétence.",
		["Experience gains"] = "Gains d'expérience",
		["The name of the enemy slain."] = "Le nom de l'ennemi tué.",
		["The amount of experience points gained."] = "Le nombre de points d'expérience gagnés.",
		["Killing blows"] = "Coups fatals",
		["Player killing blows"] = "Coups fatals joueur",
		["Killing Blow!"] = "Coup fatal !",
		["The spell or ability used to slay the enemy."] = "Le sort ou la capacité utilisé pour tuer l'ennemi.",
		["NPC killing blows"] = "Coups fatals PNJ",
		["Soul shard gains"] = "Gains de fragment d'âme",
		["The name of the soul shard."] = "Le nom du fragment d'âme.",
		["Extra attacks"] = "Attaques supplémentaires",
		["%s!"] = "%s !",
		["The name of the spell or ability which provided the extra attacks."] = "Le nom du sort ou de la capacité qui enclenchent les attaques supplémentaires.",
		--new below (Missed locale,used frFR)
-- 		["Self heals"] = true,
-- 		["Self heals over time"] = true,
-- 		["Pet skill DoTs"] = true,
-- 		["Skill you were interrupted in casting"] = true,
-- 		["The spell you interrupted"] = true,
}end)

local L_Cooldowns = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Cooldowns")
L_Cooldowns:AddTranslations("frFR", function() return {
		["Cooldowns"] = "Temps de recharge",
		["Skill cooldown finish"] = "fin du temps de recharge de la compétence",
		["[[Skill] ready!]"] = "[[Skill] prêt !]",
		["The name of the spell or ability which is ready to be used."] = "Le nom du sort ou de la capacité qui est prête à être utilisée.",
		["Traps"] = "Pièges",
		["Shocks"] = "Horions",
		["Divine Shield"] = "Bouclier divin",
		["%s Tree"] = "Arbre %s",
		["Spell ready"] = "Sort prêt",
		["<Spell name>"] = "<Nom du sort>",
}end)

local L_Loot = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Loot")
L_Loot:AddTranslations("frFR", function() return {
		["Loot"] = "Butin",
		["Loot items"] = "Objets du butin",
		["Loot [Name] +[Amount]([Total])"] = "Butin : [Name] +[Amount]([Total])",
		["The name of the item."] = "Le nom de l'objet.",
		["The amount of items looted."] = "La quantité d'objets ramassés.",
		["The total amount of items in inventory."] = "Le nombre total des objets dans l'inventaire.",
		["Loot money"] = "Argent du butin",
		["Loot +[Amount]"] = "Butin : +[Amount]",
		["The amount of gold looted."] = "La quantité d'or ramassé.",
}end)

local L_TriggerConditions_Data = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_TriggerConditions_Data")
L_TriggerConditions_Data:AddTranslations("frFR", function() return {
		["Enemy target health percent"] = "Pourcentage de vie de la cible ennemie",
		["Friendly target health percent"] = "Pourcentage de vie de la cible amie",
		["Self health percent"] = "Pourcentage de vie du joueur",
		["Self mana percent"] = "Pourcentage de mana du joueur",
		["Pet health percent"] = "Pourcentage de vie du fam.",
		["Incoming block"] = "Blocage de la cible",
		["Incoming crit"] = "Critique de la cible",
		["Incoming dodge"] = "Esquive de la cible",
		["Incoming parry"] = "Parade de la cible",
		["Outgoing block"] = "Blocage du joueur",
		["Outgoing crit"] = "Critique du joueur",
		["Outgoing dodge"] = "Esquive du joueur",
		["Outgoing parry"] = "Parade du joueur",
		["Outgoing cast"] = "Incantation du joueur",
		["<Skill name>"] = "<Nom de la compétence>",
		["Incoming cast"] = "Incantation de la cible",
		["Minimum power amount"] = "Quantité minimale de puissance",
		["Warrior stance"] = "Posture du guerrier",
		["Not in warrior stance"] = "Pas en posture du guerrier",
		["Battle Stance"] = "Posture de combat",
		["Defensive Stance"] = "Posture défensive",
		["Berserker Stance"] = "Posture berserker",
}end)

local L_CombatStatus = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_CombatStatus")
L_CombatStatus:AddTranslations("frFR", function() return {
		["Combat status"] = "Statut du combat",
		["Enter combat"] = "Début du combat",
		["+Combat"] = "+Combat",
		["Leave combat"] = "Fin du combat",
		["-Combat"] = "-Combat",
		["In combat"] = "En combat",
		["Not in combat"] = "Pas en combat",
}end)
