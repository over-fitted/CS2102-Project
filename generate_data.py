import numpy as np

"""
Add Departments
"""
num_departments = 4
Departments_no = list(range(1, num_departments))
Department_names = ['Human Resources', 'Services', 'Marketing', 'Sales']

for i in range(num_departments):
    print(f'CALL add_department ({i}, \'{Department_names[i]}\');')

print("\n")
"""
Add Rooms
"""
num_rooms = 10

Room_names = ["Eimbee",
              "Blogspan",
              "Photospace",
              "Brainverse",
              "Quire",
              "Topicblab",
              "Photospace",
              "Topiczoom",
              "Demivee",
              "Yozio"]

floor_room = np.random.randint(low = 1 , high = num_rooms + 1, size = (num_rooms,2))

for i in range(num_rooms):
    print(f'CALL add_room({floor_room[i][0]}, {floor_room[i][1]}, \'{Room_names[i]}\', {np.random.randint(0, high = num_departments)}, {np.random.randint(1, high = 20)});')

print("\n")


"""
Add employees
"""

num_employees = 10

names = ["Jeanna",
         "Jethro",
         "Chan",
         "Giulio",
         "Jennilee",
         "Stanton",
         "Royall",
         "Vanya",
         "Justin",
         "Ethelind"]

phones = np.random.randint(low = 10000000, high = 99999999, size = (num_employees))


title = ["Senior", "Manager", "Junior"]

for i in range(num_employees):
    print(f'CALL add_employee(\'{names[i]}\', NULL, NULL, \'{phones[i]}\', \'{np.random.choice(title)}\', {np.random.randint(0, high = num_departments)});')

print("\n")

