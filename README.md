# Parrot
Floating Combat Text of awesomeness.

Displays combat (damage, healing, auras) events as well as other events (loot, cooldown available, power change, repuation, kills, and more) as moving text and numbers across the screen.

Parrot also offers a trigger system to display text message and play sounds on predefined events (e.g., Nightfall for Warlocks).

## FAQ
**Q**: I created a custom trigger doing &lt;something&gt;. Is it worthy to be in parrots default triggers?  
**A**: Probably. If you want to contribute a custom trigger to be added to the default triggers, please post a ticket where you describe *exactly* how you set it up. I can't figure that out for every class and every spec.

**Q**: Parrot is not showing heals, but it's enabled in the options  
**A**: Since 3.2 WoW displays every full overheal in the combatlog (even for HoTs). That's why Parrot v1.9.0+ contains an option in Events to "Hide full overheals" which is enabled by default to avoid unnecessary spam.

**Q**: I want to use custom fonts and sounds in Parrot, but there are none available  
**A**: Parrot doesn't provide sounds or additional fonts (only the fonts included in WoW). For additional fonts and sounds please install SharedMedia. If you want to include your own custom sounds and fonts see the "INSTRUCTIONS for MyMedia.txt" in the SharedMedia-folder.

**Q**: Whenever I reload or log back in again, Parrot hides Blizzard's default outgoing damage text (the one above the mob in question). Is there a way to avoid having to re-enable Blizzard's options all the time?  
**A**: When enabled Parrot manages the settings for Blizzard FCTs damage and heal display. You can enable these features to be used with Parrot in the config (General->Game damage/healing)

**Q**: Sometimes when looting stackable items, the stack count is off. Why isn't this fixed?  
**A**: The problem is that the event for loot is triggered before or after the item was put in the bag depending on lag and may not have registered by the time we check the item's count.

## Localization
If you want to translate Parrot into your language (or update an existing translation) please do so on the [WowAce localization tool](http://www.wowace.com/projects/parrot/localization/).

## Feature Requests / Reporting Bugs
[Please use the ticket-system](http://www.wowace.com/projects/parrot/tickets/). Also check if there is a similar ticket among the open tickets already (and maybe join the discussion there).
