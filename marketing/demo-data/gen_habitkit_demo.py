import json, random, datetime as dt, uuid
random.seed(42)
today = dt.date.today()
habits = [
  # name, icon, color, start date, base rate, done today
  ("Morning run",   "run",        "teal",   dt.date(2026,5,4), 0.78, True),
  ("Read 20 pages", "book_open",  "amber",  dt.date(2026,4,20),0.88, False),
  ("Drink water",   "droplets",   "sky",    dt.date(2026,4,20),0.93, True),
  ("Meditation",    "meditation", "violet", dt.date(2026,6,1), 0.82, True),
  ("Gym",           "dumbbell",   "red",    dt.date(2026,5,18),0.70, False),
  ("Wake up early", "sun",        "orange", dt.date(2026,4,20),0.80, True),
  ("Skin care",     "flower",     "pink",   dt.date(2026,7,6), 0.90, False),
  ("Vitamins",      "pill",       "lime",   dt.date(2026,6,15),0.92, True),
  ("Journal",       "notebook",   "indigo", dt.date(2026,7,20),0.85, False),
  ("Evening walk",  "footprints", "cyan",   dt.date(2026,5,25),0.75, False),
]
H, C = [], []
for i,(name,icon,color,start,rate,today_done) in enumerate(habits):
    hid = str(uuid.UUID(int=random.getrandbits(128)))
    H.append({"id":hid,"name":name,"description":"","icon":icon,"color":color,
              "archived":False,"orderIndex":i,"createdAt":f"{start.isoformat()}T08:00:00.000Z"})
    d = start
    while d < today:
        # consistency improves over time; last 14 days nearly perfect
        age = (today - d).days
        r = rate + (0.06 if age < 60 else 0) + (0.2 if age < 14 else 0)
        if d.weekday()==6 and name=="Gym": r -= 0.4
        if random.random() < min(r,0.99) or age < 12:
            C.append({"id":str(uuid.UUID(int=random.getrandbits(128))),"date":f"{d.isoformat()}T12:00:00.000Z",
                      "habitId":hid,"timezoneOffsetInMinutes":0,"amountOfCompletions":1})
        d += dt.timedelta(days=1)
    if today_done:
        C.append({"id":str(uuid.UUID(int=random.getrandbits(128))),"date":f"{today.isoformat()}T12:00:00.000Z",
                  "habitId":hid,"timezoneOffsetInMinutes":0,"amountOfCompletions":1})
json.dump({"habits":H,"completions":C,"intervals":[],"categories":[]}, open(__import__('sys').argv[1],"w"))
print(len(H), len(C))
