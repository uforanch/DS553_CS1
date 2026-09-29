import random

n = 39

xl = list(range(n))
random.shuffle(xl)

with open("ports.txt", 'w') as f:
    f.write("\n".join([str(22001+x) for x in xl]))