import os
saxTransposition = {
    "soprano": 2,
    "alto": 9,
    "tenor": 14,
    "barytone": 21,
}

base_file = "sax_fingerings"

if not os.getcwd().endswith('src'):
    os.chdir('src')

code = ""
with open(base_file + ".qml.template", "r") as file:
    code = file.read()

for key, value in saxTransposition.items():
    with open("../dist/" + key + "_" + base_file + ".qml", "w") as file:
        file.write(code.replace("$INSTRUMENT$", key).replace(
            "$TRANSPOSITION$", str(value)))

export_file_name = '../demo_Saxy.png'
if os.path.exists(export_file_name):
    os.remove(export_file_name)
    os.system(f'musescore3.exe ../test/sax_fing_test.mscz --export-to {export_file_name}')
    os.rename(export_file_name.replace('.png', '-1.png'), export_file_name)
else:
    print(f"{export_file_name} file does not exist. Make sure you are calling this script from /src. If you deleted the file, take it back with git.")
