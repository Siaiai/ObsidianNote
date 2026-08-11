"""Replace the modes HTML block with attachment reference."""
import re

path = r"C:\Users\SiaZh\OneDrive\SIA的obsidian系统\工作\[[SR3读卡器]]\260804SR3框架整理.md"

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Strategy: find "### 不同模式通信流程" and the next "### LED行为表"
# then replace everything between them (inclusive of the ```html block)

start_marker = '### 不同模式通信流程\n\n```html\n'
end_marker = '\n```\n\n### LED行为表'

start = content.find(start_marker)
end = content.find(end_marker, start)

print(f"Start at {start}, end at {end}")

if start >= 0 and end >= 0:
    replacement = (
        '### 不同模式通信流程\n\n'
        '![[attachments/sr3-modes.html]]\n\n'
        '> [!tip] 若图表不显示，安装 Embed HTML 插件或浏览器打开 attachments/。\n\n'
        '### LED行为表'
    )
    content = content[:start] + replacement + content[end + len(end_marker):]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done - modes block replaced.')
print(f'Chars: {len(content)}')
