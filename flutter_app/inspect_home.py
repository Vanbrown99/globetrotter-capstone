from pathlib import Path
lines = Path('lib/screens/home_screen.dart').read_text(encoding='utf-8').splitlines()
for i in range(340, 366):
    print(f'{i}: {lines[i-1]}')
