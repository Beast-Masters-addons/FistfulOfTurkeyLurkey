from build_utils.utils.tables.WoWTables import WowTablesCache


class Unlocalize:
    def __init__(self, **tables_kwargs):
        self.tables = WowTablesCache(**tables_kwargs)
        self.races = self.tables.get_db_table('chrraces')
        self.classes = self.tables.get_db_table('chrclasses')

    def class_exact(self, class_name: str):
        for race in self.races:
            if class_name in [race['Name_lang'], race['Name_female_lang'], race['Name_lowercase_lang']]:
                return int(race['ID'])

    def race_partial(self, search: str):
        for race in self.races:
            if search.find(race['Name_lang']) > -1:
                return int(race['ID'])

    def class_partial(self, search: str):
        for class_ in self.classes:
            if search.find(class_['Name_lang']) > -1:
                return int(class_['ID'])
