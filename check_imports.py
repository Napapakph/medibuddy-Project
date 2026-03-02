import os, glob

# Get all files in lib/services
services_dir = r'c:\Users\alice\medibuddy-Project\lib\services'
service_files = [f for f in os.listdir(services_dir) if f.endswith('.dart')]

# Get all dart files in lib/
all_dart_files = []
for root, dirs, files in os.walk(r'c:\Users\alice\medibuddy-Project\lib'):
    for file in files:
        if file.endswith('.dart'):
            all_dart_files.append(os.path.join(root, file))

# Count imports
usage = {f: [] for f in service_files}

for dart_file in all_dart_files:
    try:
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
            for sf in service_files:
                if os.path.basename(dart_file) != sf:
                    # check if the word sf is in content
                    if sf in content:
                        usage[sf].append(dart_file)
    except Exception as e:
        pass

print('--- Usage Report ---')
for sf in service_files:
    print(f'{sf}: {len(usage[sf])} references')
    for ref in usage[sf]:
        print(f'  - {ref}')
