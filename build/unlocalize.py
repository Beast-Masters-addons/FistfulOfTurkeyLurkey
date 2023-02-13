import csv


def load_table(table):
    with open(table + '.csv') as fp_table:
        return list(csv.DictReader(fp_table))


class Unlocalize:
    def __init__(self):
        self.races = load_table('chrraces')
        self.classes = load_table('chrclasses')

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
