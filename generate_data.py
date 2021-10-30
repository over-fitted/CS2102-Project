import numpy as np

"""
Add Departments
"""
Department_names = ['Accounting',
                    'Business Development',
                    'Departments',
                    'Engineering',
                    'Human Resources',
                    'Legal','Marketing',
                    'Product Management',
                    'Research and Development',
                    'Sales',
                    'Services',
                    'Support',
                    'Training']

num_departments = len(Department_names)
Departments_no = list(range(1, num_departments))


for i in range(num_departments):
    print(f'CALL add_department ({i}, \'{Department_names[i]}\');')

print("\n")
"""
Add Rooms
"""


Room_names = ['Abata', 'Avamba',
              'Avamm', 'Brightbean',
              'Browsetype', 'Buzzster',
              'Cogidoo', 'Demimbu',
              'Demizz', 'Divavu',
              'Eabox', 'Eayo',
              'Feedmix', 'Flashdog',
              'Flashset','Gevee',
              'JumpXS', 'Lazz',
              'Leexo','Meeveo',
              'Miboo','Mita',
              'Mudo','Ooba',
              'Oyonder','Oyope',
              'Quimm','Quinu',
              'Rhynoodle','Skipstorm',
              'Skyndu','Skyvu',
              'Tagcat','Tagfeed',
              'Topicware','Vidoo',
              'Vipe','Voonyx',
              'Wikido','Yadel',
              'Yata','Youbridge',
              'Youopia','Zoovu']

num_rooms = len(Room_names)

floor_room = np.random.randint(low = 1 , high = num_rooms + 1, size = (num_rooms,2))

for i in range(num_rooms):
    print(f'CALL add_room({floor_room[i][0]}, {floor_room[i][1]}, \'{Room_names[i]}\', {np.random.randint(0, high = num_departments)}, {np.random.randint(1, high = 20)});')

print("\n")


"""
Add employees
"""



names = ['Ab','Abram',
         'Aksel','Arnold',
         'Bern','Bertram',
         'Brit','Burke',
         'Che','Cherilynn',
         'Cilka','Constancia',
         'Constantine','Cullin',
         'Darcy','Danyette',
         'Denni','Donalt',
         'Ebonee','Farley',
         'Flossie','Francine',
         'Gaspard','Glenden',
         'Gwenora','Hall',
         'Hilliard','Hunfredo',
         'Janith','Jarvis',
         'Kearney','Kirsten',
         'Kristo','Laure',
         'Leonard','Meridel',
         'Mick','Milt',
         'Nerissa','Petronille',
         'Pincas','Rabbi',
         'Ravid','Russell',
         'Sayre','Seward',
         'Travers','Wallis',
         'Wandie','Wilmar']

num_employees = len(names)

phones = np.random.randint(low = 10000000, high = 99999999, size = (num_employees))


title = ["Senior", "Manager", "Junior"]

for i in range(num_employees):
    print(f'CALL add_employee(\'{names[i]}\', NULL, NULL, \'{phones[i]}\', \'{np.random.choice(title)}\', {np.random.randint(0, high = num_departments)});')

print("\n")

