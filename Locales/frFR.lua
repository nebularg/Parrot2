local L = LibStub("AceLocale-3.0"):NewLocale("Parrot", "frFR")
if not L then return end

L[" (%d crits)"] = "(%d crits)"
L[" (%d gains)"] = "(%d gagné)"
L[" (%d heal, %d crit)"] = "(%d soin, %d crit)"
L[" (%d heal, %d crits)"] = "%d soin, %d crits)"
L[" (%d heals)"] = "(%d soins)"
L[" (%d heals, %d crit)"] = "(%d soins, %d crit)"
L[" (%d heals, %d crits)"] = "(%d soins, %d crits)"
L[" (%d hit, %d crit)"] = "(%d impact, %d crit)"
L[" (%d hit, %d crits)"] = "(%d impact, %d crits)"
L[" (%d hits)"] = "(%d impacts)"
L[" (%d hits, %d crit)"] = "(%d impacts, %d crit)"
L[" (%d hits, %d crits)"] = "(%d impacts, %d crits)"
-- L[" ([Amount] absorbed)"] = " ([Amount] absorbed)"
L[" ([Amount] blocked)"] = "([Amount] bloqués)"
L[" ([Amount] overheal)"] = "([Amount] en excès)"
L[" ([Amount] overkill)"] = "([Amount] en excès)"
L[" ([Amount] resisted)"] = "([Amount] résistés)"
L[" ([Amount] vulnerable)"] = "([Amount] de vulnérabilité)"
L["%s Tree"] = "Branche %s"
L["%s failed"] = "%s échoué"
L["%s stole %s"] = "%s gagné %s"
L["%s!"] = "%s!"
L["+Combat"] = "+Combat"
L["-Combat"] = "-Combat"
L["<Any text> or <Lua search expression>"] = "<N'importe quel texte> ou <expression de recherche Lua>"
-- L["<Buff name or spell id>"] = "<Buff name or spell id>"
L["<Item name>"] = "<nom de l'objet>"
L["<Name>"] = "<Nom>"
L["<Skill name>"] = "<Nom de la compétence>"
L["<Spell name>"] = "<Nom du sort>"
L["<Spell name> or <Item name> or <Path> or <SpellId>"] = "<Nom du sort> ou <Nom de l'objet> ou <Chemin d'accès> ou <SpellId>"
L["<SpellId>"] = "<SpellId>"
L["<Tag>"] = "<Tag>"
L["<Text to show>"] = "<Texte à afficher>"
-- L["AP"] = "AP"
L["Abbreviate"] = "Abréger"
-- L["Abbreviate number values displayed (26500 -> 26.5k)"] = "Abbreviate number values displayed (26500 -> 26.5k)"
L["Action"] = "Action"
L["Action Sticky"] = "Action en évidence"
L["Add a new filter."] = "Ajouter un nouveau filtre."
L["Add a new primary condition"] = "Ajouter une nouvelle condition primaire"
L["Add a new scroll area."] = "Ajoute une nouvelle zone de défilement"
L["Add a new secondary condition"] = "Ajouter une nouvelle condition secondaire"
L["Add a new suppression."] = "Ajoute une nouvelle suppression."
L["Add a new throttle."] = "Ajouter un nouveau limitateur"
L["Alternating"] = "Alternant"
L["Always hide skill names even when present in the tag"] = "Toujours cacher le nom des sorts même s'il est dans la phrase"
L["Always hide unit names even when present in the tag"] = "Toujours cacher le nom de l'unité même s'il est dans la phrase"
L["Amount"] = "Total"
L["Amount of damage to compare with"] = "Quantité de dommage à comparer avec"
L["Amount of health to compare"] = "Quantité de vie à comparer"
L["Amount of power to compare"] = "Quantité de puissance à comparer"
L["Amount of stacks of the aura"] = "Total des superpositions de l'aura"
L["Amount of the damage that was missed."] = "Quantité des dommages qui ont été manqués."
L["Angled"] = "Angulaire"
L["Animation style"] = "Style d'animation"
L["Animation style for normal texts."] = "Style d'animation pour les textes normaux."
L["Animation style for sticky texts."] = "Style d'animation pour les textes en évidence."
L["Any"] = "N'importe"
L["Are you sure?"] = "Êtes-vous sur?"
-- L["Artifact power gains"] = "Artifact power gains"
L["Aura active"] = "Aura active"
L["Aura fade"] = "Disparition de l'aura"
L["Aura gain"] = "Gain de l'aura"
L["Aura stack gain"] = "Gain d'uns superposition d'aura"
L["Aura type"] = "Type d'aura"
L["Auras"] = "Auras"
L["Avoids"] = "Évite"
L["Both"] = "Les deux"
-- L["Break up amounts"] = "Break up amounts"
-- L["Break up number values with '%s' (26500 -> %s)"] = "Break up number values with '%s' (26500 -> %s)"
L["Buff"] = "Buff"
L["Buff active"] = "Buff actif"
L["Buff fades"] = "Disparition d'un buff"
L["Buff gains"] = "Gain d'un buff"
L["Buff inactive"] = "Buff inactif"
L["Buff name"] = "Nom du buff"
L["Buff name or spell id"] = "Nom ou id du buff"
L["Buff stack gains"] = "Gain d'un empilement de buff"
-- L["Cast started"] = "Cast started"
L["Center of screen"] = "Centre de l'écran"
L["Change event settings"] = "Modifie les paramètres des événements."
L["Check periodically"] = "Vérifier toutes les XX secondes"
L["Classes"] = "Classes"
L["Classes affected by this trigger."] = "Détermine les classes affectées par ce déclencheur."
L["Click and drag to the position you want."] = "Cliquer et déplacer vers la position désirée."
L["Click to remove"] = "Cliquez ici pour supprimer"
L["Color"] = "Couleur"
L["Color by class"] = "Colorer par classe"
L["Color in which to flash"] = "Couleur du flash"
L["Color of the text for the current event."] = "Colorie le texte de l'événement actuel."
L["Color of the text for this trigger."] = "Détermine la couleur du texte de ce déclencheur."
L["Color unit names by class"] = "Colorer le nom de l'unité en fonction de sa classe"
L["Combat status"] = "Statut du combat"
L["Combo point gain"] = "Gain d'un point de combo"
L["Combo points"] = "Points de combo"
L["Combo points full"] = "Points de combo au max."
L["Comparator Type"] = "Type de comparateur"
L["Configuration mode"] = "Mode de configuration"
-- L["Configure what the Trigger should look like"] = "Configure what the Trigger should look like"
L["Control game options"] = "Options de contrôle du jeu"
L["Cooldowns"] = "Temps de recharge"
L["Create a new trigger"] = "Créer un nouveau déclencheur"
L["Critical hits/heals"] = "Soins/coups critiques"
L["Crushing blows"] = "Coups écrasants"
-- L["Currency gains"] = "Currency gains"
L["Custom font"] = "Police personnalisée"
L["Damage"] = "Dommage"
L["Damage types"] = "Types de dégâts"
L["Debuff"] = "Debuff"
L["Debuff active"] = "Debuff actif"
L["Debuff fades"] = "Disparition d'un débuff"
L["Debuff gains"] = "Gain d'un débuff"
L["Debuff inactive"] = "Debuff inactif"
L["Debuff stack gains"] = "Gain d'empilement d'un débuff"
L["Direction"] = "Direction"
L["Direction for normal texts."] = "Direction des textes normaux."
L["Direction for sticky texts."] = "Direction des textes en évidence."
L["Disable"] = "Désactiver"
-- L["Disable in pvp"] = "Disable in pvp"
-- L["Disable in raids"] = "Disable in raids"
-- L["Disable this module while in a battleground"] = "Disable this module while in a battleground"
-- L["Disable this module while in a raid instance"] = "Disable this module while in a raid instance"
L["Dispel"] = "Dissiper"
L["Dispel fail"] = "Dissipation ratée"
L["Do not shorten spell names."] = "Ne pas raccourcir les noms des sorts."
L["Do not show heal events when 100% of the amount is overheal"] = "Ne pas afficher les soins quand le total du sursoin est de 100%"
L["DoTs and HoTs"] = "DoTs et SoTs"
L["Down, alternating"] = "Vers le bas, alternant"
L["Down, center-aligned"] = "Vers le bas, alignés au centre"
L["Down, clockwise"] = "Vers le bas, sens des aiguilles d'une montre"
L["Down, counter-clockwise"] = "Vers le bas, sens inverse des aiguilles d'une montre"
L["Down, left"] = "Vers le bas, gauche"
L["Down, left-aligned"] = "Vers le bas, alignés à gauche"
L["Down, right"] = "Vers le bas, droite"
L["Down, right-aligned"] = "Vers le bas, alignés à droite"
L["Druid Form"] = "Forme du druide"
L["Edge of screen"] = "Bord de l'écran"
L["Edit"] = "Éditer"
L["Edit search string"] = "Éditer la chaîne à rechercher."
L["Enable icons"] = "Activer les icônes"
L["Enable the current event."] = "Active l'événement actuel."
L["Enable to show crits in the sticky style."] = "Affiche ou non les critiques dans le style En évidence."
L["Enabled"] = "Activé"
L["Enemy buff fades"] = "Disparition du buff de l'ennemi"
L["Enemy buff gains"] = "Gain du buff de l'ennemi"
L["Enemy debuff fades"] = "Disparition du debuff de l'ennemi"
L["Enemy debuff gains"] = "Gain du debuff de l'ennemi"
L["Enter combat"] = "Début du combat"
L["Enter configuration mode, allowing you to move around the scroll areas and see them in action."] = "Entre dans le mode de configuration, vous permettant de déplacer les zones de défilement et de les voir en action."
L["Environmental damage"] = "Dégâts de l'environnement"
L["Event modifiers"] = "Modificateurs d'événements"
L["Events"] = "Événements"
L["Experience gains"] = "Expérience gagnée"
L["Extra attacks"] = "Attaques supplémentaires"
L["Filter incoming spells"] = "Filtrer les sorts entrants"
L["Filter outgoing spells"] = "Filtrer les sorts sortants"
L["Filter when amount is lower than this value (leave blank to filter everything)"] = "Filtre lorsque le montant est inférieur à cette valeur (laisser vide pour tout filtrer)"
L["Filters"] = "Filtres"
L["Filters that are applied to a single spell"] = "Les filtres sont appliqués à une seule période"
L["Filters to be checked for a minimum amount of damage/healing/etc before showing."] = "Détermine les filtres à vérifier avant affichage des dégâts/soins/etc."
L["Flash screen in specified color"] = "Flash de l'écran dans la couleur spécifié"
L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."] = "Texte de combat flottant. Croac. Coco veut un gâteau."
L["Font face"] = "Type de police"
L["Font outline"] = "Contour de la police"
L["Font size"] = "Taille de la police"
L["General"] = "Général"
L["General settings"] = "Permet de configurer les paramètres généraux."
L["Gift of the Wild => Gift of t..."] = "Don du fauve => Don du f..."
L["Gift of the Wild => GotW."] = "Don du fauve => DdF"
L["Glancing hits"] = "Coups éraflés"
L["Heals"] = "Soins"
L["Heals over time"] = "Soins au court du temps"
L["Hide events used in triggers"] = "Cacher les évènements utilisés dans le gestionnaire"
L["Hide full overheals"] = "Cacher les sursoins totals"
L["Hide realm"] = "Cacher le royaume"
L["Hide realm in player names"] = "Cacher le royaume dans le nom des joueurs"
L["Hide skill names"] = "Cacher le nom du sort"
L["Hide unit names"] = "Cacher les noms des unités"
L["Hides combat events when they were used in triggers"] = "Cacher les évènements de combat quand ils ont été utilisés dans le gestionnaire"
L["Horizontal"] = "Horizontal"
L["Hostility"] = "Hositilité"
L["How fast the text scrolls by."] = "Détermine la rapidité avec laquelle le texte défile."
L["How large of an area to scroll."] = "Détermine la largeur de la zone de défilement."
L["How opaque/transparent icons should be."] = "Détermine la transparence des icônes."
L["How opaque/transparent the text should be."] = "Détermine la transparence du texte."
L["How or whether to shorten spell names."] = "Détermine s'il faut raccourcir ou non les noms des sorts et comment."
L["How to compare actual value with parameter"] = "Comment comparer la valeur actuelle avec des paramètres"
L["Icon"] = "Icône"
L["Icon side"] = "Côté de l'icône"
L["Icon transparency"] = "Transparence des icônes"
L["Ignore"] = "Ignorer"
L["Ignore Cooldown"] = "Ignorer Cooldown"
L["In a group"] = "Dans un groupe"
L["In combat"] = "En combat"
L["In vehicle"] = "état secondaire de déclenchement"
L["Incoming"] = "Entrants"
L["Incoming cast"] = "Incantation de la cible"
L["Incoming crit"] = "Critique sur le joueur"
L["Incoming damage"] = "Dégâts reçus"
L["Incoming events are events which a mob or another player does to you."] = "Les événements entrants sont les événements que les monstres et les autres joueurs font sur vous."
L["Incoming heals"] = "Soins reçus"
L["Incoming miss"] = "Les coups ratés reçus"
L["Inherit"] = "Par héritage"
L["Inherit font size"] = "Hériter de la taille de la police"
L["Interval for collecting data"] = "Intervale pour la récupération de données"
L["Item buff active"] = "Buff activ de l'objet"
L["Item buff fade"] = "Disparition du buff de l'objet"
L["Item buff fades"] = "Disparition d'un buff d'objet"
L["Item buff gain"] = "Gain du buff de l'objet"
L["Item buff gains"] = "Gain d'un buff d'objet"
L["Item cooldown ready"] = "Objet prêt"
L["Killing Blow!"] = "Coup fatal !"
L["Killing blows"] = "Coups fatals"
L["Leave combat"] = "Fin du combat"
L["Left"] = "Gauche"
L["Left, clockwise"] = "Gauche, sens des aiguilles d'une montre"
L["Left, counter-clockwise"] = "Gauche, sens inverse des aiguilles d'une montre"
L["Length"] = "Longueur"
L["List of strings that will be squelched if found."] = "Liste des chaînes qui seront écrasées si elles sont trouvées."
L["Load config"] = "chargement config"
L["Load configuration options"] = "Charger les options de configuration"
L["Loot"] = "Butin"
L["Loot +[Amount]"] = "Butin : +[Amount]"
L["Loot [Name] +[Amount]([Total])"] = "Butin : [Name] +[Amount]([Total])"
L["Loot items"] = "Objets du butin"
L["Loot money"] = "Argent du butin"
L["Low Health!"] = "Vie faible!"
L["Low Mana!"] = "Mana faible!"
L["Low Pet Health!"] = "Vie faible du familier!"
L["Lua function"] = "Fonction lua"
L["Lua search expression"] = "Expression de recherche Lua"
L["Main hand"] = "Main droite"
L["Master font settings"] = "Paramètres de la police principale"
L["Melee absorbs"] = "Att. en mêlée absorbées"
L["Melee blocks"] = "Att. en mêlée bloquées"
L["Melee damage"] = "Dégâts en mêlée"
L["Melee deflects"] = "Mêlée dévier"
L["Melee dodges"] = "Att. en mêlée esquivées"
L["Melee evades"] = "Att. en mêlée évitées"
L["Melee immunes"] = "Att. en mêlée sans effet"
L["Melee misses"] = "Att. en mêlée ratées"
L["Melee parries"] = "Att. en mêlée parées"
L["Melee reflects"] = "Mêlée renvoyée"
L["Melee resists"] = "Mêlée résistée"
L["Minimum time the cooldown must have (in seconds)"] = "Temps minimum doit avoir le temps de recharge (en secondes)"
L["Miss type"] = "Type de coups ratés reçus"
L["Misses"] = "Ratés"
L["Monochrome"] = "Monochrome"
L["Mounted"] = "Monté"
L["Multiple"] = "Multiple"
L["NPC killing blows"] = "Coup fatal PNJ"
L["Name"] = "Nom"
-- L["Name of the currency"] = "Name of the currency"
L["Name of the scroll area."] = "Nom de la zone de défilement"
L["Name or ID of the spell"] = "Nom ou ID du sort"
L["New Amount of stacks of the buff."] = "Nouveau montant d'empilement du buff."
L["New Amount of stacks of the debuff."] = "Nouveau montant d'empilement du débuff."
L["New condition"] = "Nouvelle condition"
L["New filter"] = "Nouveau filtre"
L["New scroll area"] = "Nouvelle zone de défilement"
L["New suppression"] = "Nouvelle suppression"
L["New throttle"] = "Nouveau limitateur"
L["New trigger"] = "Nouveau déclencheur"
L["None"] = "Aucun"
L["Normal"] = "Normal"
L["Normal font face"] = "Type de la police d'écriture normale."
L["Normal font outline"] = "Contour de la police d'écriture normale"
-- L["Normal font shadow"] = "Normal font shadow"
L["Normal font size"] = "Taille de la police d'écriture normale"
L["Normal inherit font size"] = "Hériter de la taille de la police d'écriture normale"
L["Not in Druid Form"] = "Pas sous forme de druide"
L["Not in combat"] = "Pas en combat"
L["Not in vehicle"] = "Pas de véhicule"
L["Not mounted"] = "Non monté"
L["Notification"] = "Notification"
L["Notification events are available to notify you of certain actions."] = "Les événements de notification vous préviennent de certaines actions."
-- L["Off"] = "Off"
L["Off hand"] = "Main gauche"
-- L["On"] = "On"
-- L["Only HoTs"] = "Only HoTs"
-- L["Only direct heals"] = "Only direct heals"
L["Only return true, if the Aura has been applied by yourself"] = "Retourne seulement vrai, si l'aura a été appliqué à vous-même"
L["Options for damage types."] = "Options concernant les types de dégâts."
L["Options for event modifiers."] = "Options concernant les modificateurs d'événements."
L["Options for this scroll area."] = "Options pour cette zone de défilement"
L["Options regarding scroll areas."] = "Options concernant les zones de défilement."
L["Other"] = "Autre"
L["Outgoing"] = "Sortants"
L["Outgoing cast"] = "Incantation du joueur"
L["Outgoing crit"] = "Critique sur la cible"
L["Outgoing damage"] = "Dégâts infligés"
L["Outgoing events are events which you do to a mob or another player."] = "Les événements sortants sont les événements que vous faites sur les montres et les autres joueurs."
L["Outgoing heals"] = "Soins prodigués"
L["Outgoing miss"] = "Les coups ratés donnés"
L["Output"] = "Sortie"
L["Overheals"] = "Soins en excès"
L["Overkills"] = "Coups en excès"
L["Own aura"] = "Aura personnelle"
L["Parabola"] = "Parabole"
L["Parrot"] = "Parrot"
L["Partial absorbs"] = "Absorbés partiellement"
L["Partial blocks"] = "Bloqués partiellement"
L["Partial resists"] = "Résistés partiellement"
L["Pet buff fades"] = "Disparition du buff du familier"
L["Pet buff gains"] = "Gain du buff du familier"
L["Pet damage"] = "Dommage du familier"
L["Pet debuff fades"] = "Disparition du debuff du familier"
L["Pet debuff gains"] = "Gain du debuff du familier"
L["Pet heals"] = "Soins du familier"
L["Pet heals over time"] = "Soins au court du temps du familier"
L["Pet melee absorbs"] = "(Fam.) Att. en mêlée absorbées"
L["Pet melee blocks"] = "(Fam.) Att. en mêlée bloquées"
L["Pet melee damage"] = "Dégâts en mêlée du familier"
L["Pet melee deflects"] = "Mêlée dévier du familier"
L["Pet melee dodges"] = "(Fam.) Att. en mêlée esquivées"
L["Pet melee evades"] = "(Fam.) Att. en mêlée évitées"
L["Pet melee immunes"] = "(Fam.) Att. en mêlée sans effet"
L["Pet melee misses"] = "(Fam.) Att. en mêlée ratées"
L["Pet melee parries"] = "(Fam.) Att. en mêlée parées"
L["Pet melee reflects"] = "Mêlée renvoyée du familier"
L["Pet melee resists"] = "Mêlée résistée du familier"
L["Pet misses"] = "Coups ratés du familier"
L["Pet siege damage"] = "Dégâts de siège du familier"
L["Pet skill DoTs"] = "(Fam.) Compétence DacTs"
L["Pet skill absorbs"] = "(Fam.) Compétences absorbées"
L["Pet skill blocks"] = "Talent bloquant du familier"
L["Pet skill damage"] = "(Fam.) Dégâts des compétences"
L["Pet skill deflects"] = "Talent dévié du familier"
L["Pet skill dodges"] = "Talent esquivant du familier"
L["Pet skill evades"] = "(Fam.) Compétences évitées"
L["Pet skill immunes"] = "(Fam.) Compétences sans effet"
L["Pet skill interrupts"] = "Talent interrompu du familier"
L["Pet skill misses"] = "Pet manque de compétences"
L["Pet skill parries"] = "Talent parant du familier"
L["Pet skill reflects"] = "(Fam.) Compétences renvoyées"
L["Pet skill resists"] = "Pet compétences résiste"
L["Player killing blows"] = "Coups fatals joueur"
L["Position: %d, %d"] = "Position: %d, %d"
L["Position: horizontal"] = "Position: horizontale"
L["Position: vertical"] = "Position: verticale"
L["Pow"] = "Bang"
L["Power change"] = "Changement de puissance"
L["Power gain"] = "Gain de puissance"
L["Power gain/loss"] = "Puissance gagnée/perdue"
L["Power loss"] = "Perte de puissance"
L["Power type"] = "Type de puissance"
L["Primary conditions"] = "Conditions primaires"
L["Rainbow"] = "Arc-en-ciel"
L["Reactive skills"] = "Compétences réactives"
L["Reason for the miss"] = "Raison du coup raté"
L["Remove"] = "Enlever"
L["Remove condition"] = "Enlever la condition"
L["Remove filter"] = "Enlever le filtre"
L["Remove suppression"] = "Enlève la suppression."
L["Remove this scroll area."] = "Enlève cette zone de défilement."
L["Remove this trigger completely."] = "Enlève ce déclencheur complètement."
L["Remove throttle"] = "Supprimer un limitateur"
L["Remove trigger"] = "Enlever le déclencheur"
L["Reputation"] = "Réputation"
L["Reputation gains"] = "Gains de réputation"
L["Reputation losses"] = "Pertes de réputation"
L["Right"] = "Droite"
L["Right, clockwise"] = "Droite, sens des aiguilles d'une montre"
L["Right, counter-clockwise"] = "Droite, sens inverse des aiguilles d'une montre"
L["Scoll area where all events will be shown"] = "Zone de défilement où tous les évènements seront affichés."
L["Scroll area"] = "Zone de défilement"
L["Scroll area: %s"] = "Zone de défilement : %s"
L["Scroll areas"] = "Zones de défilement"
L["Scrolling speed"] = "Vitesse de défilement"
L["Secondary conditions"] = "Conditions secondaires"
L["Seconds for the text to complete the whole cycle, i.e. larger numbers means slower."] = "Le nombre de secondes pendant lesquelles le texte devra faire tout le cycle. Par exemple, une valeur plus grande rend le texte lent."
L["Self heals"] = "Soins personnels"
L["Self heals over time"] = "Soins au court du temps personnels"
L["Semicircle"] = "Demi-cercle"
L["Send a normal test message."] = "Envoye un message de test normal."
L["Send a sticky test message."] = "Envoye un message de test en évidence."
L["Send a test message through this scroll area."] = "Envoye un message de test dans cette zone de défilement."
L["Set the icon side for this scroll area or whether to disable icons entirely."] = "Détermine de quel côté s'affichera les icônes pour cette zone de défilement, ou s'ils doivent être masqués."
L["Set whether icons should be enabled or disabled altogether."] = "Affiche ou non les icônes."
L["Short texts"] = "Textes courts"
-- L["Shorten amounts"] = "Shorten amounts"
L["Shorten spell names"] = "Noms des sorts raccourcis"
L["Show guardian events"] = "Montrer les événements des gardiens"
L["Siege damage"] = "Dégâts de siège"
L["Size"] = "Taille"
L["Skill DoTs"] = "Compétence dégâts sur la durée"
L["Skill absorbs"] = "Compétence absorbante"
L["Skill blocks"] = "Blocs de compétences"
L["Skill cooldown finish"] = "Fin du temps de recharge de la compétence"
L["Skill damage"] = "Dégâts de la compétence"
L["Skill deflects"] = "Talent dévié"
L["Skill dodges"] = "Talent esquivant"
L["Skill evades"] = "Compétence évitée"
L["Skill gains"] = "Gain de compétence"
L["Skill immunes"] = "Compétence insensible"
L["Skill interrupts"] = "Compétence interrompue"
L["Skill misses"] = "Talent ratés"
L["Skill parries"] = "Talent paré"
L["Skill reflects"] = "Compétence renvoyée"
L["Skill resists"] = "Talent resisté"
L["Skill you were interrupted in casting"] = "Compétence que l'on vous a interrompu pendant que vous incantiez"
L["Skill your pet was interrupted in casting"] = "Le talent de votre familier a été interrompu pendant qu'il le lançait"
L["Sound"] = "Son"
L["Spell"] = "incantation"
L["Spell filters"] = "Filtre d'incantation"
-- L["Spell name or spell id"] = "Spell name or spell id"
-- L["Spell overlay"] = "Spell overlay"
L["Spell ready"] = "Sort prêt"
L["Spell steal"] = "Vol de sort"
L["Spell throttles"] = "Limitateur de sort"
L["Spell usable"] = "Sort utilisable"
L["Sprinkler"] = "Diffuseur"
L["Stack count"] = "Compteur d'application"
L["Static"] = "Statique"
L["Sticky"] = "En évidence"
L["Sticky crits"] = "Critiques en évidence"
L["Sticky font face"] = "Type de la police d'écriture en évidence"
L["Sticky font outline"] = "Contour de la police d'écriture en évidence"
-- L["Sticky font shadow"] = "Sticky font shadow"
L["Sticky font size"] = "Taille de la police d'écriture en évidence"
L["Sticky inherit font size"] = "Hériter de la taille de la police d'écriture en évidence"
L["Straight"] = "Direct"
-- L["Strikes"] = "Strikes"
L["Style"] = "Style"
L["Successful spell cast"] = "Sort lancé avec succès"
L["Suppressions"] = "Suppressions"
L["Tag"] = "Tag"
L["Tag to show for the current event."] = "Détermine le tag à afficher pour l'événement actuel."
L["Target buff gains"] = "Gains d'un buff sur la cible"
L["Target buff stack gains"] = "Gain d'empilement de buff sur la cible"
L["Target is NPC"] = "La cible est un PNJ"
L["Target is player"] = "La cible est le joueur"
L["Test"] = "Test"
L["Test how the trigger will look and act."] = "Teste la façon dont le déclencheur se présente et réagit."
L["Text"] = "Texte"
L["Text options"] = "Options du texte"
L["Text transparency"] = "Transparence du texte"
L["The ability or spell take away your power."] = "La capacité ou le sort qui a pris votre puissance."
L["The ability or spell used to gain power."] = "La capacité ou le sort utilisé pour gagner de la puissance."
L["The ability or spell your pet used."] = "La capacité ou le sort que votre familier a utilisé."
-- L["The amount of currency gained."] = "The amount of currency gained."
L["The amount of damage absorbed."] = "La quantité de dégâts absorbés."
L["The amount of damage blocked."] = "La quantité de dégâts bloqués."
L["The amount of damage done."] = "La quantité de dégâts infligés."
L["The amount of damage resisted."] = "La quantité de dégâts résistés."
L["The amount of experience points gained."] = "Le nombre de points d'expérience gagnés."
L["The amount of gold looted."] = "La quantité d'or ramassée."
L["The amount of healing done."] = "La quantité de soins prodigués."
L["The amount of items looted."] = "La quantité d'objets ramassés."
L["The amount of overhealing."] = "La quantité de soins en excès."
L["The amount of overkill."] = "La quantité de dégâts en excès."
L["The amount of power gained."] = "La quantité de puissance gagnée."
L["The amount of power lost."] = "La quantité de puissance perdue."
L["The amount of reputation gained."] = "La quantité de points de réputation gagnée."
L["The amount of reputation lost."] = "La quantité de points de réputation perdue."
L["The amount of skill points currently."] = "Le nombre actuel de points de compétence."
L["The amount of vulnerability bonus."] = "La quantité de dégâts du bonus de vulnérabilité."
L["The character that caused the power loss."] = "Le personnage à l'origine de la perte de puissance."
L["The character that the power comes from."] = "Le personnage à l'origine du gain de puissance."
L["The current number of combo points."] = "Le nombre actuel de points de combo."
L["The enemy that gained the buff"] = "L'ennemi qui a gagné le buff"
L["The enemy that gained the debuff"] = "L'ennemi qui a gagné le debuff"
L["The enemy that lost the buff"] = "L'ennemi qui a perdu le buff"
L["The enemy that lost the debuff"] = "L'ennemi qui a perdu le debuff"
L["The icon that is shown"] = "Détermine l'icône à afficher."
L["The length at which to shorten spell names."] = "Détermine la longueur à partir de laquelle les noms des sorts sont raccourcis."
L["The name of the ally that healed you."] = "Le nom de l'allié qui vous a soigné."
L["The name of the ally that healed your pet."] = "Le nom de l'allié qui a soigné votre familier."
L["The name of the ally you healed."] = "Le nom de l'allié que vous avez soigné."
L["The name of the buff gained."] = "Le nom du buff gagné."
L["The name of the buff lost."] = "Le nom du buff perdu."
L["The name of the debuff gained."] = "Le nom du débuff gagné."
L["The name of the debuff lost."] = "Le nom du débuff perdu."
L["The name of the enemy slain."] = "Le nom de l'ennemi tué."
L["The name of the enemy that attacked you."] = "Le nom de l'ennemi qui vous a attaqué."
L["The name of the enemy that attacked your pet."] = "Le nom de l'ennemi qui a attaqué votre familier."
L["The name of the enemy you attacked."] = "Le nom de l'ennemi que vous avez attaqué."
L["The name of the enemy your pet attacked."] = "Le nom de l'ennemi que votre familier a attaqué."
L["The name of the faction."] = "Le nom de la faction."
L["The name of the item buff gained."] = "Le nom du buff d'objet gagné."
L["The name of the item buff lost."] = "Le nom du buff d'objet perdu."
L["The name of the item, the buff has been applied to."] = "Le nom de l'objet sur lequel le buff a été appliqué."
L["The name of the item, the buff has faded from."] = "Le nom de l'objet duquel le buff a disparu."
L["The name of the item."] = "Le nom de l'objet."
L["The name of the pet that gained the buff"] = "Le nom du familier qui a gagné le buff"
L["The name of the pet that gained the debuff"] = "Le nom de l'animal qui a gagné le debuff"
L["The name of the pet that lost the buff"] = "Le nom de l'animal qui a perdu le buff"
L["The name of the pet that lost the debuff"] = "Le nom de l'animal qui a perdu le debuff"
L["The name of the spell or ability which is ready to be used."] = "Le nom du sort ou de la capacité qui est prêt à être utilisé."
L["The name of the spell or ability which provided the extra attacks."] = "Le nom du sort ou de la capacité qui enclenchent les attaques supplémentaires."
L["The name of the spell that has been dispelled."] = "Le nom du sort qui a été dissipé."
L["The name of the spell that has been stolen."] = "Le nom du sort qui a été volé"
L["The name of the spell that has been used for dispelling."] = "Le nom du sort qui a été utilisé pour dissiper."
L["The name of the spell that has been used for stealing."] = "Le nom du sort qui a été utilisé pour vol."
L["The name of the spell that has not been dispelled."] = "Le nom du sort qui n'a pas été dissipé."
L["The name of the unit from which the spell has been removed."] = "Nom de l'unité de qui le sort a été enlevé"
L["The name of the unit from which the spell has been stolen."] = "Le nom de l'unité à partir de laquelle le sort a été volé."
L["The name of the unit from which the spell has not been removed."] = "Le nom de l'unité dont le sort n'a pas été enlevé."
L["The name of the unit that dispelled the spell from you"] = "Le nom de l'unité qui a dissipé le charme de votre part"
L["The name of the unit that failed dispelling the spell from you"] = "Le nom de l'unité qui n'a pas dissiper le charme de votre part"
L["The name of the unit that gained the buff."] = "Le nom de l'unité qui a gagné le buff."
L["The name of the unit that stole the spell from you"] = "Le nom de l'unité qui vous a voler votre sort"
L["The name of the unit that your pet healed."] = "Le nom de l'unité que que familier a soigné."
L["The normal text."] = "Le texte normal."
L["The number of stacks of the buff"] = "Le nombre d'application du buff"
L["The position of the box across the screen"] = "La position horizontale de la boîte sur l'écran."
L["The position of the box up-and-down the screen"] = "La position verticale de la boîte sur l'écran."
L["The skill which experienced a gain."] = "La compétence qui vient de prendre un gain."
L["The spell or ability that the ally healed you with."] = "Le sort ou la capacité avec lequel l'allié vous a soigné."
L["The spell or ability that the ally healed your pet with."] = "Le sort ou la capacité que l'allié a utilisé pour soigner votre familier."
L["The spell or ability that the enemy attacked you with."] = "Le sort ou la capacité avec lequel l'ennemi vous a attaqué."
L["The spell or ability that the enemy attacked your pet with."] = "Le sort ou la capacité avec lequel l'ennemi a attaqué votre familier."
L["The spell or ability that the pet used to heal."] = "Le sort ou la capacité utilisé par votre familier pour soigner."
L["The spell or ability that you used."] = "Le sort ou la capacité que vous avez utilisé."
L["The spell or ability that your pet used."] = "Le sort ou la capacité que votre familier a utilisé."
L["The spell or ability used to slay the enemy."] = "Le sort ou la capacité utilisé pour tuer l'ennemi."
L["The spell you interrupted"] = "Le sort que vous avez interrompu"
L["The spell your pet interrupted"] = "Le sort que votre familier a interrompu"
L["The text that is shown"] = "Détermine le texte à afficher."
L["The total amount of items in inventory."] = "Le nombre total des objets dans l'inventaire."
L["The type of damage done."] = "Le type de dégâts infligés."
L["The type of power gained (Mana, Rage, Energy)."] = "Le type de puissance gagné (Mana, rage ou énergie)."
L["The type of power lost (Mana, Rage, Energy)."] = "Le type de puissance perdu (Mana, rage ou énergie)."
L["The unit that attacked you"] = "L'unité qui vous a attaqué"
-- L["The unit that casted the spell"] = "The unit that casted the spell"
L["The unit that is affected"] = "L'unité qui est affectée"
-- L["The unit that started the cast"] = "The unit that started the cast"
L["The unit that you attacked"] = "L'unité que vous avez attaqué"
L["Thick"] = "Épais"
L["Thin"] = "Mince"
L["Thin, Monochrome"] = "Mince, Monochrome"
L["Threshold"] = "Seuil"
L["Throttle events"] = "Rassemblement d'événements"
L["Throttle time"] = "Durée du limitateur"
L["Throttles that are applied to a single spell"] = "Limitateurs appliqués à un seul sort"
L["Trigger cooldown"] = "Temps de recharge du déclencheur"
L["Triggers"] = "Déclencheurs"
L["Truncate"] = "Tronquer"
L["Type of power"] = "Type de puissance"
L["Type of the aura"] = "Type d'aura"
L["Uncategorized"] = "Non répertorié"
L["Unit"] = "Unité"
L["Unit health"] = "Vie de l'unité"
L["Unit power"] = "Puissance de l'unité"
L["Up, alternating"] = "Vers le haut, alternant"
L["Up, center-aligned"] = "Vers le haut, alignés au centre"
L["Up, clockwise"] = "Vers le haut, sens des aiguilles d'une montre"
L["Up, counter-clockwise"] = "Vers le haut, sens inverse des aiguilles d'une montre"
L["Up, left"] = "Vers le haut, gauche"
L["Up, left-aligned"] = "Vers le haut, alignés à gauche"
L["Up, right"] = "Vers le haut, droite"
L["Up, right-aligned"] = "Vers le haut, alignés à droite"
L["Use short throttle-texts (like \"2++\" instead of \"2 crits\")"] = "Utiliser des textes combinés courts (comme \"2++\" ou lieu de \"2 crits\")"
L["Vulnerability bonuses"] = "Bonus de vulnérabilité"
L["What amount to filter out. Any amount below this will be filtered.\nNote: a value of 0 will mean no filtering takes place."] = "Détermine la quantité à filtrer. Toute quantité inférieure sera filtrée.\nNotes : une valeur de 0 signifie qu'aucun filtrage ne sera fait."
L["What color this damage type takes on."] = "Détermine la couleur à utiliser pour ce type de dégâts."
L["What color this event modifier takes on."] = "Détermine la couleur à utiliser pour ce modificateur d'évènement."
L["What sound to play when the current event occurs."] = "Détermine le son à jouer quand l'événement actuel se produit."
L["What sound to play when the trigger is shown."] = "Détermine le son à jouer quand le déclencheur est affiché."
L["What text this event modifier shows."] = "Détermine le texte à afficher pour ce modificateur d'événements."
L["What timespan to merge events within.\nNote: a time of 0s means no throttling will occur."] = "Détermine le laps de temps pendant lequel les événements seront rassemblés.\nNote : un laps de 0s signifie qu'aucun rassemblement ne sera fait."
L["When all of these conditions apply, the trigger will be shown."] = "Quand toutes ces conditions s'appliquent, le déclencheur est affiché."
L["When any of these conditions apply, the secondary conditions are checked."] = "Quand n'importe laquelle de ces conditions s'applique, le déclencheur est affiché."
-- L["Whether Parrot should control the default interface's options below.\nThese settings always override manual changes to the default interface options."] = "Whether Parrot should control the default interface's options below.\nThese settings always override manual changes to the default interface options."
L["Whether all events in this category are enabled."] = "Déterminer si tous les évènements dans cette catégorie sont activés."
L["Whether events involving your guardian(s) (totems, ...) should be displayed"] = "Si des évènements impliquant vos gardiens (totems, ...) doivent être affichés"
L["Whether the current event should be classified as \"Sticky\""] = "Classe ou non l'événement actuel comme étant \"En évidence\""
L["Whether the search string is a lua search expression or not."] = "Indique si la chaîne à rechercher est une expression de recherche lua ou non."
L["Whether the trigger is enabled or not."] = "Active ou non ce déclencheur."
L["Whether the unit should be friendly or hostile"] = "Définir si l'unité doit être amicale ou hostile"
L["Whether to color damage types or not."] = "Colorie ou non les types de dégâts."
L["Whether to color event modifiers or not."] = "Colorie ou non les modificateurs d'événements."
L["Whether to enable showing this event modifier."] = "Affiche ou non ce modificateur d'événements."
L["Whether to merge mass events into single instances instead of excessive spam."] = "Fusionne ou non plusieurs événements ensemble au lieu d'un spam excessif."
L["Whether to show this trigger as a sticky."] = "Affiche ou non ce déclencheur en évidence."
L["Which animation style to use."] = "Détermine le style d'animation à utiliser."
L["Which direction the animations should follow."] = "Détermine la direction que les animations doivent suivre."
L["Which scroll area to output to."] = "Détermine la zone de défilement de la sortie."
L["Which scroll area to use."] = "Détermine la zone de défilement à utiliser."
-- L["Your total amount of the currency."] = "Your total amount of the currency."
L["[Num] CP"] = "[Num] PC"
L["[Num] CP Finish It!"] = "[Num] PC Finis le!"
L["[Text] (crit)"] = "[Text] (crit)"
L["[Text] (crushing)"] = "[Text] (écrase)"
L["[Text] (glancing)"] = "[Text] (érafle)"
L["[[Spell] ready!]"] = "[[Sort] prêt!]"
