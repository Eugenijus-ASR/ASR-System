import sys
import os

file_path = 'data/local/lm/unique_words.txt'
if not os.path.exists(file_path):
    sys.exit(0)

with open(file_path, 'r') as f:
    words = [w.strip() for w in f if w.strip()]

print("\\data\\")
print(f"ngram 1={len(words) + 2}\n")
print("\\1-grams:")
print(f"-1.0\t<s>\t0.0")
print(f"-1.0\t</s>\t0.0")
for w in words:
    print(f"-1.0\t{w}\t0.0")
print("\\end\\")
