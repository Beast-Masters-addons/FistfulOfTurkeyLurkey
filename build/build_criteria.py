from build_utils.utils import build_lua_table, WowXML
from build_utils.utils.tables.WoWTables import WowTablesCache
from unlocalize import Unlocalize

xml = WowXML()

for game in ['wrath', 'mists', 'retail']:
    tables = WowTablesCache(game=game)
    unlocalize = Unlocalize(game=game)
    criteria_110 = tables.filter_table('criteria', ('Type', '110'))
    if not criteria_110:
        continue  # Skip criteria which is not of type 110 (Land targeted spell "{Spell}" on a target)

    criteria_keys = list(map(lambda row: row['ID'], criteria_110))
    criteria_trees = {}
    parent_keys = []

    for tree in tables.filter_table('criteriatree', ('CriteriaID', criteria_keys)):
        if tree['Parent'] not in criteria_trees:
            criteria_trees[tree['Parent']] = [tree]
            parent_keys.append(tree['Parent'])
        else:
            criteria_trees[tree['Parent']].append(tree)

    criteria_addon = {}
    achievements = tables.filter_table('achievement', ('Criteria_tree', parent_keys), key_field='ID')
    for achievement_id, achievement in achievements.items():
        achievement_id = int(achievement_id)
        achievement['tree'] = criteria_trees[achievement['Criteria_tree']]
        if achievement['Criteria_tree'] not in criteria_trees:
            continue  # Only criteria trees with children are used

        #  = criteria_trees[achievement['Criteria_tree']].keys()
        for criteria in criteria_trees[achievement['Criteria_tree']]:
            race_id = unlocalize.race_partial(criteria['Description_lang'])
            class_id = unlocalize.class_partial(criteria['Description_lang'])
            if not race_id and not class_id:
                continue  # Skip criteria without race or class
            if achievement_id not in criteria_addon:
                criteria_addon[achievement_id] = {}

            criteria_addon[achievement_id][int(criteria['CriteriaID'])] = [race_id, class_id]
            pass

        if achievement_id in criteria_addon:  # Sort resulting dict by keys to simplify comparison
            criteria_addon[achievement_id] = dict(sorted(criteria_addon[achievement_id].items(), key=lambda x: x[0]))

    with open('../data/criteria_%s.lua' % game, 'w') as fp:
        lua = build_lua_table(criteria_addon, '_G.fistful_criteria_%s' % game)
        fp.write(lua)
    xml.script('../data/criteria_%s.lua' % game)

xml.save('../data/data.xml')
