import re
with open('Habitify/ContentView.swift', 'r') as f:
    text = f.read()

text = text.replace('\\"Journey & Insights\\"', '"Journey & Insights"')

with open('Habitify/ContentView.swift', 'w') as f:
    f.write(text)
