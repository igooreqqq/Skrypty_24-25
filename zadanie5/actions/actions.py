import json
from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet

with open("data/opening_hours.json", "r", encoding="utf-8") as f:
    HOURS = json.load(f)
with open("data/menu.json", "r", encoding="utf-8") as f:
    MENU = json.load(f)

class ActionShowHours(Action):
    def name(self) -> Text:
        return "action_show_hours"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict]:
        day = tracker.latest_message.get("text").lower()
        text = "\n".join(f"{d.title()}: {h}" for d, h in HOURS.items())
        dispatcher.utter_message(text=text)
        return []

class ActionShowMenu(Action):
    def name(self) -> Text:
        return "action_show_menu"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict]:
        text = "Nasze menu:\n" + "\n".join(f"{item['name']} — {item['price']} zł" for item in MENU)
        dispatcher.utter_message(text=text)
        return []

class ActionAddToOrder(Action):
    def name(self) -> Text:
        return "action_add_to_order"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict]:
        dish = next(tracker.get_latest_entity_values("dish"), None)
        order = tracker.get_slot("order") or []
        if dish:
            order.append(dish)
            dispatcher.utter_message(text=f"Dodałem {dish} do zamówienia.")
        else:
            dispatcher.utter_message(text="Nie rozumiem nazwy dania.")
        return [SlotSet("order", order)]

class ActionSetAddress(Action):
    def name(self) -> Text:
        return "action_set_address"

    def run(self, dispatcher, tracker, domain):
        addr = tracker.latest_message.get("text")
        dispatcher.utter_message(text=f"Adres dostawy ustawiony na: {addr}")
        return [SlotSet("address", addr)]

class ActionSummarizeOrder(Action):
    def name(self) -> Text:
        return "action_summarize_order"

    def run(self, dispatcher, tracker, domain):
        order = tracker.get_slot("order") or []
        addr = tracker.get_slot("address")
        if not order or not addr:
            dispatcher.utter_message(text="Brakuje pozycji w zamówieniu lub adresu.")
        else:
            summary = "Twoje zamówienie:\n" + "\n".join(f"- {dish}" for dish in order)
            summary += f"\n\nDostawa na: {addr}"
            dispatcher.utter_message(text=summary)
        return []
