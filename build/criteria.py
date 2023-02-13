import csv

from unlocalize import Unlocalize
from build_utils.utils.tables.build_lua_table import build_lua_table

achievements = {}
achievement_criteria_unlocalized = {}
with open('achievement.csv', newline='') as fp:
    reader = csv.DictReader(fp)
    for row in reader:
        achievement_id = int(row['ID'])
        achievements[achievement_id] = row
        achievement_criteria_unlocalized[int(row['Criteria_tree'])] = achievement_id

with open('criteria.csv', newline='') as fp:
    reader = csv.DictReader(fp)
    criteria = {}
    criteria2 = {}
    for row in reader:
        if row['Type'] != '110':
            continue
        criteria[int(row['Asset'])] = {'id': int(row['ID']), 'modifier': int(row['Modifier_tree_ID'])}
        criteria2[int(row['ID'])] = row

achievement_criteria = {}
unloc = Unlocalize()
with open('criteriatree.csv', newline='') as fp:
    reader = csv.DictReader(fp)
    for row in reader:
        if int(row['CriteriaID']) in criteria2:
            parent = int(row['Parent'])
            achievement = achievement_criteria_unlocalized[parent]
            if achievement not in achievement_criteria:
                achievement_criteria[achievement] = {}

            achievement_criteria[achievement][int(row['CriteriaID'])] = row['Description_lang']

achievement_criteria_unlocalized = {}
for achievement_id, criterias in achievement_criteria.items():
    criterias_unlocalized = {}
    for criteria_id, criteria in criterias.items():
        char_race = unloc.race_partial(criteria)
        char_class = unloc.class_partial(criteria)
        if char_race is None and char_class is None:
            break
        criterias_unlocalized[criteria_id] = [char_race, char_class]
    if criterias_unlocalized:
        achievement_criteria_unlocalized[achievement_id] = criterias_unlocalized

lua = build_lua_table(achievement_criteria_unlocalized, '_G.fistful_criteria')
with open('../addon/criteria.lua', 'w') as fp:
    fp.write(lua)
